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
	# --- light build for a 512 MB, 2-core handheld ------------------------------------------
	# fonts: every one is scanned at first start and registered with crengine at every first book
	# open (and in every cover-extraction child). CJK/Arabic/Indic/FreeFont = 20 MB of 24.7 MB.
	cd $(TARGET_DIR)/opt/koreader/fonts && rm -rf freefont freefont-build-tweaks.patch \
		noto/NotoSansCJKsc-Regular.otf noto/NotoNaskhArabic-*.ttf noto/NotoSansArabicUI-*.ttf \
		noto/NotoSansBengaliUI-*.ttf noto/NotoSansDevanagariUI-*.ttf
	sed -i -e '/^    fallbacks = {/,/^    },/{ /NotoSansCJKsc\|NotoSansArabicUI\|NotoSansDevanagariUI\|NotoSansBengaliUI\|freefont/d; s/^        \[6\] = "nerdfonts\/symbols.ttf",$$/        [2] = "nerdfonts\/symbols.ttf",/; }' \
		$(TARGET_DIR)/opt/koreader/frontend/ui/font.lua
	grep -q '\[2\] = "nerdfonts/symbols.ttf"' $(TARGET_DIR)/opt/koreader/frontend/ui/font.lua
	! grep -q 'NotoSansCJKsc-Regular.otf",' $(TARGET_DIR)/opt/koreader/frontend/ui/font.lua
	# plugins: network-only, touch/e-ink-only, or sqlite-on-every-page ones. hotkeys too: its default
	# gamepad map (Select = page back, L1/R1 = right page keys) overrides gamepad.lua and swallows
	# Select, so the fakers36s plugin's Select+L1/R1 bookmark combos never fire
	cd $(TARGET_DIR)/opt/koreader/plugins && rm -rf exporter.koplugin newsdownloader.koplugin \
		opds.koplugin wallabag.koplugin calibre.koplugin cloudstorage.koplugin kosync.koplugin \
		httpinspector.koplugin qrclipboard.koplugin terminal.koplugin hello.koplugin \
		externalkeyboard.koplugin autowarmth.koplugin japanese.koplugin vocabbuilder.koplugin \
		statistics.koplugin systemstat.koplugin perceptionexpander.koplugin movetoarchive.koplugin \
		coverimage.koplugin autodim.koplugin autoturn.koplugin autosuspend.koplugin \
		autostandby.koplugin keepalive.koplugin batterystat.koplugin texteditor.koplugin \
		archiveviewer.koplugin hotkeys.koplugin
	test -d $(TARGET_DIR)/opt/koreader/plugins/coverbrowser.koplugin
	# settings.reader.lua pre-sets last_migration_date to this KOReader's value, so a fresh config
	# skips ~60 one-time migrations (two of which delete the font cache right after it is built).
	# Bump both together when updating KOReader.
	grep -q 'CURRENT_MIGRATION_DATE = 20260623' $(TARGET_DIR)/opt/koreader/frontend/ui/data/onetime_migration.lua
endef

$(eval $(generic-package))
