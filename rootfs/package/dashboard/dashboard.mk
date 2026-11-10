################################################################################
#
# dashboard (FakeR36S-OS live system stats + graphs)
#
################################################################################

DASHBOARD_SITE = $(DASHBOARD_PKGDIR)
DASHBOARD_SITE_METHOD = local
DASHBOARD_LICENSE = GPL-2.0
DASHBOARD_DEPENDENCIES = sdl2 imgui

define DASHBOARD_BUILD_CMDS
	$(TARGET_CXX) $(TARGET_CXXFLAGS) -std=c++11 -O2 \
		-I$(STAGING_DIR)/usr/include/SDL2 \
		-o $(@D)/dashboard $(@D)/dashboard.cpp \
		$(TARGET_LDFLAGS) -lSDL2 -limgui
endef

define DASHBOARD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/dashboard $(TARGET_DIR)/usr/bin/dashboard
endef

$(eval $(generic-package))
