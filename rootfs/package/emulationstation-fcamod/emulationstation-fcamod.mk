################################################################################
#
# emulationstation-fcamod: the EmulationStation fork used by ArkOS
# Pin + the five patches in this directory come from Debianator (GPL-2.0),
# which runs this exact build on the same Mali-400 / Lima GPU.
#
################################################################################

EMULATIONSTATION_FCAMOD_VERSION = 74498be31cd016af6a42d00310f876d7256eff52
EMULATIONSTATION_FCAMOD_SITE = https://github.com/christianhaitian/EmulationStation-fcamod.git
EMULATIONSTATION_FCAMOD_SITE_METHOD = git
EMULATIONSTATION_FCAMOD_GIT_SUBMODULES = YES
EMULATIONSTATION_FCAMOD_LICENSE = MIT
EMULATIONSTATION_FCAMOD_LICENSE_FILES = LICENSE.md
EMULATIONSTATION_FCAMOD_DEPENDENCIES = sdl2 sdl2_mixer freetype freeimage libcurl vlc rapidjson alsa-lib mesa3d libdrm

EMULATIONSTATION_FCAMOD_CONF_OPTS = -DGLES=ON -DCMAKE_BUILD_TYPE=Release

# ES writes its binary into the source tree and loads resources/ from beside it.
EMULATIONSTATION_FCAMOD_INSTALL_DIR = /usr/lib/emulationstation
define EMULATIONSTATION_FCAMOD_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)$(EMULATIONSTATION_FCAMOD_INSTALL_DIR)
	$(INSTALL) -m 0755 $(@D)/emulationstation $(TARGET_DIR)$(EMULATIONSTATION_FCAMOD_INSTALL_DIR)/emulationstation
	cp -r $(@D)/resources $(TARGET_DIR)$(EMULATIONSTATION_FCAMOD_INSTALL_DIR)/
	$(INSTALL) -m 0644 $(EMULATIONSTATION_FCAMOD_PKGDIR)/splash.svg $(TARGET_DIR)$(EMULATIONSTATION_FCAMOD_INSTALL_DIR)/resources/splash.svg
	ln -sf $(EMULATIONSTATION_FCAMOD_INSTALL_DIR)/emulationstation $(TARGET_DIR)/usr/bin/emulationstation
endef

$(eval $(cmake-package))
