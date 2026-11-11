#!/bin/bash
# Progress of a Colab rootfs build started by colab-build.sh
L=/content/br.log
echo "packages done: $(grep -c 'Installing to target' $L)"
grep '>>> ' $L | tail -2
grep -E 'BUILD EXIT CODE|\*\*\* \[|Error [0-9]+$|CMake Error|error:' $L | grep -v '(ignored)' | tail -6
ls -la /src/out/images 2>/dev/null
