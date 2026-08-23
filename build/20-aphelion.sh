#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
T="$TMP_DIR/a"
HORIZON=1676

magick -size ${W}x${H} gradient:'#080c13'-'#020407' $T-base.png

magick -size 960x540 radial-gradient:white-black \
  -fx "max(0, 1 - abs(u-0.58)*1.45)" -blur 0x12 \
  -filter Lanczos -resize ${W}x${H}! $T-ring.png

make_nebula $T-n1.png 3311 460 1.8
make_nebula $T-n2.png 7727 130 2.6
magick $T-n1.png -swirl 130 -blur 0x8 $T-n1s.png
magick $T-n2.png -swirl -60 -blur 0x4 $T-n2s.png

magick -size ${W}x${H} gradient:white-black -function Polynomial "0,1.282,-0.282" $T-skymask.png

magick $T-n1s.png $T-ring.png -compose Multiply -composite $T-skymask.png -compose Multiply -composite \
  -evaluate multiply 0.98 -fill '#8ea4c4' -tint 70 $T-n1c.png
magick $T-n2s.png $T-ring.png -compose Multiply -composite $T-skymask.png -compose Multiply -composite \
  -evaluate multiply 0.58 -fill '#c6d5e8' -tint 55 $T-n2c.png

make_stars $T-s1.png 4242 99.82% 0.7
make_stars $T-s2.png 9119 99.980% 2.1
magick $T-s1.png $T-skymask.png -compose Multiply -composite \
  \( +clone -blur 0x2.5 -evaluate multiply 0.6 \) -compose Screen -composite -evaluate multiply 0.8 $T-s1c.png
magick $T-s2.png $T-skymask.png -compose Multiply -composite \
  \( +clone -blur 0x7 -evaluate multiply 0.85 \) -compose Screen -composite -fill '#e8effb' -tint 40 $T-s2c.png

magick $T-base.png \
  $T-s1c.png -compose Screen -composite \
  $T-s2c.png -compose Screen -composite \
  $T-n1c.png -compose Screen -composite \
  $T-n2c.png -compose Screen -composite \
  $T-sky.png

magick "$TMP_DIR/sigil-alpha.png" -filter Lanczos -resize 1598x1598 $T-sig.png
SX=1121
SY=128

magick $T-sig.png -background black -alpha remove -alpha off $T-sigflat.png
magick $T-sigflat.png -blur 0x12 -evaluate multiply 0.72 -fill '#dcebfb' -tint 40 $T-g1.png
magick $T-sigflat.png -blur 0x46 -evaluate multiply 0.52 -fill '#93aecd' -tint 60 $T-g2.png
magick $T-sigflat.png -blur 0x150 -evaluate multiply 0.34 -fill '#5f7a9c' -tint 70 $T-g3.png

magick -size ${W}x${H} xc:black -fill white -draw "rectangle 1914,1540 1926,${HORIZON}" -blur 0x3 $T-beam.png
magick -size ${W}x${H} xc:black -fill white -draw "rectangle 1902,1540 1938,${HORIZON}" -blur 0x30 \
  -evaluate multiply 0.48 $T-beamglow.png
magick -size ${W}x${H} gradient:black-white -function Polynomial "-0.7,1.5,0.10" $T-beammask.png
magick $T-beam.png $T-beammask.png -compose Multiply -composite $T-beamc.png
magick $T-beamglow.png $T-beammask.png -compose Multiply -composite -fill '#bcd3ee' -tint 45 $T-beamgc.png

magick $T-sky.png \
  $T-g3.png -geometry +${SX}+${SY} -compose Screen -composite \
  $T-g2.png -geometry +${SX}+${SY} -compose Screen -composite \
  $T-beamgc.png -compose Screen -composite \
  $T-beamc.png -compose Screen -composite \
  $T-g1.png -geometry +${SX}+${SY} -compose Screen -composite \
  $T-sig.png -geometry +${SX}+${SY} -compose Over -composite \
  $T-withsig.png

magick "$TMP_DIR/scene-4k.png" -crop ${W}x800+0+1360 +repage $T-band.png
magick -size ${W}x800 gradient:black-white -function Polynomial "-2.0,3.2,0" $T-bandmask.png
magick $T-band.png $T-bandmask.png -alpha off -compose CopyOpacity -composite $T-banda.png
magick $T-withsig.png $T-banda.png -geometry +0+1360 -compose Over -composite $T-scene.png

magick -size ${W}x${H} xc:black -fill white \
  -draw "translate 1920,${HORIZON} scale 1,0.05 circle 0,0 1000,0" -blur 0x70 \
  -evaluate multiply 0.62 -fill '#dfeafb' -tint 30 $T-horizon.png

magick $T-scene.png $T-horizon.png -compose Screen -composite $T-lit.png

make_vignette $T-v.png 22
magick $T-lit.png $T-v.png -compose Multiply -composite -level 1%,99.5% -modulate 100,94,100 $T-graded.png
apply_grain $T-graded.png $T-final.png 15
encode $T-final.png 3-aphelion
