#!/bin/sh
# Launched through appd (goodluckOS supervisor): EmulationStation is closed while the
# app runs and restarted fresh afterwards, so it never loses the gamepad.
# fr-poweroff stops appd first and forces the power off if a stop script hangs.
if [ -x /usr/local/bin/fr-poweroff ]; then cmd="doas /usr/local/bin/fr-poweroff reboot"; else cmd="doas /sbin/reboot"; fi
exec doas /usr/local/bin/appctl launch-application "are-you-sure \"Reboot the device?\" \"$cmd\""
