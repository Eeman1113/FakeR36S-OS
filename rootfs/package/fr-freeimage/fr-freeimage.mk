################################################################################
#
# fr-freeimage: FreeImage for EmulationStation (recipe and patches from Batocera, github.com/batocera-linux/batocera.linux)
#
################################################################################

FR_FREEIMAGE_VERSION = 3.18.0
FR_FREEIMAGE_SITE = http://downloads.sourceforge.net/freeimage
FR_FREEIMAGE_SOURCE = FreeImage$(subst .,,$(FR_FREEIMAGE_VERSION)).zip
FR_FREEIMAGE_LICENSE = GPL-2.0 or GPL-3.0 or FreeImage Public License
FR_FREEIMAGE_LICENSE_FILES = license-gplv2.txt license-gplv3.txt license-fi.txt
FR_FREEIMAGE_CPE_ID_VENDOR = freeimage_project
FR_FREEIMAGE_CPE_ID_PRODUCT = freeimage
FR_FREEIMAGE_INSTALL_STAGING = YES

define FR_FREEIMAGE_EXTRACT_CMDS
	$(UNZIP) $(FR_FREEIMAGE_DL_DIR)/$(FR_FREEIMAGE_SOURCE) -d $(@D)
	mv $(@D)/FreeImage/* $(@D)
	rmdir $(@D)/FreeImage
endef

FR_FREEIMAGE_CFLAGS = $(TARGET_CFLAGS) -std=gnu17 -Wno-implicit-function-declaration \
	-Wno-error=incompatible-pointer-types -Wno-error=int-conversion
FR_FREEIMAGE_CXXFLAGS = $(TARGET_CXXFLAGS) -fpermissive

ifneq ($(filter y,$(BR2_ARM_CPU_HAS_NEON) $(BR2_ARM_FPU_FP_ARMV8) $(BR2_ARM_CPU_ARMV8A)),)
FR_FREEIMAGE_CFLAGS += -DPNG_ARM_NEON_OPT=0
endif

ifeq ($(HOSTARCH),aarch64)
FR_FREEIMAGE_CFLAGS += -fPIC
FR_FREEIMAGE_CXXFLAGS += -fPIC
endif

define FR_FREEIMAGE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(FR_FREEIMAGE_CFLAGS)" \
		CXXFLAGS="$(FR_FREEIMAGE_CXXFLAGS) -std=c++11" \
		$(MAKE) -C $(@D)
endef

define FR_FREEIMAGE_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install
endef

define FR_FREEIMAGE_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))
