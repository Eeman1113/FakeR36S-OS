################################################################################
#
# es-theme-carbon (RetroPie) for EmulationStation, pin from Debianator
#
################################################################################

ES_THEME_CARBON_VERSION = b09973e0b0c589cb11fe772c169a6ff5d588b390
ES_THEME_CARBON_SITE = $(call github,RetroPie,es-theme-carbon,$(ES_THEME_CARBON_VERSION))
ES_THEME_CARBON_LICENSE = CC-BY-NC-SA-2.0

define ES_THEME_CARBON_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc/emulationstation/themes/carbon
	cp -r $(@D)/. $(TARGET_DIR)/etc/emulationstation/themes/carbon/
	rm -rf $(TARGET_DIR)/etc/emulationstation/themes/carbon/.git*
endef

$(eval $(generic-package))
