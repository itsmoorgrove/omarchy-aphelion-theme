#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require magick rsvg-convert

magick "$SRC_DIR/sigil.png" -colorspace Gray -level 14%,90% "$TMP_DIR/sigil-mask.png"
magick -size 1254x1254 xc:white "$TMP_DIR/sigil-mask.png" -alpha off \
  -compose CopyOpacity -composite "$TMP_DIR/sigil-alpha.png"

magick "$SRC_DIR/scene.png" -colorspace RGB \
  -filter Lanczos -resize 200% \
  -unsharp 0x0.9+0.30+0.005 \
  -filter Lanczos -resize ${W}x${H}! \
  -colorspace sRGB \
  -adaptive-sharpen 0x0.8+0.02 \
  "$TMP_DIR/scene-base.png"

magick -size ${W}x${H} xc:gray50 -attenuate 0.30 +noise Gaussian -colorspace Gray -blur 0x0.35 "$TMP_DIR/_g.png"
magick "$TMP_DIR/scene-base.png" "$TMP_DIR/_g.png" -compose Overlay -composite "$TMP_DIR/_go.png"
magick "$TMP_DIR/scene-base.png" "$TMP_DIR/_go.png" -compose blend -define compose:args=16 -composite \
  -level 0.8%,99.5% "$TMP_DIR/scene-4k.png"
rm -f "$TMP_DIR/_g.png" "$TMP_DIR/_go.png"

echo "  prepared sigil-alpha.png and scene-4k.png"
