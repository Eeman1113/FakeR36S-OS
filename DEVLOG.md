# FakeR36S-OS devlog

Hey, I'm Eeman (EemanSleepDeeprived). This is the running diary of FakeR36S-OS, the firmware I'm building for my fake R36S. Every push to `main` gets an entry here: what I changed, why, how I checked it, and what I still haven't tested on the real thing. Oldest at the top, newest at the bottom.

Some context, because it explains a lot of what follows. I bought what I thought was an R36S. It turned out to be a clone: a GA36-MB V1.2 board with an Allwinner A23 (two Cortex-A7 cores), a Mali-400 GPU, around 512 MB of RAM and a JD9366 screen ("panel 2"). ArkOS won't run on it. The stock firmware pretends to be ArkOS but isn't. So I'm making my own, and I want it to feel like the real thing.

Part 1 is the history of [goodluckOS](https://github.com/CodeZombie/goodluckOS), the project my fork stands on. I kept every commit of it here because none of this would exist without CodeZombie and everyone who contributed. Part 2 is mine.

The native Ocarina of Time port lives in its own repo, [FakeR36S-Ocarina](https://github.com/Eeman1113/FakeR36S-Ocarina).

## Part 1: goodluckOS (the base)

Everything below this line, until Part 2, is goodluckOS as CodeZombie (Jeremy Clark) and the contributors built it. I didn't write any of it. I just get to build on it, and I'm really grateful.

### 2026-08-25

#### `ff44892` 21:35 · Initial commit

*Jeremy Clark* · 1 file changed, 339 insertions(+) · in LICENSE

### 2026-08-26

#### `090b62b` 02:48 · Added base containerised build system

*Jeremy Clark* · 73 files changed, 7517 insertions(+) · in rootfs (58), home (5), kernel (5), image (2), .gitignore, BUILD.md

Includes all files necessary to build a minimally functional goodluckOS flashable image

#### `a6c5369` 02:50 · gitignored home/staging

*Jeremy Clark* · 3 files changed, 1 insertion(+), 1055 deletions(-) · in home (2), .gitignore

Deleted home/staging
Added home/staging to .gitignore

#### `d08e0ad` 03:27 · Added landing page

*Jeremy Clark* · 3 files changed, 644 insertions(+) · in docs (3)

### 2026-08-29

#### `31f66b3` 03:55 · package files for libretro cores

*Jeremy Clark* · 14 files changed, 408 insertions(+), 30 deletions(-) · in rootfs (11), home (2), image

[Puppy] Added 'Archives'
[Puppy] Added out-of-tree build.sh
[System-Settings] Added brightness and ALSA controls
[System-Settings] Added out-of-tree build.sh
[Rootfs] Added libretro cores #2
[Home] Added better retroarch config (fixed stuttering)  #6
[Image] Added bootimage.bmp

### 2026-08-30

#### `c04b18d` 13:25 · Auto resize home partition script

*Jeremy Clark* · 25 files changed, 3603 insertions(+), 1121 deletions(-) · in rootfs (20), home (2), image (2), .gitignore

[Rootfs] Added auto-resize-home-partition script
[Home] Added pcsx_rarmed opt file with good defaults
[Rootfs] Got rid of powerdaemon (player should now be able to poweroff/reboot directly)
[Rootfs] toggle screen script now triggers on button event up
[Rootfs] Added GBA/PSX/SNES archive desktop files
[Rootfs] Removed duplicate ga36-mb-gamepad autoconf file in /usr/share
[Puppy] Fixed mk/.in files.

### 2026-09-01

#### `b4e2197` 17:32 · Display driver now stable

*Jeremy Clark* · 4 files changed, 363 insertions(+), 329 deletions(-) · in kernel (4)

- Fixed issue where display driver failed to initialize ~10% of the time.
- Simplified display driver, removed unnecessary symbols.
- Rewrote dcs write function to return errors (They're unused, but it was useful for debugging and there's no reason to remove them)
- Removed `regulator-always-on` from `dldo3`

### 2026-09-04

#### `1ae9084` 03:40 · Revise README for clarity and update installation steps

*Jeremy Clark* · 1 file changed, 6 insertions(+), 5 deletions(-) · in README.md

Updated installation instructions and fixed formatting issues in the README.

### 2026-09-06

#### `f66691b` 17:59 · Fix typo in 'DISCLAIMER' section header

*Jeremy Clark* · 1 file changed, 1 insertion(+), 1 deletion(-) · in README.md

### 2026-09-23

#### `d22ed87` 14:56 · improved display driver, rewrote puppy, etc

*Jeremy Clark* · 70 files changed, 2470 insertions(+), 1378 deletions(-) · in rootfs (55), home (6), kernel (4), docs (2), BUILD.md, README.md

Improved the display driver
Rewrote puppy to be a lot simpler + not use .desktop files
Added doas
rewrote resize-home app + script
Removed USB network stack
Swapped gzDoom for Chocolate Doom
Added ImGui as a standalone lib packagae
Added are-you-sure app
Added bubblewrap + podman (for testing port packaging - not working, still in dev)
Updated website

#### `881957c` 14:59 · Merge branch 'main' of https://github.com/CodeZombie/goodluckOS (merge)

*Jeremy Clark*

### 2026-09-24

#### `f259bbd` 00:12 · Added PPSSPP

*Jeremy Clark* · 5 files changed, 79 insertions(+) · in rootfs (5)

PPSSPP builds and works!
Also added an entry to the default apps.puppy
I get ~okay~ framerates in ~some~ games.

### 2026-09-25

#### `62326c9` 02:07 · aliased reboot/poweroff, gallium hud, moved tempfiles

*Jeremy Clark* · 17 files changed, 86 insertions(+), 20 deletions(-) · in rootfs (16), home

App-specific temp files now live in /dev/shm
Added sega archives to apps.puppy
added sega icons
Reboot is no longer forced - Added reboot/poweroff alias to also kill puppy-bootstrap
Fixed bug with triggerhappy starting too early
Added global gallium-hud with MODE+SELECT

### 2026-09-26

#### `74e0177` 17:24 · puppy-bootstrap stopped on shutdown

*Jeremy Clark* · 8 files changed, 55 insertions(+), 14 deletions(-) · in rootfs (8)

puppy-bootstrap now automatically stops when the system attempts to shut down/reboot.
puppy-bootstrap is now a busybox init.d service
Added a version badge to puppy overlay.png
Fixed bug where all packages had to be re-downloaded after running ./scripts/clean.sh in rootfs container.

#### `5cfde42` 17:56 · S01resize-home only runs on startup

*Jeremy Clark* · 2 files changed, 6 insertions(+), 6 deletions(-) · in rootfs (2)

Fixed bug where S01resize-home would re-run at shutdown.
Fixed multiple puppy-bootstrap instances issue

#### `ced5e94` 20:53 · Updated readme, added changelog

*Jeremy Clark* · 2 files changed, 9 insertions(+), 2 deletions(-) · in CHANGELOG.md, README.md

### 2026-09-28

#### `6bd47b9` 16:22 · Added Download page, removed most hardcoded voltages from dts

*Jeremy Clark* · 7 files changed, 482 insertions(+), 34 deletions(-) · in rootfs (5), docs, kernel

Added a Downloads page so users can identify their hardware variants.
Removed most hard-coded regulator voltages from the .dts, as these values can be inherited from the bootloader.
Switched to out-of-chain reboot script to avoid reboot race conditions.
Mounted /run to tmpfs
Added extra file extensions to apps.puppy

#### `db6667d` 16:55 · Added Variant A support to h/w id tool, updated readme

*Jeremy Clark* · 2 files changed, 8 insertions(+), 1 deletion(-) · in README.md, docs

#### `6cc79df` 23:10 · Improved script.bin extraction logic

*Jeremy Clark* · 1 file changed, 75 insertions(+), 7 deletions(-) · in docs

The script.bin extraction logic in download.html now actually finds the length of the script.bin file before calculating the checksum.

This fixes a bug where it would miss positive matches.

### 2026-09-29

#### `cd12390` 12:11 · Added a compatible variant hash

*Jeremy Clark* · 1 file changed, 5 insertions(+), 1 deletion(-) · in docs

#### `e3dc7ef` 12:38 · Temporarily revoked Variant B support

*Jeremy Clark* · 1 file changed, 4 insertions(+), 4 deletions(-) · in docs

Variant B still needs to use it's own bootloader, even if the goodluck DTS is compatible.
I'm going to re-enable support for this variant as soon as I have my custom image builder ready to go (which should be really soon)

### 2026-09-30

#### `77a23ee` 01:02 · Added multi-SoC build support, a23 dts, firmware builder

*Jeremy Clark* · 6 files changed, 1138 insertions(+), 467 deletions(-) · in kernel (3), image (2), docs

Added an a23 DTS file. This is untested, but should be safe.
Added multi-SoC support to the build files.
Added a new Firmware Builder tool so users can create their own goodluckOS image based on their existing bootloaders.

### 2026-10-01

#### `4dfc38e` 16:06 · Added replace-mbr checkbox to firmware builder

*Jeremy Clark* · 2 files changed, 37 insertions(+), 15 deletions(-) · in README.md, docs

Users can now skip the replace MBR step in the builder.
This is for debug purposes only. It will likely not actually build a firmware that can boot into goodluckOS, but if all the steps were followed correctly, it should produce an image that can at least reach the bootloader.

#### `919e38e` 16:46 · Added known-unsupported feature to fw builder

*Jeremy Clark* · 1 file changed, 27 insertions(+), 7 deletions(-) · in docs

#### `2d6b2b2` 09:56 · Fixed shutdown and reboot hanging when no USB cable is plugged in

*alvesmaicon* · 1 file changed, 6 insertions(+) · in rootfs

Unbinding the serial gadget from the UDC never returns without VBUS, so rcK stopped at
S30usb-gadget and the console never powered off or rebooted. The gadget is now only torn down when
USB power is present.

#### `f8c3a90` 07:45 · Fixed power off: marked the AXP223 as the system power controller

*alvesmaicon* · 2 files changed, 6 insertions(+) · in kernel (2)

Without x-powers,system-power-controller the axp20x driver never registers a power-off handler,
so poweroff ran the whole shutdown and then just halted the CPU, leaving the screen dark with the
backlight on and the battery draining.

#### `fc0f997` 23:03 · Refined Firmware Builder UI

*Jeremy Clark* · 1 file changed, 58 insertions(+), 63 deletions(-) · in docs

### 2026-10-02

#### `b0cc413` 11:49 · Show HOME on the PC over USB (MTP), like a phone

*alvesmaicon* · 4 files changed, 61 insertions(+), 13 deletions(-) · in rootfs (3), kernel

The USB gadget becomes a composite device: the ACM serial console plus an
MTP function served by uMTP-Responder over FunctionFS. HOME stays mounted
on the console while the PC browses it. On a kernel without FunctionFS the
gadget falls back to serial only.

- kernel: CONFIG_USB_CONFIGFS_F_FS
- rootfs: BR2_PACKAGE_UMTPRD, /etc/umtprd/umtprd.conf
- S30usb-gadget: ffs.mtp function, start umtprd before binding the UDC

#### `b676c24` 12:05 · USB gadget: never lose the serial console to MTP

*alvesmaicon* · 1 file changed, 36 insertions(+), 5 deletions(-) · in rootfs

On the first try the gadget never bound with MTP, which took the serial
console down with it, and the shutdown then hung unbinding the UDC with
the cable in.

- If the bind fails, or the PC has not enumerated the device 15s after
  binding with the cable in, rebuild the gadget with the serial console
  alone. The reason goes to /tmp/usb-gadget.log, umtprd's output to
  /tmp/umtprd.log.
- stop: give the UDC unbind 3s, then let the shutdown go on.

#### `59b5cda` 12:09 · kernel: CONFIG_POSIX_MQUEUE for umtprd

*alvesmaicon* · 1 file changed, 1 insertion(+) · in kernel

umtprd passes messages between its threads with a POSIX message queue;
without it mq_open fails and umtprd exits before writing the MTP
descriptors, so the gadget cannot bind.

#### `4f2ad27` 12:38 · kernel: musb gadget kept losing OUT packets, which hung MTP copies

*alvesmaicon* · 2 files changed, 43 insertions(+) · in kernel (2)

musb_ep_restart() flushed the RX FIFO when an OUT request was queued on
an idle endpoint, so a packet that had arrived in between was dropped.
FunctionFS queues one request per read(), and the MTP data phase comes
right after its command: copies to the console hung with a 0-byte file.
The serial console never hit it because u_serial keeps requests queued.

Patches now live in kernel/patches/ and are applied before the build.

#### `15ee5d6` 12:53 · README: copy games over USB (MTP)

*alvesmaicon* · 1 file changed, 4 insertions(+), 2 deletions(-) · in README.md

Moves "Mount device storage via USB" from in development to features,
and explains it in How do I add games, with its two limits (booted on a
charger, and Puppy listing new games only after reopening).

#### `cf8fd6f` 16:27 · Updated Landing Page

*Jeremy Clark* · 1 file changed, 7 insertions(+), 16 deletions(-) · in docs

The landing page has been updated to reflect the new firmware-builder process.

### 2026-10-03

#### `3eb0c91` 02:18 · Added links to video guides

*Jeremy Clark* · 1 file changed, 75 insertions(+), 5 deletions(-) · in docs

Improved firmware builder page logo
Added video guide links in firmware builder
Fixed firmware builder light mode text colors

#### `9e919cd` 12:45 · Fixed swapped A/B buttons in RetroArch

*Jeferson Lopes* · 2 files changed, 5 insertions(+), 5 deletions(-) · in home (2)

#### `619cab3` 17:36 · Merge pull request #52 from alvesmaicon/feat/mtp-home (merge)

*Jeremy Clark*

Feat/mtp home courtesy of alvesmaicon

#### `0b7385f` 17:46 · Added Design Philosophy and AI policy to Readme

*Jeremy Clark* · 1 file changed, 14 insertions(+) · in README.md

#### `92f6113` 20:03 · Merge pull request #48 from jefersonftlopes/fix-retroarch-ab (merge)

*Jeremy Clark*

Fix swapped A/B buttons in RetroArch

### 2026-10-04

#### `caa73df` 00:31 · S99appd + correct kernel headers in rootfs

*Jeremy Clark* · 20 files changed, 465 insertions(+), 105 deletions(-) · in rootfs (16), kernel (2), home, image

Replaced puppy-bootstrap with a much more versatile and flexible appd.
Appd fully manages the launcher->app->launcher lifecycle. Puppy no longer has any knowledge of how any of that works outside of now needing to launch apps through appd.
This also lets us swap out any launcher for any other launcher and as long as it launches all apps through appd, it'll work.

Added evsieve

Removed power-management scripts - doas /sbin/reboot works now.

#### `3ca17cd` 02:11 · moved appd logic to appctl

*Jeremy Clark* · 6 files changed, 395 insertions(+), 383 deletions(-) · in rootfs (6)

#### `c1c0d88` 02:11 · Merge branch 'main' of https://github.com/CodeZombie/goodluckOS (merge)

*Jeremy Clark*

#### `729c09d` 13:04 · Headphones on the GA36-MB A33, and FN+DPAD_DOWN to switch speaker/headphones

*alvesmaicon* · 4 files changed, 27 insertions(+), 1 deletion(-) · in rootfs (2), README.md, kernel

The headphone jack is wired for direct drive (stock script.bin:
headphone_direct_used=1), so its return goes to the codec's HPCOM instead of
ground. Nothing routed to HPCOM, so it stayed off: a pop, then about a second
into playback the codec muted the headphone output. Routing the jack to HPCOM
makes the headphones play on both sides.

There is no jack detection on the v1.1 (no GPIO, LRADC or codec HMIC change
when plugging it in) and the speaker amp is fed from the headphone output, so
both play at once. A pin switch adds a "Speaker Switch" ALSA control, and
audio-output.sh turns it off for headphones and on for the speaker.
FN+DPAD_DOWN toggles it. Like the volume, the choice isn't saved: the speaker
comes back on at boot.

Fixes #7.

#### `8738dd4` 15:28 · Boot: start appd with appctl's full path, and drop the power-manager respawn

*alvesmaicon* · 3 files changed, 3 insertions(+), 4 deletions(-) · in rootfs (3)

S99appd called "appctl", but init runs the boot scripts with
PATH=/sbin:/usr/sbin:/bin:/usr/bin (/usr/local/bin is only added for login
shells by profile.d/path.sh), so appd never started and the launcher didn't
come up after boot.

post-build.sh still added "::respawn:/usr/local/bin/power-manager.sh" to
inittab after power-manager.sh was removed, so init retried the missing
script once a second ("can't run ... No such file or directory").

doas.conf allowed /usr/bin/local/appctl, a path that doesn't exist; it's
/usr/local/bin/appctl. The "cmd appctl" rule already covered it.

Tested on a GA36-MB v1.1 (A33): the launcher starts on boot, nothing in the
log about power-manager, and doas /usr/local/bin/appctl works as player.

#### `85b741e` 21:32 · Added terminal apps, save volume+brightness across reboots

*Jeremy Clark* · 5 files changed, 61 insertions(+), 24 deletions(-) · in rootfs (4), kernel

#### `0284d54` 21:38 · Removed alpha 0.0.1 banner

*Jeremy Clark* · 2 files changed, 0 insertions(+), 0 deletions(-) · in home, rootfs

#### `a49c226` 22:12 · Merge branch 'main' into pr/boot-fixes (merge)

*Jeremy Clark*

#### `6c1a2de` 22:18 · Merge pull request #56 from alvesmaicon/pr/headphones (merge)

*Jeremy Clark*

Headphones on the GA36-MB A33, and FN+DPAD_DOWN to switch speaker/headphones

#### `89f557a` 22:18 · Merge pull request #55 from alvesmaicon/pr/boot-fixes (merge)

*Jeremy Clark*

Fix boot: start appd with appctl's full path, drop the power-manager respawn

### 2026-10-05

#### `baa2748` 00:56 · Added "proceed anyway' feature to firmware builder

*Jeremy Clark* · 1 file changed, 23 insertions(+), 3 deletions(-) · in docs

#### `e83372f` 23:47 · DTS: power the TF-2 slot (mmc1)

*alvesmaicon* · 1 file changed, 1 insertion(+) · in kernel

mmc1 had no vmmc-supply, so the controller offered no voltage and turned
any card down: "no support for card's volts", error -22. It's now on
vcc-io (dcdc1), the rail that also feeds port PG and the main slot.
Still non-removable: the slot has no card-detect pin, so the card is
found at boot and the kernel doesn't poll for it.

Tested on a GA36-MB v1.1 (A33) with a 1 GB and a 16 GB card. The A23 DTS
has the same node but I have no A23 board to test it on.

#### `fed7666` 23:47 · Mount the TF-2 card at boot and list its games

*alvesmaicon* · 4 files changed, 66 insertions(+), 24 deletions(-) · in rootfs (3), README.md

udev runs external-card.sh for the partitions of mmcblk1: the largest FAT
partition is mounted at /media/external, owned by player like HOME, and
unmounted when the card goes away. The runs for each partition take
turns, so a card with several FAT partitions gets only one mounted. A
card without roms/ gets the same system folders as HOME.

Every system in apps.puppy also looks in /media/external/roms/<system>,
so the card's games show up in the system tabs, covers included, with
no change to Puppy. README: how to lay out the card.

Tested on a GA36-MB v1.1 (A33): a 1 GB card with games and a 16 GB card
with three FAT partitions (the stock one).

### 2026-10-06

#### `92dbd7f` 13:13 · post-build.sh: make it safe to run again on the same target

*alvesmaicon* · 1 file changed, 5 insertions(+), 3 deletions(-) · in rootfs

Buildroot runs post-build.sh on every make, but the script assumed a
fresh target: the second run (any incremental build) fails on the sed
of S10triggerhappy, already renamed to S99, and on mkdir of the existing
player-flags. The sed now takes either name, the rename only happens
once, and mkdir uses -p. A fresh build ends up the same as before.

#### `9e88c36` 14:18 · Merge pull request #60 from alvesmaicon/pr/post-build-rerun (merge)

*Jeremy Clark*

post-build.sh: make it safe to run again on the same target

#### `e7d2e7f` 21:35 · Merge pull request #59 from alvesmaicon/pr/tf2-slot (merge)

*Jeremy Clark*

Power the TF-2 slot and list the second card's games

#### `0a3ee7a` 21:38 · Fixed a23 audio, added panel 2 init sequence

*Jeremy Clark* · 3 files changed, 171 insertions(+), 67 deletions(-) · in kernel (3)

Fixes #42

#### `e57a1e5` 22:46 · Puppy: holding a direction repeats the move

*alvesmaicon* · 1 file changed, 37 insertions(+), 5 deletions(-) · in rootfs

Holding the d-pad (or an arrow key) moves once, then repeats after
350 ms every 60 ms until it is released. Launching clears the held
direction, so a release lost while the app runs can't keep it moving.
SDL's own keyboard repeat is ignored so keys don't repeat twice.

Closes #61

#### `0e1026f` 22:23 · Merge pull request #64 from alvesmaicon/pr/puppy-dpad-repeat (merge)

*Jeremy Clark*

Puppy: holding a direction repeats the move

### 2026-10-07

#### `e513411` 02:33 · Remove old installation instructions for goodluckOS

*muhammed bayrak* · 1 file changed, 7 deletions(-) · in README.md

Removed old installation instructions for goodluckOS from README.

### 2026-10-06

#### `0bdb9e6` 13:57 · MTP: show the TF-2 card on the PC too, next to HOME

*alvesmaicon* · 3 files changed, 15 insertions(+) · in rootfs (3)

umtprd gets a second storage, "External card" at /media/external, left
hidden (notmounted). external-card.sh tells umtprd to show it once the
card is mounted and to hide it before unmounting, so the PC drops it
first. A card mounted at boot comes up before umtprd, so S30usb-gadget
asks for it once MTP is up. umtprd -cmd only runs while umtprd does:
started on its own it would become a second daemon.

Tested on a GA36-MB v1.1 (A33): the card shows up next to HOME at boot,
goes away and comes back when unmounted and mounted again, and files
copied from the PC arrive intact.

#### `a57b9d6` 22:42 · Merge pull request #65 from muhammedbyk/patch-1 (merge)

*Jeremy Clark*

Remove old installation instructions for goodluckOS

### 2026-10-07

#### `8759cd2` 10:44 · RetroArch: A few nice improvements have been added.

*muhammed bayrak* · 1 file changed, 6 insertions(+), 6 deletions(-) · in home

Select + Y can now be used as a shortcut to take screenshots.
The left joystick is now set to D-pad mode by default.
Save files, screenshots, and savestates are now organized into separate folders for each game, which makes them much easier to manage.

#### `362029f` 10:44 · Merge branch 'main' of https://github.com/muhammedbyk/goodluckOS (merge)

*muhammed bayrak*

#### `93b0b26` 21:59 · Merge pull request #66 from alvesmaicon/pr/external-mtp (merge)

*Jeremy Clark*

MTP: show the TF-2 card on the PC too, next to HOME

#### `fe14073` 18:05 · A23 audio: speaker/headphone switch and headphone direct drive

*Maicon Alves* · 2 files changed, 41 insertions(+), 1 deletion(-) · in kernel (2)

Two gaps left over after the #42 fix (0a3ee7a): the A23 card never
exposed a way to mute the speaker on its own, and the headphone jack's
return (HPCOM) was never routed, so headphones alone could pop and then
go silent after about a second, the same bug the A33 had before #7.

The kernel patch adds a "Speaker" pin switch to the A23 card, mirroring
what sun50i-h616 already does in the same driver file. It shows up in
ALSA as "Speaker Switch", the same name audio-output.sh and FN+DPAD_DOWN
already look for, so no userspace changes are needed.

Not tested on real A23 hardware. The patch applies cleanly against the
current sun4i-codec.c from Linux's own tree, but muhammedbyk's A23 is
the only way to confirm either change actually fixes #68.

#### `70d8d86` 23:53 · Panel toggle via .dts

*Jeremy Clark* · 3 files changed, 184 insertions(+), 168 deletions(-) · in kernel (3)

The panel-1/panel-2 init sequence can now be toggled from the device tree.

### 2026-10-08

#### `f32cd1a` 08:47 · puppy: navigate with the left stick as well as the d-pad

*Claude* · 1 file changed, 35 insertions(+) · in rootfs

Map the left stick onto the existing Up/Down/Left/Right actions, so it
gets the same hold-to-repeat behaviour as the d-pad with no new input
path. The d-pad and keyboard code is untouched.

A direction engages past about half travel and is held until the stick
falls back below about a quarter, and only switches to another direction
on a deliberate push. A stick that wobbles sideways while springing back
to centre therefore doesn't produce a stray move.

Claude-Session: https://claude.ai/code/session_01HBEuXjT5n7LKwooYDo75zj

#### `4952ed0` 11:52 · Merge branch 'CodeZombie:main' into puppy-left-stick (merge)

*muhammed bayrak*

#### `440ee48` 12:57 · Merge pull request #72 from muhammedbyk/puppy-left-stick (merge)

*Jeremy Clark*

Puppy Launcher: Add left joystick navigation support

#### `c75dab5` 23:13 · MTP: a cancelled copy no longer leaves its partial file on the console

*alvesmaicon* · 2 files changed, 46 insertions(+) · in rootfs (2)

Cancelling a copy to the console in the PC's file manager left the
part already sent on HOME: umtprd stops reading, closes the file and
returns, but never removes it. The PC no longer lists the file, so the
space stays taken and can only be freed on the console. Seen with a
384 MB video cancelled at 347 MB.

umtprd 1.8.1 (Buildroot's, also the latest release) and its master
have the same code. A patch through BR2_GLOBAL_PATCH_DIR removes the
file and its entry on a cancelled SendObject, as DeleteObject does
(under the storage's uid/gid), and forgets the object handle. A
cancelled SendPartialObject keeps its file, which existed before.

goodluck_defconfig gets BR2_GLOBAL_PATCH_DIR (board/my-device/patches),
Buildroot's way to patch one of its own packages.

#### `7ce6cea` 23:32 · MTP: a folder made and renamed on the PC no longer shows twice

*alvesmaicon* · 1 file changed, 201 insertions(+) · in rootfs

Windows makes a folder as "New folder" and then renames it. umtprd 1.8.1
renames its entry without moving it in the name hash table, so its own
inotify watch doesn't find the new name and adds a second entry: the PC
lists the folder twice (both open the same folder on the card). Seen
with media/ and media/video/ made from Windows.

umtprd's master fixed it in 806536d (PR #144, after the 1.8.1 release):
backported as it is, as 0002.

### 2026-10-09

#### `44a93a0` 18:18 · Merge pull request #70 from alvesmaicon/pr/a23-audio (merge)

*Jeremy Clark*

A23 audio: speaker/headphone switch and headphone direct drive

#### `b9dadb7` 20:38 · Merge pull request #77 from alvesmaicon/pr/mtp-cancel (merge)

*Jeremy Clark*

MTP: remove a cancelled copy's partial file, and fix a renamed folder showing twice

#### `8e2e67c` 23:34 · Refactored dts/dtsi, added kernel exFAT

*Jeremy Clark* · 13 files changed, 257 insertions(+), 567 deletions(-) · in kernel (11), image (2)

#### `6f24849` 23:36 · fixed indent in kernel build Dockerfile

*Jeremy Clark* · 1 file changed, 7 insertions(+), 7 deletions(-) · in kernel

### 2026-10-10

#### `4a31a08` 03:39 · tf-2 hotplug, credits app, exFAT, partitionless disk

*Jeremy Clark* · 15 files changed, 948 insertions(+), 16 deletions(-) · in rootfs (12), kernel (2), image

Pinned linux version to 7.2.9
Added `credits` app
Added support for removing/re-inserting a microSD card into TF-2
Added a umount entry to Puppy to safely unmount the card in TF-2
Added support for partitionless microSD cards in TF-2
Added exFAT support for TF-2 cards
Added simple "user guide" app which is just less pointed to a text file

### 2026-10-12

#### `0cf988f` 10:49 · appctl: start the autolaunch entry at boot

*Maicon Alves* · 1 file changed, 11 insertions(+), 1 deletion(-) · in rootfs

Puppy saves the entry picked with SELECT to /home/player/autolaunch,
but nothing started it at boot. appd now launches it once per boot
instead of the launcher; when it exits, the launcher comes up as usual.

Fixes #82.

#### `e0b9b6e` 14:13 · kernel: clear the BSP boot flag on power off

*Maicon Alves* · 1 file changed, 26 insertions(+) · in kernel

Plugging a charger into a powered off console booted goodluckOS. The
stock firmware only lit the charging LED.

The stock BSP u-boot decides this with a flag in the AXP223 data buffer
register 0x0f. It writes 0x0e on every boot. When the PMIC powers up
with a charger present, it reads the flag: 0x0e means the system was
running, so it boots; any other value sends it to its charger screen
(the BAT*.BMP frames in the stock FAT, already on every card). The BSP
kernel writes 0x00 there on power off. The mainline power off path only
writes the off bit in register 0x32, so the flag stays 0x0e forever and
u-boot always boots. script.bin asks for the charger screen
([pmu1_para] power_start = 0).

Found by disassembling the stock u-boot (axp_probe_startup_cause reads
register 0x0f; "pre sys mode" for 0x0e) and confirmed on the console:
register 0x0f reads 0x0e while goodluckOS runs.

Reboot is unchanged: it doesn't go through the power off path, so the
flag stays 0x0e and u-boot boots as before.

Fixes #85.

### 2026-10-16

#### `757e7c1` 07:22 · Battery savings in sleep and the launcher, own icon for Eject TF-2

*muhammed bayrak* · 5 files changed, 45 insertions(+), 6 deletions(-) · in rootfs (5)

Sleep (power button, screen off):
- Freezes the launcher and the running app (appd cgroup), so the CPU
  and GPU go idle and the game waits instead of running on unseen.
- Holds the gamepad (evsieve), so presses in a pocket don't reach the app.
- Turns the speaker amp off if it was on.
Waking undoes all three. MTP and other services keep running.

Launcher (Puppy):
- Polls input every 10 ms instead of SDL2's 1 ms on KMSDRM: about 8x
  less idle CPU time, no noticeable input delay.

Eject TF-2:
- Has its own eject icon (RemixIcon, same style as the other system
  icons) instead of the Power Off icon.

#### `d42dd11` 07:58 · Puppy: icons for User Guide and Credits

*muhammed bayrak* · 4 files changed, 4 insertions(+) · in rootfs (4)

User Guide gets RemixIcon's book-open-line and Credits its team-line,
rendered like the other system icons (48 px, #D2D2D2) and credited in
ATTRIBUTION.txt. Before, both showed the default terminal icon.

#### `eb27fbc` 08:54 · Sleep: find the gamepad by its real name, so the grab works

*muhammed bayrak* · 1 file changed, 1 insertion(+), 1 deletion(-) · in rootfs

toggle-screen.sh looked for an input device named 'GA36-MB-Gamepad',
but the driver names it 'GA36-MB Gamepad' (a space, not a hyphen). The
gamepad was never found, so the grab didn't start and buttons pressed
while asleep still reached the app after waking.

#### `e37b0c7` 10:54 · Merge pull request #88 from alvesmaicon/pr/autolaunch (merge)

*Jeremy Clark*

appctl: start the autolaunch entry at boot

#### `4f30497` 18:01 · Added glos-setup app

*Jeremy Clark* · 16 files changed, 500 insertions(+), 73 deletions(-) · in rootfs (12), CHANGELOG.md, README.md, docs, home

glos-setup featuring a headphone warning.
We may remove this in future versions when headphone audio becomes safe, but it must remain in place for now.

#### `8d676e2` 18:14 · Added panel support to firmware builder

*Jeremy Clark* · 1 file changed, 14 insertions(+), 10 deletions(-) · in docs

### 2026-10-20

#### `75ce5cf` 14:58 · A23: enable drivevbus so the USB PHY probes

*Michal Genserek* · 1 file changed, 4 insertions(+) · in kernel

- usb0_vbus-supply points at reg_drivevbus, which the AXP223 driver only
  registers with x-powers,drive-vbus-en; without it usbphy defers forever,
  musb never probes and neither the serial console nor MTP appears

### 2026-11-02

#### `c00e0ed` 21:14 · Bring up the loopback interface at boot

*Maicon Alves* · 1 file changed, 8 insertions(+) · in rootfs

Nothing configures networking (Buildroot's ifupdown-scripts is off in goodluck_defconfig), so lo stays down and every socket on 127.0.0.1 fails. Luanti's singleplayer runs a local server and the game stops at "Failed to bind socket" before the world opens: an app installed with the App Installer of #103 showed it on an A23, and an A33 v1.1 behaves the same. With lo up the world opens.

### 2026-11-05

#### `42c046a` 23:28 · Merge pull request #115 from rincewindcz/a23-usb-drivevbus (merge)

*Jeremy Clark*

A23: USB OTG never probes (no serial console, no MTP)

#### `923717f` 23:43 · Updated Readme to mention GA36Ports

*Jeremy Clark* · 1 file changed, 3 insertions(+), 9 deletions(-) · in README.md

Updated Readme to mention GA36Ports, removed template Screenshots section

#### `ea288a6` 23:52 · Merge pull request #89 from alvesmaicon/pr/charger-boot (merge)

*Jeremy Clark*

Show the charging screen instead of booting when plugged in while off

### 2026-11-06

#### `fbe096f` 00:05 · Merge pull request #147 from alvesmaicon/pr/loopback (merge)

*Jeremy Clark*

Bring up the loopback interface at boot

### 2026-11-07

#### `60fc974` 15:16 · Added support for A23-Elgom variant

*Jeremy Clark* · 1 file changed, 5 insertions(+), 1 deletion(-) · in docs

This closes #137

### 2026-11-08

#### `fb23346` 13:40 · Improved documentation files

*Jeremy Clark* · 3 files changed, 119 insertions(+), 23 deletions(-) · in README.md, SOFTWARE.md, rootfs

Added SOFTWARE.md and filled out PUPPY.md

#### `2e437cd` 23:37 · Updated libretro-cores git version to `master`

*Jeremy Clark* · 1 file changed, 1 insertion(+), 1 deletion(-) · in rootfs

The "Latest" version of the libretro-super repo is actually 6 years old. `master` is actually actually the most current.

### 2026-11-09

#### `4b51c1f` 23:17 · Merge pull request #98 from muhammedbyk/batterySavingsAndicons (merge)

*Jeremy Clark*

Battery optimizations, sleep mode and own icon for settings related apps

## Part 2: FakeR36S-OS

### 2026-11-11

**Day summary.** The longest day. I went from "can this board even run anything else?" to my own firmware booting on the device, in one night and one day.

- **Getting started.** I forked goodluckOS, kept its mainline Linux 7.2.9 kernel with the panel 2 driver, and spliced my card's stock boot0 and U-Boot in from my own backup (they never go in the repo). My board turned out to be the "A23 Esisla" variant; the SHA-256 of its script.bin is how the tools recognise it.
- **Making it feel like ArkOS.** EmulationStation fcamod as the frontend, 40 systems with the best core already picked for this weak little chip, automatic scaling per system, ArkOS hotkeys, and Select+B for an FPS counter (I really wanted that one).
- **Making it mine.** My logo as the boot logo, an animated splash with a chime and "made by EemanSleepDeeprived" printed along the edge of the logo, and my logo with a tiny spinner on every loading screen instead of the cat. Plus a dashboard with live graphs, because I'm a developer and I like graphs, a battery saver, and a fix for the headphone pop that annoyed me forever.
- **The build fought back.** Buildroot 2026 with CMake 4 and GCC 15 broke a lot of old code: FreeImage missing (borrowed from Batocera), a Kconfig loop, CMake refusing old projects, C23 breaking older C, a libretro pin, the OS outgrowing its partition, and three cores quietly building x86 code for an ARM device. One fix at a time until CI went green.
- **The first boots were rough.** First the cat spinner forever (a library wasn't installed). Then a controller setup screen every boot (ES hard-codes a path; I patched it). Then I booted my freshly flashed card and landed in Puppy instead of EmulationStation, with save states stuck at 0%. That one took digging: the first-boot resize remounted my games partition read-only for my user, so nothing could save. One missing mount option. Fixed in `d3e84e7`, and after that it finally felt real.
- **Looks.** EPIC-CODY by CodyV59, the theme from my stock card, became the default, plus box art tools and an installer step that fetches art in the browser.

#### `07bd2fe` 02:30 · FakeR36S-OS 1.0: ArkOS-style firmware for the fake R36S (GA36-MB, Allwinner A23)

*Eeman1113* · 110 files changed, 2258 insertions(+), 168 deletions(-) · in home (70), rootfs (34), kernel (2), .github, README.md, image

- EmulationStation (fcamod) frontend with carbon theme, boots straight in
- 43 systems with the best core preselected for the A23, incl. N64 (ParaLLEl)
- Automatic per-system scaling: integer / sharp (FP16-safe 2-pass) / smooth
- ArkOS hotkeys in RetroArch
- CPU frequency scaling from the board's stock DVFS table + opt-in 1.2 GHz mode
- System Dashboard with live CPU, battery, memory, storage, temperature graphs
- Headphone pop and volume-spike fix (codec kept powered, per-output volume, fade-in)
- Animated boot splash with chime, quiet boot, custom boot logo
- CI build on GitHub Actions; tools/make-flashable.sh for the user's stock boot region

#### `e2e6c82` 02:31 · Grow the HOME partition to fill the card automatically on first boot

*Eeman1113* · 1 file changed, 1 insertion(+) · in rootfs

#### `e0920cb` 02:31 · Select+B toggles the FPS counter in games

*Eeman1113* · 2 files changed, 2 insertions(+), 2 deletions(-) · in README.md, home

#### `f871752` 02:32 · Keep game saves next to the ROMs, like the stock GA36 firmware

*Eeman1113* · 1 file changed, 3 insertions(+), 3 deletions(-) · in home

#### `16a3795` 02:35 · README: step-by-step stock card backup (macOS, Linux, Windows), verify, restore

*Eeman1113* · 1 file changed, 73 insertions(+), 6 deletions(-) · in README.md

#### `9d57e0f` 02:45 · README: full credits and thanks to goodluckOS, Debianator, ArkOS and the community

*Eeman1113* · 1 file changed, 42 insertions(+), 7 deletions(-) · in README.md

#### `92b8f23` 02:50 · Automatic battery saver: 816 MHz cap for 8/16-bit systems, toggle in the dashboard; README: no BIOS included

*Eeman1113* · 6 files changed, 80 insertions(+), 43 deletions(-) · in rootfs (4), README.md, home

#### `2db6e5e` 02:51 · CI: publish each main build as the 'latest' release (gzip for the web installer, xz, checksums)

*Eeman1113* · 1 file changed, 17 insertions(+), 1 deletion(-) · in .github

#### `7aa3b99` 02:57 · Web installer: build the flashable image in the browser (board check, splice, boot logo); nothing uploaded

*Eeman1113* · 6 files changed, 312 insertions(+), 1393 deletions(-) · in docs (6)

#### `ad25ee8` 09:57 · Fix the OS build: add libfreeimage (from Batocera) for EmulationStation, fix the SDL2/ImGui Kconfig loop, fetch the kernel from cdn.kernel.org with retries

*Eeman1113* · 15 files changed, 335 insertions(+), 6 deletions(-) · in rootfs (13), README.md, kernel

#### `934f98a` 10:02 · Rename the FreeImage package to fr-freeimage (Buildroot keeps libfreeimage as a legacy symbol)

*Eeman1113* · 12 files changed, 57 insertions(+), 57 deletions(-) · in rootfs (12)

#### `96b4cae` 12:18 · Fix CMake 4 / GCC 15 issues (ES policy minimum + cstdint, gnu17 for C cores and parallel-n64); add Colab build helper

*Eeman1113* · 5 files changed, 34 insertions(+), 3 deletions(-) · in rootfs (3), tools (2)

#### `e35ac62` 14:22 · Pin libretro-super to a commit (Buildroot 2026 can't use a branch name as a git version)

*Eeman1113* · 1 file changed, 3 insertions(+), 1 deletion(-) · in rootfs

#### `e0928e9` 16:44 · Image: 1.4 GiB system partition (the full OS no longer fits goodluckOS's 384 MiB)

*Eeman1113* · 1 file changed, 5 insertions(+), 3 deletions(-) · in image

#### `ce01eb4` 16:57 · Systems: use cores that built (mGBA for GBA, Genesis Plus GX for Mega Drive/SMS/Sega CD); hide 32X, Vectrex, DOS until their cores build; add tools/assemble-base.sh

*Eeman1113* · 3 files changed, 50 insertions(+), 34 deletions(-) · in home (2), tools

#### `263eb82` 17:04 · Build gpSP, PicoDrive and VecX for the Cortex-A7 (platform=unix emitted x86 code); make CI caches saveable

*Eeman1113* · 2 files changed, 18 insertions(+) · in .github, rootfs

#### `70a52e5` 19:57 · Fix ES start (install bundled libpugixml); logo + spinner loading screen everywhere (boot, launcher, apps) replacing the ASCII cat; splash keeps the logo; launcher logs and falls back to Puppy

*Eeman1113* · 9 files changed, 195 insertions(+), 38 deletions(-) · in rootfs (8), home

#### `5595c05` 20:13 · Splash: credit printed isometrically along the logo's lower-right edge, no underline; frame-by-frame preview mode

*Eeman1113* · 1 file changed, 33 insertions(+), 18 deletions(-) · in rootfs

#### `59f0ec7` 20:22 · ES reads input config from /etc/emulationstation (hard-coded): link it to the preset in HOME so no setup screen and remaps save; launch Tools apps through appctl so ES never loses the gamepad

*Eeman1113* · 6 files changed, 16 insertions(+), 5 deletions(-) · in home (5), rootfs

#### `848d626` 20:26 · ES: patch to read and save es_input.cfg in ~/.emulationstation (fcamod hard-codes /etc); drop the /etc link

*Eeman1113* · 2 files changed, 21 insertions(+), 1 deletion(-) · in rootfs (2)

#### `adfb966` 20:36 · Default theme: EPIC-CODY by CodyV59 (EpicNoir fork, 640x480 RG351V edition), fetched unmodified from upstream (CC BY-NC-SA 4.0); carbon stays as fallback

*Eeman1113* · 6 files changed, 35 insertions(+), 3 deletions(-) · in rootfs (4), README.md, home

#### `d3e84e7` 22:28 · Fix first boot: remount HOME writable for player, save states, settings app

*Eeman1113* · 5 files changed, 10 insertions(+), 21 deletions(-) · in rootfs (3), home (2)

- S01resize-home remounted HOME without uid/gid after growing it, so the
  whole first boot ran with a read-only HOME for the player user: ES could
  not open its log and fell back to Puppy, glos-setup could not finish,
  save states hung at 0%. Mount with the same options as fstab.
- appctl: detach the loading spinner from the control FIFO.
- RetroArch: uncompressed save states in a flat states dir (pre-created).
- System Settings: drop placeholder buttons that did nothing.

#### `0a1beb4` 22:34 · ES: enable theme sounds and background music (roms/bgmusic)

*Eeman1113* · 2 files changed, 5 insertions(+), 1 deletion(-) · in home (2)

#### `762f6ce` 22:48 · tools/fetch-art.py: box art from libretro thumbnails for games without art [skip ci]

*Eeman1113* · 2 files changed, 254 insertions(+) · in README.md, tools

#### `11238fc` 22:54 · Web installer: automatic box art (step 5), weekly art index refresh [skip ci]

*Eeman1113* · 40 files changed, 438 insertions(+), 1 deletion(-) · in docs (36), tools (2), .github, README.md

### 2026-11-12

**Day summary.** Playing it for real and fixing what that turned up.

- The theme had no art at all, just text on blue, and my old card looked so much better. Turned out my own install recipe deleted the theme's art folder. Facepalm. Fixed in `28c35d0`.
- I added a power menu when you hold the power button (`4492f39`), and a Ports system in ES (`04745d3`) so native games show up next to the emulators. That one is for the native Ocarina of Time port, which I'm way too excited about.
- Shutting down from ES threw me back into goodluckOS's launcher, and shutting down from there got stuck on my loading screen. ES calls `sudo`, which doesn't exist here, and the shutdown path had no safety net. `7399902` sends every shutdown through one script with a watchdog and a log, so it always finishes and I can see why if it doesn't.

#### `28c35d0` 00:18 · EPIC-CODY: keep _art (posters, controllers, system sounds)

*Eeman1113* · 1 file changed, 3 insertions(+), 2 deletions(-) · in rootfs

#### `4492f39` 01:01 · Hold power button for a power menu (shut down, restart, cancel)

*Eeman1113* · 8 files changed, 211 insertions(+), 1 deletion(-) · in rootfs (8)

- power-key.sh: tap still turns the screen off/on; holding 1.5 s opens the menu
- power-menu.sh: wakes the screen, closes a running game with SIGTERM so
  RetroArch writes its save, then shows the menu through appd
- power-menu: ImGui app with battery level, FakeR36S colours

#### `04745d3` 01:07 · Ports system in EmulationStation

*Eeman1113* · 6 files changed, 85 insertions(+) · in home (3), rootfs (2), README.md

fr-ports-sync turns installed goodluckOS ports (ports/<id>/ plus their Puppy
entry, as published by ga36-ports) into roms/ports launchers with names,
descriptions and icons; launcher.sh runs it before ES starts. fr-port runs
them at full CPU speed with a log.

#### `7399902` 01:56 · Shutdown and restart that always finish

*Eeman1113* · 6 files changed, 67 insertions(+), 4 deletions(-) · in home (3), rootfs (3)

- fr-poweroff: stops appd first (games save, nothing relaunches), syncs, powers
  off or reboots, and a watchdog outside appd's cgroups forces it after 25 s if a
  stop script hangs; every step logged to .config/fakers36s/shutdown.log
- EmulationStation's Quit menu calls 'sudo shutdown', absent here: launcher.sh
  picks up ES's /tmp/es-shutdown and es-sysrestart markers and does it for real
  (it used to drop to Puppy)
- power menu and Puppy's Power Off / Reboot go through fr-poweroff

#### devlog · Starting this devlog

*Eeman1113* · DEVLOG.md

I wanted one place that tells the whole story, so here it is: every commit since goodluckOS's very first one (122 of them), grouped by day, with my notes on the FakeR36S-OS days. From here on every push gets an entry.

- **Where things stand:** the build with the shutdown fixes (`7399902`) is running. When it's done, my card gets the system update and I can finally try the power menu and native Zelda.
- **Not tested on the device yet:** the power menu, the Ports system, the shutdown watchdog, and the theme art built into the system.

#### update · Updating without reflashing

*Eeman1113* · fr-update, S00update, fr-loading progress mode, CI update package, web installer, tools/update-os.sh, README

Reflashing every time and copying 11 GB of games back is not how I want to live, and it's definitely not how anyone else using this should have to. So now there's an update path that keeps everything.

- **How it works:** the web installer (or you, by hand) drops `fakers36s-update-a23_panel2.tar` into `HOME/update/`. On the next boot, before anything else starts, `fr-update` checks it's for this board, verifies every checksum, writes the kernel (and reads it back to be sure), installs the system files and refreshes only the HOME files the OS owns. Then it restarts.
- **What it never touches:** saves, save states, my RetroArch and per-core settings, button remaps, ES settings, gamelists, art, BIOS, ports. New defaults only get added where nothing exists, and new RetroArch settings are appended, never overwritten. It also knows not to bring back `autolaunch`, so the first-time setup doesn't run again.
- **If something goes wrong:** it refuses to start under 20% battery without a charger, and the package is only deleted after a complete install, so a power cut just means it carries on next boot. Everything goes to `update.log`.
- **The screen:** I didn't want a frozen logo for minutes, so the loading screen got a progress mode: my logo, "UPDATING FAKER36S-OS" with the percentage, a bar, and what it's doing right now ("Installing system files: 1830 of 4400"). It draws straight to the framebuffer with a tiny built-in font, so it works before anything else is running. I rendered a frame on my Mac to check it looks right.
- **Also:** `tools/update-os.sh` for Mac and Linux people who'd rather write the system straight to the card, with the same keep-HOME guarantee.
- **Not tested on the device yet:** the whole on-device update. The first real test is the next release, once this build is out.

#### tools-theme · Two "Ports" in the menu

*Eeman1113* · home/overlay/.emulationstation/es_systems.cfg

Booted the update and laughed: two Ports in the system list. The Tools system (Dashboard, Settings, Power Off...) was borrowing EPIC-CODY's Ports artwork, which was fine until real Ports showed up next to it. Tools now uses the theme's "Options / System Configuration" look, the same idea as ArkOS's options menu.

#### morning-fixes · Silent jingles and a slow first Zelda launch

*Eeman1113* · SDL2_mixer MP3, es_systems.cfg

First real morning with the update on the card. The system update itself went smoothly (90 seconds, games all still there) and shutdown now finishes cleanly: the new `shutdown.log` shows it going from "requested" to the last stop script in about 2 seconds. Two things were off though.

- **Some system jingles were silent.** ES's log was full of "Unrecognized audio format" for the theme's MP3s. Buildroot builds SDL2_mixer with MP3 switched off, and EPIC-CODY lists `.ogg` then `.mp3` while this ES takes the last match, so even systems with an OGG fell on the MP3. SDL2_mixer's own built-in MP3 decoder is now switched back on (no extra library), which also makes MP3 menu music in `roms/bgmusic` work like the README promises. On my card I converted the 26 MP3 jingles to OGG in the meantime.
- **Zelda sat on the loading screen.** Before extracting, the port searched my whole 11 GB games partition for an N64 ROM, which takes forever on this SD card. FakeR36S-Ocarina now looks in HOME and `roms/n64` first.

#### dashboard-launch · The dashboard that wouldn't stay open

*Eeman1113* · rootfs/package/dashboard, tools/System Dashboard.sh

Opened the System Dashboard from Options and it flashed the loading screen and dropped me straight back. It runs fine on my Mac, so it's something about the handheld. Best guess: the dashboard closes on B, Start or Select, and on this pad the physical A button can come through as SDL's "B", so the press that launched it could close it right away. Now it ignores buttons for the first 0.7 s and only quits on a press it saw start, and anything it prints goes to `.config/fakers36s/dashboard.log` so I can actually see what happened if it's something else.

#### office · A demo, real docs, and a release that names the right commit

*Eeman1113* · `765d75a`, `313b765`, `0b98d5e`

Did a bit from the office today.

- **The demo is in the README** (`765d75a`): a portrait poster frame of the handheld that links to the video, so people can see it boot before they flash anything.
- **BUILD.md and kernel/README.md are finally mine** (`313b765`). They still described goodluckOS's build; now they explain how FakeR36S-OS actually gets built.
- **The release names the right commit** (`0b98d5e`). The `latest` tag was created once and never moved, so the release page kept saying it came from the very first commit even though the files were fresh. CI now moves the tag to the commit that built the release and rewrites the notes, including a pointer to the update package for people who already run FakeR36S-OS.

Meanwhile on the handheld: native Zelda runs flawlessly, which honestly made my day. Still to fix there: quitting with Select+Start and the FPS toggle (both in the port's next build), save states surviving a power off, and the dashboard not opening.

#### app-log · Seeing why the Options apps bounce

*Eeman1113* · home/overlay/.local/launcher.sh

Every Options entry (Dashboard, Settings, Power Off, Puppy) flashes the loading screen and drops me back. They all start through appctl, which only keeps their output in RAM, so after a reboot there was nothing to look at. Now the launcher copies that output to `.config/fakers36s/last-app.log` every time EmulationStation comes back, so the next bounce leaves a trace I can read on my Mac.

Meanwhile, the good news: native Zelda keeps running great, and its new build can finally quit with Select+Start and show FPS with Select+B.

#### options-fix · The Options apps were never allowed to start

*Eeman1113* · home/overlay/tools/*.sh

Found it, and it was one word. ES's log had `appd: daemon is not running` every time I opened an Options entry, even though appd was obviously running (it's what started ES). Before sending a launch request, `appctl` checks the daemon with `kill -0`, and the daemon runs as root while the Options scripts run as me. A normal user isn't allowed to signal a root process, even just to ask if it exists, so appctl decided the daemon was dead and gave up. goodluckOS's own launcher runs `doas appctl`; my Tools scripts didn't. Now Dashboard, Settings, Puppy, Reboot and Power Off all go through `doas`, which `doas.conf` already allowed.

Also on the card today: the Zelda build with save states that live on the card and survive a power off. First time it's on real hardware.

#### zelda-states · Save states that survive turning it off

*Eeman1113* · [FakeR36S-Ocarina](https://github.com/Eeman1113/FakeR36S-Ocarina)

I saved a state in native Zelda, quit, shut the console down, turned it back on, pressed Select+L1, and I was standing exactly where I left. On a two core A23. I'm genuinely so happy about this one.

Ship of Harkinian's save states are a raw copy of game memory, which is full of pointers that change every launch, so they normally die with the process. To make them portable, the game's heaps now sit at fixed addresses, the binary is built non-PIE, and every block of memory an asset is built in gets recorded, so a pointer into Link's skeleton or a room's collision can be written as "asset, block, offset" and rebuilt after a restart. States go to the card in the background, the autosave every 30 seconds and when I quit with Select+Start, and the first Select+X after a restart resumes the last session.

It took three tries on the real thing: the first build hung on quit (a condition variable destroyed while a thread still slept on it), and the second refused every state because a failed "alt asset" lookup had been tagged as part of a real asset. My own logs found both. Also new today: the Options apps finally open (they needed `doas`), and seven new GBA RPGs on the card, including Pokemon Heart & Soul.

#### reader · A bookshelf in my pocket

*Eeman1113* · rootfs/package/koreader, fr-reader, fr-padwatch, tools/Reader.sh

I wanted my handheld to be a proper ebook reader too, so Options now has **Reader**, right under the Dashboard. It opens KOReader straight onto a grid of book covers from the `read` folder on the card, with my reading font (Bookerly) as the default, margins and spacing tuned for the 640x480 screen, and night mode one menu away.

The fun parts:
- KOReader ships an official 32-bit ARM Linux build, but its SDL3 only knows desktops (X11 and Wayland), so on my console it would draw nothing. The system SDL3 already talks to the screen directly (KMS/DRM), so the package swaps KOReader's copy for a link to it.
- KOReader already understands gamepads: D-pad, A to open, B back, L1/R1 to turn pages, Start for the menu. It just has no way to quit with buttons, so I wrote `fr-padwatch`, a tiny program that runs an app and closes it when Select+Start are held together (politely first, so the reading position is saved).
- The release tarball has no top folder, which would have quietly broken Buildroot's unpacking. Caught it before the build.
- Reading runs at the battery-saving CPU speed, and all settings and positions live on the card so updates never lose my place.

Not tested on the console yet: this build is the first one with it.


#### updater-fix · It said failed, but it had finished

*Eeman1113* · rootfs-overlay/usr/local/bin/fr-update

First real run of the on-card updater, and it told me "system files could not be written". I panicked a bit, then read my own log: kernel written, then the failure exactly two minutes later, which is about how long the whole system takes to unpack on this chip. So it hadn't stopped halfway. It had written every single file and then lied to me.

The culprit was the little loop that moves the progress bar. It updates the bar every 50 files, and the last line of that loop was a test for "is this a multiple of 50". With 6,355 files the answer at the end was no, the loop returned false, and the updater took that as tar failing. Every update with a file count not divisible by 50 would have done the same. Classic.

Now tar's own exit status is the only thing that decides, and whatever tar complains about goes into `update.log`, so next time I'll see the real error instead of guessing. On my card I finished the skipped last step by hand, and Reader is finally in Options.

#### reader-buttons · Reading with my thumbs

*Eeman1113* · fr-reader, koreader.mk, fr-settings.lua

Reader opened on the console for the first time today and it was beautiful, and then I pressed the D-pad and nothing happened. KOReader had seen my gamepad fine. The catch is that its desktop build thinks it's on a touchscreen, and touch lists have no highlighted item for a D-pad to move. One environment variable, `DISABLE_TOUCH=1`, flips it into the mode it uses on e-readers with real buttons, and suddenly the whole library is navigable.

The layout now:
- D-pad moves, A opens, B goes back (and closes a book), Start is the menu, Y is the options for a book
- reading: D-pad left/right and L1/R1 turn pages
- Select does nothing on its own anymore. It was mapped to page back AND page forward at the same time, which is a special kind of useless, and it's half of the Select+Start exit

Startup was the other pain: almost a minute and a half the first time, with a spinner that stopped after 20 seconds so it looked frozen. Now Reader starts at full CPU speed behind a spinner that keeps going until the library is actually up (KOReader opens the gamepad last, so I watch the log for that), then drops to the battery saver for reading. The online-only plugins (OPDS, news, Wallabag, sync...) are switched off once, through a small Lua merge that never touches anything I change inside KOReader.

#### reader-light · Putting KOReader on a diet

*Eeman1113* · koreader.mk, fr-reader, settings.reader.lua, fr-settings.lua

Reader worked, but every button press took about ten seconds and opening it took minutes. With 512 MB of RAM and two slow cores, that's not something you can live with, so I sent an agent to dig through KOReader's code and my logs, and it came back with actual answers instead of guesses.

The startup: on a fresh config KOReader runs about sixty one-time migrations, and two of them delete the font cache right after it was built. So the 30 second font scan ran twice and was never saved. A fresh config has nothing to migrate, so now it starts already marked as up to date. The build also checks the migration date, so a future KOReader update can't quietly break this.

The lag: the first time a book opens, crengine registers every font it has, and 16 MB of that was one Chinese font, plus Arabic, Indic and two FreeFonts. That's gone now: fonts went from 24.7 MB to 4.6 MB, keeping Noto Sans/Serif, the icon font and my Bookerly. Twenty-eight plugins are removed from the build entirely (network ones, touch and e-ink ones, and the statistics and vocabulary databases that wrote to the card on every page). It also runs flat out now: a new `cpuprofile max` turns on the 1.2 GHz turbo and pins the clock at the top for the whole Reader session (by raising the minimum clock, so it works with whatever governor the kernel has), and everything goes back to my own Performance mode setting when Reader closes, and crengine's RAM cache is capped at 5x instead of 40x, which on this console could have meant up to 500 MB.

Not all of it is explained yet: there are still about 22 seconds before KOReader even opens the screen. So the launcher now writes a small trace every 2 seconds while starting (process state, CPU time, clock speed, free memory) and the time until the library appears. The next log will tell me what those seconds are.
