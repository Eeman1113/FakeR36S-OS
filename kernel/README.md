# The FakeR36S-OS kernel

Mainline **Linux 7.2.9** for the GA36-MB board, plus the two drivers the hardware cannot run without,
three small patches, and the device trees. Built in a container, so nothing needs to be installed
locally beyond Docker or Podman.

```sh
./build.sh          # kernel/out/
```

## What comes out

| File | What it is |
|---|---|
| `android_boot_a23_panel2.img` | the variant this project is built and tested for |
| `android_boot_a23_panel1.img` | other A23 panel, untested |
| `android_boot_a33_panel{1,2}.img` | A33 boards, better served by goodluckOS upstream |
| `dtb/*.dtb` | the device trees on their own |
| `kernel_config.txt` | the kernel config the build used |

Each boot image is a zImage with its DTB appended, wrapped as an Android boot image, which is what
the vendor U-Boot expects to find at sector 172032.

Only `a23_panel2` is built in CI. Pick your variant from the board, or from **System Information →
CPU NUMBER** in the stock firmware: 2 means A23, 4 means A33.

## What this kernel adds on top of mainline

### Device trees (`dts/`)

`ga36mb.dtsi` carries the parts shared by every variant, with `ga36mb-a23.dtsi` and
`ga36mb-a33.dtsi` on top and a thin `.dts` per panel.

The A23 file is where most of the FakeR36S-OS work lives:

- **A CPU frequency table.** Mainline `sun8i-a23.dtsi` has no OPP table at all, so without this the
  CPU sits at whatever the bootloader left it at, 1008 MHz, forever. The points are transcribed from
  this board's own `script.bin` `[dvfs_table]`: 648 MHz at 1.04 V, 816 MHz at 1.10 V, 1008 MHz at
  1.20 V, and 1200 MHz at 1.32 V marked `turbo-mode` so it is only used when boost is switched on.
  The vendor's 1344 and 1536 MHz "extremity" points are deliberately left out. Nothing runs at a
  voltage the manufacturer was not already using.
- **Codec routing for the A23**, including `"Headphone", "HPCOM"`, because the jack is direct driven
  and its return is on HPCOM.
- **`x-powers,drive-vbus-en` on the AXP PMIC.** Without it the USB PHY defers forever and musb never
  probes, so USB simply does not appear.
- **MIPI DSI and D-PHY nodes**, which mainline does not describe for this SoC.

### Patches (`patches/`)

- `0001` musb gadget: read a pending RX packet on restart
- `0003` ASoC sun4i-codec: speaker pin switch on the A23
- `0005` mfd axp20x: clear the BSP boot flag on power off

### Drivers (`drivers/`)

- `jd9366-ga36mbv1-2.c`, the display panel
- `ga36mb-gamepad.c`, buttons and analog sticks as a single input device

**Both of these come from [goodluckOS](https://github.com/CodeZombie/goodluckOS), written by
CodeZombie**, and they are the reason Linux runs on this board at all. The short version of what
they had to work out, because it explains why the code looks the way it does:

The panel has no markings and no documentation. Its initialisation sequence was recovered by pulling
`lcd.ko` out of the stock Linux 3.4 firmware and reading it in Ghidra. Even with the right sequence
it only came up about nine times in ten, because the bootloader leaves the display running and hands
it over without cleanup, so the driver now power cycles the panel at the top of `prepare` instead of
just toggling the reset pin.

The gamepad is stranger. The buttons sit directly on GPIOs, but the Allwinner SoC has no general
purpose ADC, so the manufacturer added a second microcontroller to read the analog sticks and talk to
the main SoC over **UART**. That MCU needs an initialisation sequence from the host, which came out of
the stock driver the same way. The GPIO buttons were then pulled out of the device tree and polled
inside the driver, so the whole thing enumerates as one controller: RetroArch and most games behave
badly when a device shows up as two.

CodeZombie's own account of that work is worth reading in the
[upstream repository](https://github.com/CodeZombie/goodluckOS).

## Flashing just the kernel

No need to rebuild the OS to test a kernel change. The boot image lives at a fixed offset, outside
both partitions:

```sh
./build.sh
sudo dd if=out/android_boot_a23_panel2.img bs=512 seek=172032 conv=notrunc status=progress of=/dev/sdX
sync
```

`/dev/sdX` is the card itself, not a partition. On macOS use `/dev/rdiskN` and `bs=512`, and find the
disk with `diskutil list external physical` first.

This overwrites part of the stock boot region, so make sure you still have your `stock_backup.img`
before doing it.
