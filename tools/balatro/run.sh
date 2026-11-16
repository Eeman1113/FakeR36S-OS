#!/bin/sh
# Balatro on FakeR36S-OS: LOVE 11.5 (OpenGL ES 2) with PortMaster's handheld patches applied by
# tools/balatro-port.sh on a computer. Select+Start quits. Saves stay in this folder.
D=$(cd "$(dirname "$0")" && pwd)
G=$D/Balatro_pm
[ -f "$G" ] || G=$D/Balatro.love                 # unpatched game still runs, just heavier
[ -f "$G" ] || { echo "Balatro: no game file in $D (run tools/balatro-port.sh)"; exit 1; }
LOG=/home/player/.config/fakers36s/balatro.log
mkdir -p "$D/saves" "${LOG%/*}"
[ "$(wc -c < "$LOG" 2>/dev/null || echo 0)" -gt 300000 ] && : > "$LOG"

export HOME=/home/player XDG_DATA_HOME=$D/saves XDG_CONFIG_HOME=$D/saves
export SDL_VIDEODRIVER=kmsdrm LOVE_GRAPHICS_USE_OPENGLES=1
. /etc/profile.d/sdl_controller.sh 2>/dev/null
# PortMaster patch settings: performance mode on, 30 fps to start (Settings > Video changes it)
export BALATRO_PM_PERF_OPTIMIZATIONS=1
export BALATRO_PM_FPS_CAP=${BALATRO_PM_FPS_CAP:-30}
export BALATRO_PM_SETUP_FILE=$D/saves/display-setup.txt
export BALATRO_PM_BUTTON_MAP_FILE=$D/saves/controller-map.txt

echo "=== balatro start $(date) $(basename "$G")" >> "$LOG"
doas /usr/local/bin/cpuprofile max 2>/dev/null
/usr/bin/fr-padwatch love "$G" >> "$LOG" 2>&1
rc=$?
doas /usr/local/bin/cpuprofile normal 2>/dev/null
echo "=== balatro exit $rc" >> "$LOG"
exit $rc
