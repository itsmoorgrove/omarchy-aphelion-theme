#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require magick rsvg-convert chromium


mkdir -p "$TMP_DIR/home"

rsvg-convert -w 900 -h 500 "$BUILD_DIR/unlock.svg" -o "$ROOT_DIR/unlock.png"
echo "  wrote unlock.png"

magick "$OUT_DIR/2-ensign.jpg" -crop 2560x1600+0+351 +repage "$BUILD_DIR/bg.png"
shot "$BUILD_DIR/preview.html" "$TMP_DIR/preview-raw.png" 1280 900 2.25
magick "$TMP_DIR/preview-raw.png" -crop 2880x1800+0+0 +repage "$ROOT_DIR/preview.png"
rm -f "$BUILD_DIR/bg.png"
echo "  wrote preview.png"

PLYMOUTH_ASSETS="${OMARCHY_PATH:-/usr/share/omarchy}/default/plymouth"
if [[ -f $PLYMOUTH_ASSETS/entry.png ]]; then
  bg=$(awk -F'"' '/^background *=/ { print $2; exit }' "$ROOT_DIR/colors.toml")
  fg=$(awk -F'"' '/^foreground *=/ { print $2; exit }' "$ROOT_DIR/colors.toml")

  for asset in entry lock bullet; do
    magick "$PLYMOUTH_ASSETS/$asset.png" -channel RGB +level-colors "$fg","$fg" "$TMP_DIR/pl-$asset.png"
  done

  logo_w=$(magick "$ROOT_DIR/unlock.png" -format "%w" info:)
  logo_h=$(magick "$ROOT_DIR/unlock.png" -format "%h" info:)
  entry_w=$(magick "$TMP_DIR/pl-entry.png" -format "%w" info:)
  entry_h=$(magick "$TMP_DIR/pl-entry.png" -format "%h" info:)

  logo_x=$(( (1920 - logo_w) / 2 ))
  logo_y=$(( (1080 - logo_h) / 2 ))
  entry_x=$(( (1920 - entry_w) / 2 ))
  entry_y=$(( logo_y + logo_h + 40 ))
  lock_h=$(( entry_h * 8 / 10 ))
  lock_w=$(( 84 * lock_h / 96 ))
  lock_x=$(( entry_x - lock_w - 15 ))
  lock_y=$(( entry_y + entry_h / 2 - lock_h / 2 ))
  bullet_y=$(( entry_y + entry_h / 2 - 4 ))

  magick "$TMP_DIR/pl-lock.png" -resize ${lock_w}x${lock_h}! "$TMP_DIR/pl-lock-s.png"
  magick "$TMP_DIR/pl-bullet.png" -resize 7x7! "$TMP_DIR/pl-bullet-s.png"

  magick -size 1920x1080 xc:"$bg" \
    "$ROOT_DIR/unlock.png" -geometry +${logo_x}+${logo_y} -compose Over -composite \
    "$TMP_DIR/pl-entry.png" -geometry +${entry_x}+${entry_y} -compose Over -composite \
    "$TMP_DIR/pl-lock-s.png" -geometry +${lock_x}+${lock_y} -compose Over -composite \
    "$TMP_DIR/pl-stage.png"

  cp "$TMP_DIR/pl-stage.png" "$TMP_DIR/pl-out.png"
  for i in 0 1 2 3 4 5 6; do
    bx=$(( entry_x + 20 + i * 12 ))
    magick "$TMP_DIR/pl-out.png" "$TMP_DIR/pl-bullet-s.png" -geometry +${bx}+${bullet_y} \
      -compose Over -composite "$TMP_DIR/pl-next.png"
    mv "$TMP_DIR/pl-next.png" "$TMP_DIR/pl-out.png"
  done

  magick "$TMP_DIR/pl-out.png" -strip "$ROOT_DIR/preview-unlock.png"
  echo "  wrote preview-unlock.png"
else
  echo "  skipped preview-unlock.png (Omarchy plymouth assets not found)"
fi

rm -rf "$TMP_DIR/gif" && mkdir -p "$TMP_DIR/gif"
i=0
for name in 1-aphelion-mark 2-ensign 3-aphelion 4-eclipse 5-monolith 6-void; do
  magick "$OUT_DIR/$name.jpg" -resize 1440x900^ -gravity center -extent 1440x900 \
    -resize 720x450 "$TMP_DIR/gif/$(printf '%02d' $i).png"
  i=$((i + 1))
done
magick -delay 140 -loop 0 "$TMP_DIR/gif"/*.png \
  -colors 240 -dither FloydSteinberg -layers OptimizeTransparency \
  "$ROOT_DIR/preview.gif"
echo "  wrote preview.gif"
