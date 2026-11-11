#!/bin/sh
# Launched through appd (goodluckOS supervisor): EmulationStation is closed while the
# app runs and restarted fresh afterwards, so it never loses the gamepad.
exec /usr/local/bin/appctl launch-application "are-you-sure \"Power off the device?\" \"doas /sbin/poweroff\""
