################################################################################
#
# koreader: the official armhf Linux release, installed in /opt/koreader.
# Its bundled SDL3 is built for desktops (X11/Wayland, no KMS/DRM), so it is replaced
# by a link to the system SDL3, which draws straight to the screen. SDL keeps the ABI
# within a major version. The CoverBrowser plugin's first-start view becomes the cover
# grid (mosaic) instead of the detailed list.
#
################################################################################

KOREADER_VERSION = v2026.07.1
KOREADER_SOURCE = koreader-linux-armhf-$(KOREADER_VERSION).tar.xz
KOREADER_SITE = https://github.com/koreader/koreader/releases/download/$(KOREADER_VERSION)
KOREADER_LICENSE = AGPL-3.0
# the release tarball has no top-level folder (bin/, lib/, share/ at its root)
KOREADER_STRIP_COMPONENTS = 0
KOREADER_DEPENDENCIES = sdl3

define KOREADER_INSTALL_TARGET_CMDS
	rm -rf $(TARGET_DIR)/opt/koreader
	mkdir -p $(TARGET_DIR)/opt
	cp -a $(@D)/lib/koreader $(TARGET_DIR)/opt/koreader
	rm -f $(TARGET_DIR)/opt/koreader/libs/libSDL3.so.0
	ln -s /usr/lib/libSDL3.so.0 $(TARGET_DIR)/opt/koreader/libs/libSDL3.so.0
	sed -i 's/saveSetting("filemanager_display_mode", "list_image_meta")/saveSetting("filemanager_display_mode", "mosaic_image")/' \
		$(TARGET_DIR)/opt/koreader/plugins/coverbrowser.koplugin/main.lua
	grep -q 'saveSetting("filemanager_display_mode", "mosaic_image")' \
		$(TARGET_DIR)/opt/koreader/plugins/coverbrowser.koplugin/main.lua
	# gamepad: Select does nothing in KOReader (it is half of the Select+Start exit, and it was
	# mapped to both page back and page forward); L1/R1 are the page turn keys of button mode
	sed -i -e '/button_key_names = {/,/^    },/{ /^        \[4\] = "RPgBack",$$/d; /^        \[5\] = "RPgFwd",$$/d; s/^        \[9\] = "RPgBack",$$/        [9] = "LPgBack",/; s/^        \[10\] = "RPgFwd",$$/        [10] = "LPgFwd",/; }' \
		$(TARGET_DIR)/opt/koreader/frontend/device/sdl/gamepad.lua
	grep -q '\[9\] = "LPgBack"' $(TARGET_DIR)/opt/koreader/frontend/device/sdl/gamepad.lua
	! grep -q '\[4\] = "RPgBack"' $(TARGET_DIR)/opt/koreader/frontend/device/sdl/gamepad.lua
endef

$(eval $(generic-package))
