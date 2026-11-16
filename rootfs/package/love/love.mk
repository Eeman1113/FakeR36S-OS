################################################################################
#
# love
#
################################################################################

LOVE_VERSION = 11.5
LOVE_SOURCE = love-$(LOVE_VERSION)-linux-src.tar.gz
LOVE_SITE = https://github.com/love2d/love/releases/download/$(LOVE_VERSION)
LOVE_LICENSE = Zlib
LOVE_LICENSE_FILES = license.txt
LOVE_DEPENDENCIES = host-pkgconf luajit sdl2 zlib openal freetype libmodplug libvorbis libtheora
# the release tarball ships a generated configure; Balatro and friends use OGG, not MP3
LOVE_CONF_OPTS = --with-lua=luajit --disable-mpg123 --disable-gme

$(eval $(autotools-package))
