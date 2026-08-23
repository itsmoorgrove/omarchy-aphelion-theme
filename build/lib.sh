#!/bin/bash
set -euo pipefail

BUILD_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(dirname "$BUILD_DIR")
SRC_DIR="$BUILD_DIR/src"
TMP_DIR="$BUILD_DIR/.tmp"
OUT_DIR="$ROOT_DIR/backgrounds"

mkdir -p "$TMP_DIR" "$OUT_DIR"

W=3840
H=2160

require() {
  local missing=()
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    echo "missing: ${missing[*]}" >&2
    exit 1
  fi
}

make_nebula() {
  local out=$1 seed=$2 scale=$3 pow=$4
  magick -size ${scale}x$((scale * H / W)) -seed "$seed" plasma:fractal \
    -colorspace Gray -blur 0x2 -auto-level -evaluate Pow "$pow" \
    -filter Lanczos -resize ${W}x${H}! -blur 0x6 "$out"
}

make_stars() {
  local out=$1 seed=$2 thresh=$3 soften=$4
  magick -size ${W}x${H} -seed "$seed" xc:black -attenuate 1 +noise Random \
    -colorspace Gray -threshold "$thresh" -blur 0x"$soften" -auto-level "$out"
}

make_vignette() {
  local out=$1 lift=$2
  magick -size ${W}x${H} radial-gradient:white-black \
    -sigmoidal-contrast 4,55% +level "${lift}%,100%" "$out"
}

apply_grain() {
  local in=$1 out=$2 amount=$3
  magick -size ${W}x${H} -seed 1337 xc:gray50 -attenuate 0.32 +noise Gaussian -colorspace Gray -blur 0x0.35 "$TMP_DIR/_grain.png"
  magick "$in" "$TMP_DIR/_grain.png" -compose Overlay -composite "$TMP_DIR/_grained.png"
  magick "$in" "$TMP_DIR/_grained.png" -compose blend -define compose:args="$amount" -composite "$out"
  rm -f "$TMP_DIR/_grain.png" "$TMP_DIR/_grained.png"
}

sigil_raster() {
  local out=$1 height=$2
  magick "$TMP_DIR/sigil-alpha.png" -filter Lanczos -resize x"$height" "$out"
}

sigil_vector() {
  local out=$1 height=$2
  rsvg-convert -h "$height" "$BUILD_DIR/sigil.svg" -o "$out"
}

encode() {
  local in=$1 name=$2
  magick "$in" -quality 95 -sampling-factor 4:4:4 -interlace none -strip "$OUT_DIR/$name.jpg"
  echo "  wrote backgrounds/$name.jpg"
}

shot() {
  local page=$1 out=$2 width=$3 height=$4 scale=$5
  mkdir -p "$TMP_DIR/home"
  HOME="$TMP_DIR/home" chromium \
    --headless --no-sandbox --disable-gpu --disable-breakpad --hide-scrollbars \
    --user-data-dir="$TMP_DIR/chromium" \
    --force-device-scale-factor="$scale" \
    --virtual-time-budget=8000 \
    --screenshot="$out" \
    --window-size="$width,$height" \
    "file://$page" 2>/dev/null
}
