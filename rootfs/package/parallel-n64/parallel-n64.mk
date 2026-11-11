################################################################################
#
# parallel-n64 (libretro N64 core, tuned for Cortex-A7 + Mali-400 / Lima)
#
# Build recipe, pin and patch from Debianator (GPL-2.0, github.com/Bepok/Debianator):
# platform=classic_armv7_a7 = Cortex-A7 NEON hard-float, GLES2, ARM dynarec.
#
################################################################################

PARALLEL_N64_VERSION = 6f233392445dcef4188a321d4ba65a776f0e1672
PARALLEL_N64_SITE = https://github.com/libretro/parallel-n64.git
PARALLEL_N64_SITE_METHOD = git
PARALLEL_N64_LICENSE = GPL-2.0
PARALLEL_N64_LICENSE_FILES = COPYING
PARALLEL_N64_DEPENDENCIES = mesa3d zlib

# GCC 15 defaults C to gnu23 (bool keyword etc.); this core is older C
define PARALLEL_N64_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) platform=classic_armv7_a7 \
		CC="$(TARGET_CC) -std=gnu17" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)"
endef

define PARALLEL_N64_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/parallel_n64_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/parallel_n64_libretro.so
endef

$(eval $(generic-package))
