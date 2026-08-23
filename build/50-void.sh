#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
T="$TMP_DIR/v"

magick -size ${W}x${H} xc:'#010204' $T-base.png

make_nebula $T-n1.png 20240 300 2.0
magick -size 960x540 gradient:white-black -rotate -28 -gravity center -crop 960x540+0+0 +repage \
  -function Polynomial "-3.0,3.0,0" -blur 0x14 -filter Lanczos -resize ${W}x${H}! $T-band.png
magick $T-n1.png $T-band.png -compose Multiply -composite \
  -evaluate multiply 0.52 -fill '#8ea6c8' -tint 75 $T-n1c.png

make_stars $T-s1.png 5150 99.70% 0.6
make_stars $T-s2.png 8080 99.955% 1.9
magick $T-s1.png \( +clone -blur 0x2 -evaluate multiply 0.55 \) -compose Screen -composite \
  -evaluate multiply 0.85 $T-s1c.png
magick $T-s2.png \( +clone -blur 0x8 -evaluate multiply 0.9 \) -compose Screen -composite \
  -fill '#e9f0fc' -tint 40 $T-s2c.png

magick $T-base.png \
  $T-s1c.png -compose Screen -composite \
  $T-s2c.png -compose Screen -composite \
  $T-n1c.png -compose Screen -composite \
  $T-sky.png

sigil_vector $T-sig.png 780
magick $T-sig.png -background black -alpha remove -alpha off $T-sigflat.png
magick $T-sigflat.png -blur 0x9   -evaluate multiply 0.75 -fill '#dfeeff' -tint 40 $T-g1.png
magick $T-sigflat.png -blur 0x40  -evaluate multiply 0.55 -fill '#9ab3d2' -tint 60 $T-g2.png
magick $T-sigflat.png -blur 0x150 -evaluate multiply 0.38 -fill '#5f7a9c' -tint 70 $T-g3.png

magick $T-sky.png \
  $T-g3.png -gravity center -compose Screen -composite \
  $T-g2.png -gravity center -compose Screen -composite \
  $T-g1.png -gravity center -compose Screen -composite \
  $T-sig.png -gravity center -compose Over -composite \
  $T-lit.png

make_vignette $T-v.png 16
magick $T-lit.png $T-v.png -compose Multiply -composite -level 1%,99.5% -modulate 100,94,100 $T-graded.png
apply_grain $T-graded.png $T-final.png 13
encode $T-final.png 5-void
