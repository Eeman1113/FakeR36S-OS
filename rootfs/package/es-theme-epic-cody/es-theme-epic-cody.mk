################################################################################
#
# es-theme-epic-cody: EPIC-CODY by CodyV59 (a fork of EpicNoir by Chicuelo and
# Nick L / c64-dev), RG351V 640x480 edition. Licensed CC BY-NC-SA 4.0: shipped
# unmodified, fetched from upstream, for non-commercial use with attribution.
#
################################################################################

ES_THEME_EPIC_CODY_VERSION = b810e33851f2df0f86e9e2570cddab3a40961f8f
ES_THEME_EPIC_CODY_SITE = $(call github,CodyV59,es-theme-epic-cody-RG351V,$(ES_THEME_EPIC_CODY_VERSION))
ES_THEME_EPIC_CODY_LICENSE = CC-BY-NC-SA-4.0
ES_THEME_EPIC_CODY_LICENSE_FILES = README.md

define ES_THEME_EPIC_CODY_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc/emulationstation/themes/epic-cody
	cp -r $(@D)/. $(TARGET_DIR)/etc/emulationstation/themes/epic-cody/
	rm -rf $(TARGET_DIR)/etc/emulationstation/themes/epic-cody/.git* \
		$(TARGET_DIR)/etc/emulationstation/themes/epic-cody/_art
endef

$(eval $(generic-package))
