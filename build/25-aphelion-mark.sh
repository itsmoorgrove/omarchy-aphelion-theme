#!/bin/bash
# Aphelion wordmark wallpaper: 20-aphelion's sky/terrain with the ensign mark.
# Render size is overridable: W=7680 H=4320 bash build/25-aphelion-mark.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require magick rsvg-convert

W=${W_OVERRIDE:-$W}
H=${H_OVERRIDE:-$H}
S=$(awk "BEGIN{print $W/3840}")
NAME=${NAME:-1-aphelion-mark}
T="$TMP_DIR/m"

# scale a 4K-space length to the current render size
s() { awk "BEGIN{printf \"%d\", $1*$S}"; }
f() { awk "BEGIN{printf \"%.3f\", $1*$S}"; }

HORIZON=$(s 1676)

magick -size ${W}x${H} gradient:'#080c13'-'#020407' $T-base.png

# --- sky -------------------------------------------------------------------
make_nebula $T-n1.png 3311 460 1.8
make_nebula $T-n2.png 7727 130 2.6
magick $T-n1.png -swirl 130 -blur 0x$(f 8) $T-n1s.png
magick $T-n2.png -swirl -60 -blur 0x$(f 4) $T-n2s.png

# vertical plume: brightest on the centre column, fading toward the edges
magick \( -size $((W/2))x1 gradient:black-white \) \( +clone -flop \) +append \
  -filter Lanczos -resize ${W}x${H}! -evaluate Pow 1.8 -blur 0x$(f 30) $T-column.png
magick -size ${W}x${H} gradient:white-black -function Polynomial "0,1.282,-0.282" $T-skymask.png

magick $T-n1s.png $T-column.png -compose Multiply -composite $T-skymask.png -compose Multiply -composite \
  -evaluate multiply 1.15 -fill '#8ea4c4' -tint 70 $T-n1c.png
magick $T-n2s.png $T-column.png -compose Multiply -composite $T-skymask.png -compose Multiply -composite \
  -evaluate multiply 0.78 -fill '#c6d5e8' -tint 55 $T-n2c.png

make_stars $T-s1.png 4242 99.82% $(f 0.7)
make_stars $T-s2.png 9119 99.980% $(f 2.1)
magick $T-s1.png $T-skymask.png -compose Multiply -composite \
  \( +clone -blur 0x$(f 2.5) -evaluate multiply 0.6 \) -compose Screen -composite -evaluate multiply 0.75 $T-s1c.png
magick $T-s2.png $T-skymask.png -compose Multiply -composite \
  \( +clone -blur 0x$(f 7) -evaluate multiply 0.85 \) -compose Screen -composite -fill '#e8effb' -tint 40 $T-s2c.png

magick $T-base.png \
  $T-s1c.png -compose Screen -composite \
  $T-s2c.png -compose Screen -composite \
  $T-n1c.png -compose Screen -composite \
  $T-n2c.png -compose Screen -composite \
  $T-sky.png

# --- terrain band + horizon burst -----------------------------------------
BAND_H=$(s 800)
BAND_Y=$(s 1360)
magick "$TMP_DIR/scene-4k.png" -filter Lanczos -resize ${W}x${H}! \
  -crop ${W}x${BAND_H}+0+${BAND_Y} +repage $T-band.png
magick -size ${W}x${BAND_H} gradient:black-white -function Polynomial "-2.0,3.2,0" $T-bandmask.png
magick $T-band.png $T-bandmask.png -alpha off -compose CopyOpacity -composite $T-banda.png
magick $T-sky.png $T-banda.png -geometry +0+${BAND_Y} -compose Over -composite $T-scene.png

magick -size ${W}x${H} xc:black -fill white \
  -draw "translate $(s 1920),${HORIZON} scale 1,0.05 circle 0,0 $(s 1000),0" -blur 0x$(f 70) \
  -evaluate multiply 0.62 -fill '#dfeafb' -tint 30 $T-horizon.png
magick $T-scene.png $T-horizon.png -compose Screen -composite $T-lit.png

# --- mark ------------------------------------------------------------------
SIG_H=$(s 484)                       # svg box height; visible glyph is ~0.95 of it
SIG_W=$(awk "BEGIN{printf \"%d\", $SIG_H/1.6}")
SIG_X=$(( (W - SIG_W) / 2 ))
SIG_Y=$(s 578)
WORD_W=$(s 768)
WORD_Y=$(s 1115)

rsvg-convert -h "$SIG_H" "$BUILD_DIR/sigil.svg" -o $T-sig-white.png

magick -background none -fill white -font URWGothic-Book \
  -pointsize $(s 150) -kerning $(s 68) label:'APHELION ' -trim +repage \
  -filter Lanczos -resize ${WORD_W}x $T-word-white.png
WORD_X=$(( (W - $(magick $T-word-white.png -format %w info:)) / 2 ))

# silver gradient, both pieces share one ramp over the mark's vertical extent
MARK_TOP=$SIG_Y
MARK_H=$(( WORD_Y + $(magick $T-word-white.png -format %h info:) - SIG_Y ))
magick -size 8x${MARK_H} gradient:'#ffffff'-'#9fb2cb' -resize ${W}x${MARK_H}! $T-silver.png

magick -size ${W}x${H} xc:none \
  $T-sig-white.png -geometry +${SIG_X}+${SIG_Y} -compose Over -composite \
  $T-word-white.png -geometry +${WORD_X}+${WORD_Y} -compose Over -composite \
  $T-mark-alpha.png
magick -size ${W}x${H} xc:black $T-silver.png -geometry +0+${MARK_TOP} -compose Over -composite \
  $T-mark-alpha.png -alpha extract -compose CopyOpacity -composite $T-mark.png

magick $T-mark.png -background black -alpha remove -alpha off $T-markflat.png
magick $T-markflat.png -blur 0x$(f 14) -evaluate multiply 0.55 -fill '#dcebfb' -tint 40 $T-mg1.png
magick $T-markflat.png -blur 0x$(f 55) -evaluate multiply 0.34 -fill '#93aecd' -tint 60 $T-mg2.png

magick $T-lit.png \
  $T-mg2.png -compose Screen -composite \
  $T-mg1.png -compose Screen -composite \
  $T-mark.png -compose Over -composite \
  $T-withmark.png

# --- grade -----------------------------------------------------------------
make_vignette $T-v.png 22
magick $T-withmark.png $T-v.png -compose Multiply -composite -level 1%,99.5% -modulate 100,94,100 $T-graded.png
apply_grain $T-graded.png $T-final.png 15

if [[ ${W} -gt 3840 ]]; then
  # 8K master lives outside backgrounds/ so omarchy's wallpaper cycle stays 4K-only
  magick $T-final.png -quality 94 -sampling-factor 4:4:4 -interlace none -strip "$ROOT_DIR/$NAME-8k.jpg"
  echo "  wrote $NAME-8k.jpg"
else
  encode $T-final.png "$NAME"
fi
