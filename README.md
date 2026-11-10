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
- **ArkOS hotkeys**: Select+Start exit, Select+X menu, Select+R1/L1 save/load state, Select+R2 fast forward
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
1. **Back up your original SD card first.** It holds the vendor bootloader; without it the device can't boot.
   ```
   sudo dd if=/dev/rdiskN of=stock_backup.img bs=4m
   ```
2. Download `FakeR36S-OS_base_a23_panel2` from the latest Actions run or Release.
3. Build your flashable image. This copies your own card's boot region and checks the board variant:
   ```
   tools/make-flashable.sh goodluck_base_a23_panel2.img.xz stock_backup.img fakers36s.img
   ```
4. Flash `fakers36s.img` to a **new** microSD card and boot it in slot TF1. Your stock card stays untouched.

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
