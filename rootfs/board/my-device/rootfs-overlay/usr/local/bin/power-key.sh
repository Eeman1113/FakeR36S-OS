#!/bin/sh
# Power button (run by triggerhappy as root):
#   tap            -> screen off / on (toggle-screen.sh), as before
#   hold 1.5 s     -> power menu (power-menu.sh), opens while the button is still held
STAMP=/run/powerkey
case "$1" in
down)
    t=$(cut -d' ' -f1 /proc/uptime)
    echo "$t" > "$STAMP"
    (
        sleep 1.5 2>/dev/null || sleep 2
        [ "$(cat "$STAMP" 2>/dev/null)" = "$t" ] || exit 0
        echo menu > "$STAMP"
        exec /usr/local/bin/power-menu.sh
    ) </dev/null >/dev/null 2>&1 &
    ;;
up)
    s=$(cat "$STAMP" 2>/dev/null)
    rm -f "$STAMP"
    [ "$s" = menu ] && exit 0
    [ -n "$s" ] && exec /usr/local/bin/toggle-screen.sh
    ;;
esac
exit 0
