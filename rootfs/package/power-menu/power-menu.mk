################################################################################
#
# power-menu: the hold-power-button menu (shut down, restart, cancel)
#
################################################################################

POWER_MENU_SITE = $(POWER_MENU_PKGDIR)
POWER_MENU_SITE_METHOD = local
POWER_MENU_DEPENDENCIES = sdl2 imgui

define POWER_MENU_BUILD_CMDS
	$(TARGET_CXX) $(TARGET_CXXFLAGS) -std=c++11 \
		-I$(@D)/imgui \
		-I$(@D)/imgui/backends \
		-I$(STAGING_DIR)/usr/include/SDL2 \
		-o $(@D)/power-menu $(@D)/power-menu.cpp \
		$(TARGET_LDFLAGS) \
		-lpthread -ldrm -lSDL2 -lGLESv2 -lEGL -lasound -limgui
endef

define POWER_MENU_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/power-menu $(TARGET_DIR)/usr/bin/power-menu
endef

$(eval $(generic-package))
