################################################################################
#
# bootsplash (FakeR36S-OS animated boot splash + chime)
#
################################################################################

BOOTSPLASH_SITE = $(BOOTSPLASH_PKGDIR)
BOOTSPLASH_SITE_METHOD = local
BOOTSPLASH_LICENSE = GPL-2.0
BOOTSPLASH_DEPENDENCIES = sdl2 imgui

define BOOTSPLASH_BUILD_CMDS
	$(TARGET_CXX) $(TARGET_CXXFLAGS) -std=c++11 -O2 \
		-I$(STAGING_DIR)/usr/include/SDL2 \
		-o $(@D)/bootsplash $(@D)/bootsplash.cpp \
		$(TARGET_LDFLAGS) -lSDL2 -limgui
endef

define BOOTSPLASH_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bootsplash $(TARGET_DIR)/usr/bin/bootsplash
endef

$(eval $(generic-package))
