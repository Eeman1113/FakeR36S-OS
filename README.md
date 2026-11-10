# FakeR36S-OS

**Custom firmware for fake / clone R36S handhelds built on the GA36-MB board (Allwinner A23).**
A fast, clean, ArkOS-style OS: EmulationStation, RetroArch, N64, auto-scaling, live system dashboard.

> Bought an "R36S" and it turned out to be a fake? If the back of the board says **GA36-MB** and the
> chip is an **Allwinner A23/A33** (often laser-marked "RK3326"), ArkOS, dArkOS, ArkOS4Clone and ROCKNIX
> **cannot** run on it, because they need a real Rockchip RK3326. This OS is built for that board.

## Features
- **ArkOS-style frontend**: EmulationStation (fcamod, the ArkOS fork), carbon theme, boots straight into it
- **43 systems, best core preselected for the A23**: NES, SNES, **N64** (ParaLLEl, dynarec), GB/GBC/GBA,
  Mega Drive/32X/Sega CD, Master System, Game Gear, PC Engine/CD, SuperGrafx, PS1, PSP, CPS1/2/3, Neo Geo,
  MAME 2003-Plus, Neo Geo Pocket, WonderSwan, Atari 2600/7800/Lynx, Virtual Boy, Vectrex, MSX, ZX Spectrum,
  Amstrad CPC, Intellivision, ColecoVision, Odyssey 2, Pokemon Mini, Game & Watch, DOS
- **Automatic scaling per system**: integer scaling for Game Boy / Game Gear / Lynx / NGP, crisp
  "sharp" scaling (2x nearest + bilinear fit, FP16-safe on the Mali-400) for 2D consoles and arcade,
  smooth scaling for 3D systems
- **ArkOS hotkeys**: Select+Start exit, Select+X menu, Select+B FPS counter, Select+R1/L1 save/load state, Select+R2 fast forward
- **CPU frequency scaling** from the board's own stock DVFS table (648-1008 MHz), plus an opt-in
  **1.2 GHz performance mode** (the vendor's own max_freq)
- **System Dashboard**: live CPU per core, frequency, battery voltage/current/charge, memory, zram,
  storage, temperature, with graphs
- **No headphone pops or volume spikes**: the codec stays powered, and speaker / headphones keep
  separate volumes with a fade-in on switch
- Animated boot splash with chime, quiet boot, custom boot logo

## Supported hardware
| Board | SoC | Screen | Status |
|---|---|---|---|
| GA36-MB V1.2-20260416 "A23 Esisla" | Allwinner A23 (2 cores) | panel 2 | ✅ tested |
| other GA36-MB A23 variants (Xeno, Underscore, Elgom) | A23 | panel 1 or 2 | should work (untested) |
| GA36-MB A33 variants | A33 (4 cores) | - | use upstream goodluckOS |

Check your board: open the back, or look at **System Information → CPU NUMBER** on the stock firmware
(2 = A23, 4 = A33). The image builder refuses to run on a stock card that is not a known A23 board.

## Install

### 1. Back up your original SD card (`stock_backup.img`)
The stock card holds the vendor bootloader and your board's hardware config. **Without it this device
cannot boot anything**, so back it up first and keep the original card untouched.
The image builder only needs the first 128 MB, but a full backup also saves your games and saves.

<details open>
<summary><b>macOS</b></summary>

1. Insert the stock card and find it (check the size matches the card):
   ```
   diskutil list external physical
   ```
   It shows up as `/dev/diskN`, for example `/dev/disk4  *15.9 GB`.
2. Back it up (use `rdiskN`, it is much faster; this only **reads** the card):
   ```
   sudo dd if=/dev/rdiskN of=stock_backup.img bs=4m status=progress
   sudo chown $(whoami) stock_backup.img
   ```
   A 16 GB card takes about 15 minutes over USB 2.0.
3. Optional, quicker: only the part the builder needs:
   ```
   sudo dd if=/dev/rdiskN of=stock_backup.img bs=1m count=128
   ```
</details>

<details>
<summary><b>Linux</b></summary>

1. Find the card: `lsblk` (for example `/dev/sdb` or `/dev/mmcblk0`; check the size).
2. Back it up:
   ```
   sudo dd if=/dev/sdX of=stock_backup.img bs=4M status=progress conv=fsync
   sudo chown $USER stock_backup.img
   ```
</details>

<details>
<summary><b>Windows</b></summary>

Use **Win32 Disk Imager** (or HDD Raw Copy Tool): pick the card's drive letter, type a file name ending in
`stock_backup.img`, and click **Read** (not Write). If Windows offers to format the card, click **Cancel**:
its partitions are Linux ones that Windows can't read, and formatting would erase the bootloader.
</details>

**Verify the backup.** These two hashes should be identical for a full backup:
```
shasum -a 256 stock_backup.img
sudo dd if=/dev/rdiskN bs=4m | shasum -a 256        # Linux: sha256sum and /dev/sdX
```
Keep `stock_backup.img` somewhere safe (external drive or cloud). To restore stock at any time:
```
sudo dd if=stock_backup.img of=/dev/rdiskN bs=4m
```

### 2. Download FakeR36S-OS
Get `FakeR36S-OS_base_a23_panel2` (`goodluck_base_a23_panel2.img.xz`) from the latest
[Actions run](../../actions) or Release.

### 3. Build your flashable image
This copies your own card's boot region, adds the boot logo, and refuses to run if the backup isn't a
supported A23 board:
```
tools/make-flashable.sh goodluck_base_a23_panel2.img.xz stock_backup.img fakers36s.img
```
Needs `python3`, `xz` and `mtools` (`brew install mtools` / `apt install mtools`).

### 4. Flash a NEW microSD card
```
sudo dd if=fakers36s.img of=/dev/rdiskN bs=4m      # make sure N is the NEW card!
```
Put it in slot **TF1** and power on. The first boot grows the HOME partition to fill the card.

### 5. Add your games
Plug the card into your computer: the **HOME** partition mounts normally. Put ROMs in `roms/<system>/`
(folder names match the stock card: `nes`, `snes`, `gba`, `n64`, `psx`, `megadrive`, ...) and BIOS files in
`.config/retroarch/system/`. Game saves (`.srm`) go next to the ROMs, as on the stock firmware.

## Building
GitHub Actions builds everything (kernel, Buildroot rootfs, home, base image) on every push to `main`.
See [BUILD.md](BUILD.md) to build locally with Docker.

## Credits
Built on **[goodluckOS](https://github.com/CodeZombie/goodluckOS)** by CodeZombie and contributors (GPL-2.0):
the A23 device tree, the JD9366 panel driver and the GA36-MB gamepad driver come from there.
The N64 and EmulationStation recipes, pins and patches come from **[Debianator](https://github.com/Bepok/Debianator)** (GPL-2.0).
EmulationStation fcamod by christianhaitian; carbon theme by the RetroPie project; RetroArch and libretro cores by their authors.

FakeR36S-OS by **Eeman1113** (EemanSleepDeeprived). Licensed GPL-2.0, like goodluckOS.

<sub>Keywords: fake R36S, R36S clone, GA36, GA36-MB, Allwinner A23, Allwinner A33, R36S custom firmware,
ArkOS alternative, R36S fake fix, EmuELEC clone, retro handheld.</sub>
