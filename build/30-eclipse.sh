#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
T="$TMP_DIR/e"

magick -size ${W}x${H} radial-gradient:'#070b11'-'#010204' -blur 0x30 $T-base.png

magick -size 960x540 radial-gradient:white-black \
  -fx "max(0, 1 - abs(u-0.60)*2.6)" -blur 0x10 \
  -filter Lanczos -resize ${W}x${H}! $T-ring.png

make_nebula $T-n1.png 4711 420 1.7
make_nebula $T-n2.png 991 110 2.4
magick $T-n1.png -swirl 110 -blur 0x8 $T-n1s.png
magick $T-n2.png -swirl -70 -blur 0x4 $T-n2s.png

make_stars $T-s1.png 22 99.84% 0.7
make_stars $T-s2.png 77 99.982% 2.2

magick $T-n1s.png $T-ring.png -compose Multiply -composite \
  -evaluate multiply 0.66 -fill '#8ea4c4' -tint 72 $T-n1c.png
magick $T-n2s.png $T-ring.png -compose Multiply -composite \
  -evaluate multiply 0.30 -fill '#c6d5e8' -tint 55 $T-n2c.png

magick $T-s1.png \( +clone -blur 0x2.5 -evaluate multiply 0.65 \) -compose Screen -composite \
  -evaluate multiply 0.80 $T-s1c.png
magick $T-s2.png \( +clone -blur 0x7 -evaluate multiply 0.8 \) -compose Screen -composite \
  -fill '#e6eefa' -tint 40 $T-s2c.png

magick $T-base.png \
  $T-s1c.png -compose Screen -composite \
  $T-s2c.png -compose Screen -composite \
  $T-n1c.png -compose Screen -composite \
  $T-n2c.png -compose Screen -composite \
  $T-sky.png

sigil_raster $T-sig.png 1860
magick $T-sig.png -background black -alpha remove -alpha off $T-sigflat.png
magick $T-sigflat.png -blur 0x14 -evaluate multiply 0.72 -fill '#dcebfb' -tint 40 $T-glow1.png
magick $T-sigflat.png -blur 0x55 -evaluate multiply 0.50 -fill '#93aecd' -tint 60 $T-glow2.png
magick $T-sigflat.png -blur 0x170 -evaluate multiply 0.36 -fill '#5f7a9c' -tint 70 $T-glow3.png

magick $T-sky.png \
  $T-glow3.png -gravity center -geometry +0-40 -compose Screen -composite \
  $T-glow2.png -gravity center -geometry +0-40 -compose Screen -composite \
  $T-glow1.png -gravity center -geometry +0-40 -compose Screen -composite \
  $T-sig.png   -gravity center -geometry +0-40 -compose Over -composite \
  $T-lit.png

make_vignette $T-v.png 20
magick $T-lit.png $T-v.png -compose Multiply -composite \
  -level 1.5%,99.5% -modulate 100,94,100 $T-graded.png
apply_grain $T-graded.png $T-final.png 15
encode $T-final.png 3-eclipse

cp $T-sky.png "$TMP_DIR/eclipse-sky.png"
