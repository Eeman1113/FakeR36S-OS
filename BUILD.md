# Building FakeR36S-OS

Everything here targets the **GA36-MB board with an Allwinner A23**. GitHub Actions builds the whole
OS on every push to `main` and publishes it to the `latest` release, so you only need this document
if you want to build locally or change something.

FakeR36S-OS is a fork of [goodluckOS](https://github.com/CodeZombie/goodluckOS) and keeps its
four-stage build, but the stages, the partition layout and the install path have all moved on.
If you are coming from goodluckOS, read this rather than assuming.

## The four stages

| Stage | Directory | Produces | Time |
|---|---|---|---|
| Kernel | `kernel/` | `android_boot_<variant>.img`, DTBs | ~6 min |
| Rootfs | `rootfs/` | `rootfs.tar` | 1 to 2.5 hours |
| Home | `home/` | `home.tar` | seconds |
| Image | `image/` | `goodluck_base_<variant>.img` | ~5 min |

The first three are independent and can run in any order. The image stage needs all three.

The image this produces is a **base image**: its boot region is deliberately left blank, because the
vendor bootloader cannot be redistributed. Turning it into something flashable is a separate step,
described under [Making a flashable image](#making-a-flashable-image).

## CI

`.github/workflows/build.yml` runs `kernel`, `home` and `rootfs` in parallel, then `image`. It builds
the `a23_panel2` variant only, since that is the board this project is tested on.

Two caches make repeat runs bearable: `rootfs/dl` (source tarballs) and `rootfs/ccache`. Both are
chowned back to the runner user after the build, because Buildroot runs as root inside the container
and `actions/cache` cannot read root-owned files. Without that step neither cache is ever saved and
every run takes well over two hours.

On `main`, a successful run uploads four assets to the `latest` release: the base image as `.xz`
(for humans) and as `.gz` (the web installer streams that one through `DecompressionStream`),
`fakers36s-update-<variant>.tar` for devices already running FakeR36S-OS, and `SHA256SUMS.txt`.
The update tarball is a `manifest.txt`, the boot image, and the rootfs and home tarballs gzipped,
which `fr-update` installs on the device at boot.

## 1. The kernel

Docker or Podman, no local toolchain needed:

```sh
cd kernel && ./build.sh          # output in kernel/out/
```

It fetches **linux 7.2.9** from cdn.kernel.org, adds two reverse-engineered drivers, three patches
and the GA36-MB device trees, then builds four variants (A23 and A33, panel 1 and panel 2) as Android
boot images with the DTB appended to the zImage. See [kernel/README.md](kernel/README.md) for what is
in there and how to flash just the kernel.

## 2. The rootfs

Buildroot 2026.08-rc2 in a container. `rootfs/start.sh` builds the image and drops you into it:

```sh
cd rootfs && ./start.sh
```

Inside:

| Command | What it does |
|---|---|
| `./scripts/configure.sh` | loads `configs/goodluck_defconfig` (runs automatically on entry) |
| `./scripts/build.sh -j$(nproc)` | builds, leaving `out/images/rootfs.tar` |
| `./scripts/menuconfig.sh` | Buildroot config |
| `./scripts/busybox-menuconfig.sh` | Busybox config |
| `./scripts/clean.sh` | removes build artifacts |

Expect 1 to 2.5 hours cold. The cross toolchain, Mesa with the Lima driver, SDL2 and SDL3,
EmulationStation, RetroArch and about thirty libretro cores are all compiled from source.

No Docker (for example on a cloud VM), `tools/colab-build.sh` does the same thing natively.

### Custom packages

`rootfs/package/<name>/` with a `Config.in` and a `<name>.mk`, registered in
`rootfs/package/Config.in`. The ones specific to this project:

- `dashboard`, `bootsplash`, `system-settings`, `credits`, `puppy`, `resize-home`, `are-you-sure`
- `emulationstation-fcamod` with five patches for this hardware, `es-theme-carbon`, `fr-freeimage`
- `libretro-cores`, `parallel-n64`, `ppsspp`, `retroarch`

Two things in `libretro-cores.mk` are worth knowing before you touch it. `LIBRETRO_CORES_VERSION`
must be a commit SHA, because Buildroot resolves it as a commit and not as a branch. And gpSP,
PicoDrive and VecX get a second build pass with `platform=classic_armv7_a7`, because their Makefiles
detect the build host under `platform=unix` and emit x86 code.

## 3. The home overlay

```sh
cd home && ./build.sh            # home/out/home.tar
```

`home/overlay/` becomes `/home/player` on the FAT32 HOME partition: `es_systems.cfg`, the RetroArch
configuration and per-core overrides, the Tools scripts, and the empty `roms/<system>` tree built
from `.romdirs`.

Because HOME is FAT32, you can edit any of this from a computer with the card plugged in, without
rebuilding anything.

## 4. The image

Needs `kernel/out/android_boot_<variant>.img`, `rootfs/out/images/rootfs.tar` and `home/out/home.tar`.

```sh
cd image && ./build.sh           # image/out/goodluck_base_<variant>.img
```

The layout, from `image/Dockerfile`:

```
0        .. 128 MiB    boot region, left blank (spliced in later from your own card)
128 MiB  .. 1536 MiB   ext4 "linux", the system
1536 MiB .. 2 GiB      FAT32 "HOME", grown to fill the card on first boot
```

The system partition is 1.4 GiB because the full OS does not fit in goodluckOS's 384 MiB.

If you have CI artifacts and would rather not run Docker and libguestfs, `tools/assemble-base.sh`
builds the same image with `mke2fs -d`, `mkfs.fat` and `mtools`. No root, no VM, works on macOS.

## Making a flashable image

The base image cannot boot on its own. Sectors 1 to 172031 of your own stock card hold the vendor
boot0, U-Boot, `script.bin` and the boot-resource partition, and have to be spliced in:

```sh
tools/make-flashable.sh goodluck_base_a23_panel2.img.xz stock_backup.img fakers36s.img
```

Needs `python3`, `xz` and `mtools`. It fingerprints `script.bin` and refuses to run on a board it
does not recognise, so it cannot hand you an image that will not boot. It also writes the custom
`bootlogo.bmp` into the stock boot-resource FAT.

The web installer in `docs/` does the same thing in a browser, with nothing uploaded anywhere.

## Updating a card you have already flashed

Reflashing means copying your games back. Instead:

- **On the device**, use the updater, which takes the `fakers36s-update-*.tar` from the release
- **From a computer**, `sudo tools/update-os.sh fakers36s.img diskN` writes only the boot region and
  the system partition, leaving the partition table and everything on HOME alone

## Flashing stages individually

You do not need a full build to test one change.

| Changed | Flash |
|---|---|
| Kernel | `dd if=android_boot_a23_panel2.img bs=512 seek=172032 conv=notrunc of=/dev/sdX` |
| Rootfs | mount the `linux` partition, empty it, untar `rootfs.tar` into it |
| Home | mount `HOME` (FAT32, mounts anywhere), replace files under `player/` |

## Getting your stock card backup

The installer needs the first 128 MB of the card that came with the device. A full backup is better,
since it also preserves the games and saves that shipped on it.

```sh
diskutil list external physical              # macOS, find the disk
sudo dd if=/dev/rdiskN of=stock_backup.img bs=1m count=128
```

```sh
lsblk                                        # Linux
sudo dd if=/dev/sdX of=stock_backup.img bs=4M count=32 conv=fsync
```

Keep it. Without it this device cannot boot anything at all.
