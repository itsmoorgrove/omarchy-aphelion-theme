#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require magick rsvg-convert chromium

DOCS_DIR="$ROOT_DIR/docs"
mkdir -p "$DOCS_DIR" "$TMP_DIR/home"


if [[ ! -f $TMP_DIR/eclipse-sky.png ]]; then
  bash "$BUILD_DIR/30-eclipse.sh" >/dev/null
fi

magick "$TMP_DIR/eclipse-sky.png" -crop 3840x1210+0+280 +repage -resize 2800x "$BUILD_DIR/banner-bg.png"
shot "$BUILD_DIR/banner.html" "$TMP_DIR/banner-raw.png" 1400 500 2
magick "$TMP_DIR/banner-raw.png" -crop 2800x880+0+0 +repage -resize 1400x \
  -quality 94 -strip "$DOCS_DIR/banner.png"
rm -f "$BUILD_DIR/banner-bg.png"
echo "  wrote docs/banner.png"

shot "$BUILD_DIR/palette.html" "$TMP_DIR/palette-raw.png" 1400 580 2
magick "$TMP_DIR/palette-raw.png" -crop 2800x1040+0+0 +repage -resize 1400x \
  -quality 94 -strip "$DOCS_DIR/palette.png"
echo "  wrote docs/palette.png"
