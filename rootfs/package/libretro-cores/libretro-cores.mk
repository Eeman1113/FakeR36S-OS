################################################################################
#
# libretro-cores
#
################################################################################

# Buildroot 2026 can't resolve a branch name as a git version: pin libretro-super's current commit.
# (The cores themselves are still fetched at their latest master by libretro-fetch.sh.)
LIBRETRO_CORES_VERSION = f7786ec5db34c5dcba15b96712e7211021ed4b7b
LIBRETRO_CORES_SITE = https://github.com/libretro/libretro-super.git
LIBRETRO_CORES_SITE_METHOD = git
LIBRETRO_CORES_LICENSE = Various (GPL-2.0+, MIT, Non-Commercial)
LIBRETRO_CORES_LICENSE_FILES = COPYING

LIBRETRO_CORES_DEPENDENCIES = zlib host-cmake

LIBRETRO_MAJOR_CORES_LIST = \
	fceumm \
	nestopia \
	snes9x2005 \
	snes9x2010 \
	genesis_plus_gx \
	picodrive \
	quicknes \
	dosbox \
	pcsx_rearmed \
	gambatte \
	gpsp \
	mednafen_pce_fast \
	mednafen_supergrafx \
	fbneo \
	mame2003_plus \
	stella2014 \
	prosystem \
	handy \
	mednafen_ngp \
	mednafen_wswan \
	mednafen_vb \
	pokemini \
	vecx \
	o2em \
	fuse \
	bluemsx \
	gw \
	freeintv \
	cap32

CMAKE_LIBRETRO_CORES_LIST = \
	mgba

# core:makefile, rebuilt for the Cortex-A7 after the generic pass
ARM_A7_LIBRETRO_CORES = gpsp:Makefile picodrive:Makefile.libretro vecx:Makefile.libretro



define LIBRETRO_CORES_RUN_FETCH
	cd $(@D) && ./libretro-fetch.sh $(LIBRETRO_MAJOR_CORES_LIST)
	cd $(@D) && ./libretro-fetch.sh $(CMAKE_LIBRETRO_CORES_LIST)
endef
LIBRETRO_CORES_POST_EXTRACT_HOOKS += LIBRETRO_CORES_RUN_FETCH

# CC gets -std=gnu17: GCC 15 defaults C to gnu23, which breaks many older cores
define LIBRETRO_CORES_BUILD_CMDS
	cd $(@D) && \
		CC="$(TARGET_CC) -std=gnu17" \
		CXX="$(TARGET_CXX)" \
		AR="$(TARGET_AR)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		CXXFLAGS="$(TARGET_CXXFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		MAKE="$(MAKE)" \
		./libretro-build.sh $(LIBRETRO_MAJOR_CORES_LIST)

	rm -rf $(@D)/libretro-mgba/build
	mkdir -p $(@D)/libretro-mgba/build
	cd $(@D)/libretro-mgba/build && \
		$(HOST_DIR)/bin/cmake .. \
			-DCMAKE_TOOLCHAIN_FILE=$(HOST_DIR)/share/buildroot/toolchainfile.cmake \
			-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
			-DCMAKE_BUILD_TYPE=Release \
			-DBUILD_LIBRETRO=ON \
			-DBUILD_SDL=OFF \
			-DBUILD_QT=OFF \
			-DUSE_FFMPEG=OFF \
			-DUSE_SQLITE3=OFF \
			-DUSE_MINIZIP=OFF \
			-DUSE_EDITLINE=OFF \
			-DUSE_DISCORD_RPC=OFF
	$(MAKE) -C $(@D)/libretro-mgba/build mgba_libretro

	mkdir -p $(@D)/dist/unix
	cp $(@D)/libretro-mgba/build/mgba_libretro.so $(@D)/dist/unix/mgba_libretro.so

	# platform=unix makes these Makefiles detect the BUILD host (x86) and emit x86 code.
	# classic_armv7_a7 = Cortex-A7 NEON hard-float (SNES Classic), same CPU as the A23.
	# Best effort: a failure here must not break the OS build.
	$(foreach c,$(ARM_A7_LIBRETRO_CORES),\
		( $(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/libretro-$(word 1,$(subst :, ,$(c))) \
			-f $(word 2,$(subst :, ,$(c))) platform=classic_armv7_a7 \
			CC="$(TARGET_CC) -std=gnu17" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)" \
		&& cp $(@D)/libretro-$(word 1,$(subst :, ,$(c)))/$(word 1,$(subst :, ,$(c)))_libretro.so $(@D)/dist/unix/ ) \
		|| echo "FakeR36S-OS: core $(c) did not build";$(sep))
endef

define LIBRETRO_CORES_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/lib/libretro
	find $(@D)/dist/unix -name "*_libretro.so" -exec \
		$(INSTALL) -D -m 0755 {} $(TARGET_DIR)/usr/lib/libretro/ \;
endef

$(eval $(generic-package))
