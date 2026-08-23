#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require magick chromium
T="$TMP_DIR/en"

shot "$BUILD_DIR/wallpaper-ensign.html" $T-raw.png 1920 1160 2
magick $T-raw.png -crop ${W}x${H}+0+0 +repage $T-flat.png
apply_grain $T-flat.png $T-final.png 12
encode $T-final.png 2-ensign
