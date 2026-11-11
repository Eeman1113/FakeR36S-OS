#!/bin/sh
# Hold-power menu. Wakes the screen if it was off, closes a running game cleanly
# (SIGTERM: RetroArch writes the game's save file on the way out), then shows the
# menu through appd so it owns the screen. Cancel brings EmulationStation back.
LOCK=/run/power-menu.lock
[ -e "$LOCK" ] && exit 0
: > "$LOCK"; trap 'rm -f "$LOCK"' EXIT
APPCTL=/usr/local/bin/appctl

[ "$(cat /sys/class/backlight/backlight/brightness)" = 0 ] && /usr/local/bin/toggle-screen.sh

if $APPCTL status | grep -q "application cgroup: populated"; then
    $APPCTL stop-application
    i=0
    while $APPCTL status | grep -q "application cgroup: populated" && [ "$i" -lt 50 ]; do
        sleep 0.1 2>/dev/null || sleep 1
        i=$((i + 1))
    done
fi
$APPCTL launch-application "/usr/bin/power-menu"
