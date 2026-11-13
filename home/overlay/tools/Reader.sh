#!/bin/sh
# Launched through appd (goodluckOS supervisor): EmulationStation is closed while the
# app runs and restarted fresh afterwards, so it never loses the gamepad.
exec doas /usr/local/bin/appctl launch-application "/usr/local/bin/fr-reader"
