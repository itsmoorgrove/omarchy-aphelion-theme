#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
T="$TMP_DIR/m"

magick -size ${W}x${H} gradient:'#070b12'-'#020306' $T-base.png

make_nebula $T-n1.png 8123 480 3.1
make_nebula $T-n2.png 5309 150 4.0
make_stars $T-s1.png 611 99.84% 0.7
make_stars $T-s2.png 918 99.983% 2.1

magick -size ${W}x${H} gradient:white-black -function Polynomial "1.6,-0.6,0" $T-skymask.png
magick $T-n1.png $T-skymask.png -compose Multiply -composite \
  -evaluate multiply 0.52 -fill '#8fa6c6' -tint 70 $T-n1c.png
magick $T-n2.png $T-skymask.png -compose Multiply -composite \
  -evaluate multiply 0.22 -fill '#c4d3e6' -tint 55 $T-n2c.png
magick $T-s1.png $T-skymask.png -compose Multiply -composite \
  \( +clone -blur 0x2.5 -evaluate multiply 0.6 \) -compose Screen -composite -evaluate multiply 0.70 $T-s1c.png
magick $T-s2.png $T-skymask.png -compose Multiply -composite \
  \( +clone -blur 0x7 -evaluate multiply 0.85 \) -compose Screen -composite -fill '#e8effb' -tint 40 $T-s2c.png

magick $T-base.png \
  $T-s1c.png -compose Screen -composite \
  $T-s2c.png -compose Screen -composite \
  $T-n1c.png -compose Screen -composite \
  $T-n2c.png -compose Screen -composite \
  $T-sky.png

sigil_vector $T-sig.png 1450
magick $T-sig.png -background black -alpha remove -alpha off $T-sigflat.png
magick $T-sigflat.png -blur 0x10 -evaluate multiply 0.66 -fill '#dfeeff' -tint 40 $T-g1.png
magick $T-sigflat.png -blur 0x48 -evaluate multiply 0.46 -fill '#93aecd' -tint 60 $T-g2.png
magick $T-sigflat.png -blur 0x150 -evaluate multiply 0.30 -fill '#5f7a9c' -tint 70 $T-g3.png

SX=$(( (W - $(magick $T-sig.png -format "%w" info:)) / 2 ))
SY=180

magick $T-sky.png \
  $T-g3.png -geometry +${SX}+${SY} -compose Screen -composite \
  $T-g2.png -geometry +${SX}+${SY} -compose Screen -composite \
  $T-g1.png -geometry +${SX}+${SY} -compose Screen -composite \
  $T-sig.png -geometry +${SX}+${SY} -compose Over -composite \
  $T-withsig.png

magick "$TMP_DIR/scene-4k.png" -crop ${W}x760+0+1400 +repage $T-band.png
magick -size ${W}x760 gradient:black-white -function Polynomial "-2.2,3.4,0" -level 0%,100% $T-bandmask.png
magick $T-band.png $T-bandmask.png -alpha off -compose CopyOpacity -composite $T-banda.png
magick $T-withsig.png $T-banda.png -geometry +0+1400 -compose Over -composite $T-scene.png

magick -size ${W}x${H} xc:black -fill white \
  -draw "translate 1920,1660 scale 1,0.055 circle 0,0 900,0" -blur 0x60 \
  -evaluate multiply 0.55 -fill '#dce9fa' -tint 35 $T-horizon.png

magick $T-sig.png -flip -resize 100%x42% -blur 0x9 -motion-blur 0x14+90 \
  -background black -alpha remove -alpha off -evaluate multiply 0.20 $T-refl.png
magick -size $(magick $T-refl.png -format "%wx%h" info:) gradient:white-black $T-reflmask.png
magick $T-refl.png $T-reflmask.png -compose Multiply -composite $T-reflm.png

magick $T-scene.png \
  $T-horizon.png -compose Screen -composite \
  $T-reflm.png -geometry +${SX}+1700 -compose Screen -composite \
  $T-lit.png

make_vignette $T-v.png 24
magick $T-lit.png $T-v.png -compose Multiply -composite -level 1%,99.5% -modulate 100,93,100 $T-graded.png
apply_grain $T-graded.png $T-final.png 15
encode $T-final.png 5-monolith
