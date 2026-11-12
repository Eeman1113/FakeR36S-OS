#!/bin/sh
# FakeR36S-OS launcher: boot straight into EmulationStation (the ArkOS frontend).
# - logs ES output to ~/.config/fakers36s/es.log (readable from a computer)
# - if ES dies within 15 s twice in a row this boot, falls back to Puppy so the
#   console is never stuck on the loading screen
. /etc/profile 2>/dev/null
export HOME=/home/player
cd "$HOME"
export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
LOGDIR=$HOME/.config/fakers36s
FAILS=/dev/shm/fakers36s-es-fails
mkdir -p "$LOGDIR"
# what the last app launched through appctl (Options entries, ports from Puppy) printed: appd keeps it in RAM only
for f in /dev/shm/application/application.log /dev/shm/application/application.log.old; do
    [ -s "$f" ] && { echo "=== $(date) $f"; cat "$f"; } >> "$LOGDIR/last-app.log"
done

/usr/local/bin/fr-ports-sync 2>/dev/null   # list installed ports in ES
fails=$(cat "$FAILS" 2>/dev/null || echo 0)
if [ -x /usr/bin/emulationstation ] && [ "$fails" -lt 2 ]; then
    rm -f /tmp/es-shutdown /tmp/es-sysrestart
    start=$(cut -d. -f1 /proc/uptime)
    echo "=== $(date) ES start (fails so far: $fails)" >> "$LOGDIR/es.log"
    /usr/bin/emulationstation >> "$LOGDIR/es.log" 2>&1
    rc=$?
    # ES's Quit menu leaves a marker and then calls "sudo shutdown", which doesn't exist here:
    # do the real power off / restart, and stay alive so appd doesn't start ES again meanwhile
    for m in shutdown sysrestart; do
        [ -e /tmp/es-$m ] || continue
        echo "=== ES asked for $m" >> "$LOGDIR/es.log"
        arg=; [ $m = sysrestart ] && arg=reboot
        if [ -x /usr/local/bin/fr-poweroff ]; then
            doas /usr/local/bin/fr-poweroff $arg
        elif [ -n "$arg" ]; then
            doas /sbin/reboot
        else
            doas /sbin/poweroff
        fi
        exec sleep 120
    done
    end=$(cut -d. -f1 /proc/uptime)
    echo "=== ES exited rc=$rc after $((end - start)) s" >> "$LOGDIR/es.log"
    if [ $((end - start)) -lt 15 ]; then echo $((fails + 1)) > "$FAILS"; else echo 0 > "$FAILS"; fi
    exit $rc
fi
echo "=== $(date) falling back to Puppy" >> "$LOGDIR/es.log"
exec /usr/bin/puppy
