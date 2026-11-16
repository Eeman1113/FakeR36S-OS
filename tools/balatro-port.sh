#!/bin/bash
# balatro-port.sh: put YOUR copy of Balatro on a FakeR36S-OS card as a port.
#   tools/balatro-port.sh <Balatro.app | Balatro.love | Balatro.exe> /Volumes/HOME
# It applies PortMaster's handheld patches (small-screen layout, performance, controls; MIT,
# github.com/PortsMaster/PortMaster-New, ports/balatro) with their own patchscript, pinned to
# one commit, and installs ports/balatro plus a Ports entry. Your game files are only copied
# to the card; nothing is uploaded. Needs bash, python3, curl and GNU sed (macOS: brew install gnu-sed).
set -euo pipefail
PM_COMMIT=1d30f2cd7c162fb8950fc190793a046306715ffd
PM_RAW=https://raw.githubusercontent.com/PortsMaster/PortMaster-New/$PM_COMMIT/ports/balatro/balatro
SRC=${1:?usage: balatro-port.sh <Balatro.app|.love|.exe> <HOME mount>}
HOMEDIR=${2:?usage: balatro-port.sh <Balatro.app|.love|.exe> <HOME mount>}
HERE=$(cd "$(dirname "$0")" && pwd)
[ -f "$HOMEDIR/.romdirs" ] || { echo "$HOMEDIR doesn't look like a FakeR36S-OS HOME partition" >&2; exit 1; }

# GNU sed (the patchscript uses sed -i without a suffix)
for s in sed gsed /opt/homebrew/opt/gnu-sed/libexec/gnubin/sed /usr/local/opt/gnu-sed/libexec/gnubin/sed; do
    if "$s" --version 2>/dev/null | grep -q GNU; then GNUSED=$s; break; fi
done
[ -n "${GNUSED:-}" ] || { echo "GNU sed is needed (macOS: brew install gnu-sed)" >&2; exit 1; }

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
G=$WORK/gamedir; mkdir -p "$G/patches" "$G/resources/fonts" "$G/bin" "$G/tools" "$WORK/sedbin"
ln -s "$(command -v "$GNUSED")" "$WORK/sedbin/sed"

case "$SRC" in
    *.app|*.app/) cp "$SRC/Contents/Resources/Balatro.love" "$G/Balatro.love"; GAMEFILE=Balatro.love ;;
    *.love) cp "$SRC" "$G/Balatro.love"; GAMEFILE=Balatro.love ;;
    *.exe) cp "$SRC" "$G/Balatro.exe"; GAMEFILE=Balatro.exe ;;
    *) echo "give Balatro.app, Balatro.love or Balatro.exe" >&2; exit 1 ;;
esac

echo "Fetching PortMaster's Balatro patches (commit ${PM_COMMIT:0:7})..."
for f in achievements controls cpu_opt loc_fix options particle_cleanup perf rumble small_screen text_cleanup; do
    curl -fsSL -o "$G/patches/$f.lua" "$PM_RAW/patches/$f.lua"
done
curl -fsSL -o "$G/tools/patchscript" "$PM_RAW/tools/patchscript"
curl -fsSL -o "$G/resources/fonts/Nunito-Black.ttf" "$PM_RAW/resources/fonts/Nunito-Black.ttf"
curl -fsSL -o "$WORK/LICENSE.Nunito_OFL.txt" "$PM_RAW/licenses/LICENSE.Nunito_OFL.txt"

# the patchscript drives 7za; this stand-in does the same x/u/t/l on the game's zip
cat > "$G/bin/7za.host" <<'PY'
#!/usr/bin/env python3
import sys, zipfile, os, shutil, tempfile
a = [x for x in sys.argv[1:] if x != '-aoa']
cmd, so = a[0], '-so' in a
a = [x for x in a[1:] if x != '-so']
arc, files = a[0], a[1:]
if cmd == 'x':
    z = zipfile.ZipFile(arc)
    for f in files:
        data = z.read(f)
        if so: sys.stdout.buffer.write(data); continue
        os.makedirs(os.path.dirname(f) or '.', exist_ok=True)
        open(f, 'wb').write(data)
elif cmd == 'u':
    z = zipfile.ZipFile(arc); names = set(files)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(os.path.abspath(arc))); os.close(fd)
    with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as out:
        for i in z.infolist():
            if i.filename in names or i.filename.startswith('__MACOSX/'): continue
            out.writestr(i, z.read(i.filename))
        for f in files: out.write(f, f)
    z.close(); shutil.move(tmp, arc)
elif cmd == 't':
    sys.exit(1 if zipfile.ZipFile(arc).testzip() else 0)
elif cmd == 'l':
    print("\n".join(zipfile.ZipFile(arc).namelist()))
else:
    sys.exit(2)
PY
chmod +x "$G/bin/7za.host"

echo "Patching (your original file is not changed)..."
( cd "$G" && PATH="$WORK/sedbin:$PATH" GAMEDIR="$G" GAMEFILE="$GAMEFILE" OUTPUT_GAME=Balatro_pm \
    BUILD_STAMP="$G/.balatro-build.txt" LAYOUT=small PERFORMANCE=on FONT=nunito \
    PERF_OPTIMIZATIONS=1 DEVICE_ARCH=host bash tools/patchscript )

D=$HOMEDIR/ports/balatro
mkdir -p "$D/saves" "$D/licenses" "$HOMEDIR/.local/share/applications" "$HOMEDIR/.local/share/icons"
cp "$G/Balatro_pm" "$D/Balatro_pm"
cp "$HERE/balatro/run.sh" "$D/run.sh"; chmod +x "$D/run.sh"
cp "$WORK/LICENSE.Nunito_OFL.txt" "$D/licenses/"
cat > "$D/licenses/README.txt" <<TXT
Balatro (c) LocalThunk / Playstack: your own copy, patched on your computer.
Handheld patches and patchscript: PortMaster (MIT), github.com/PortsMaster/PortMaster-New,
ports/balatro at commit $PM_COMMIT. Nunito font: SIL Open Font License (LICENSE.Nunito_OFL.txt).
TXT
if [ -f "${SRC%/}/Contents/Resources/GameIcon.icns" ] && command -v sips >/dev/null; then
    sips -s format png -Z 256 "${SRC%/}/Contents/Resources/GameIcon.icns" --out "$HOMEDIR/.local/share/icons/balatro.png" >/dev/null
fi
cat > "$HOMEDIR/.local/share/applications/balatro.puppy" <<PUP
NAME=Balatro
CATEGORY=Ports
COMMAND=/home/player/ports/balatro/run.sh
DESCRIPTION=The poker roguelike. Needs FakeR36S-OS with LOVE 11.5. Select+Start quits.
ICON=/home/player/.local/share/icons/balatro.png
PUP
echo "Done: Balatro is in Ports on the card (needs an OS with LOVE 11.5)."
