#!/bin/sh
# Launched through appd (goodluckOS supervisor): EmulationStation is closed while the
# app runs and restarted fresh afterwards, so it never loses the gamepad.
# its output goes to HOME, so a problem can be read from a computer
exec doas /usr/local/bin/appctl launch-application "sh -c '/usr/bin/dashboard >> /home/player/.config/fakers36s/dashboard.log 2>&1'"
