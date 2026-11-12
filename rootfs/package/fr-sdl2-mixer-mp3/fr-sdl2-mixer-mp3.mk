################################################################################
#
# fr-sdl2-mixer-mp3: Buildroot builds SDL2_mixer with --disable-music-mp3. Turn its
# built-in minimp3 decoder back on (no extra library): EmulationStation then plays the
# EPIC-CODY system sounds that are MP3 and MP3 menu music from roms/bgmusic.
# br2-external makefiles are read after Buildroot's, and configure takes the last flag.
#
################################################################################

SDL2_MIXER_CONF_OPTS += --enable-music-mp3 --enable-music-mp3-minimp3 --disable-music-mp3-mpg123
