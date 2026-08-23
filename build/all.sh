#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

for stage in 00-prepare 10-ensign 20-aphelion 30-eclipse 40-monolith 50-void 60-assets 70-docs; do
  echo "$stage"
  bash "$BUILD_DIR/$stage.sh"
done

rm -rf "$TMP_DIR"
echo "done"
