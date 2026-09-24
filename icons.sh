#!/usr/bin/env sh
# Rasterise SVG source art (assets/) into PNGs: the launcher-icon drawable
# Connect IQ needs at build time, and the Store's cover image. CIQ can't
# consume SVG directly, so regenerate PNGs whenever the source SVGs change.
#
# Usage:
#   ./icons.sh            # launcher icon at the default size + store cover
#   ./icons.sh 72         # launcher icon at a specific pixel size + store cover
#
# Requires: resvg (https://github.com/linebender/resvg)
set -eu

cd "$(dirname "$0")"

if ! command -v resvg >/dev/null 2>&1; then
  echo "error: resvg not found on PATH" >&2
  exit 1
fi

# Launcher-icon size for the Venu 4 (venu445mm compiler.json: 65x65).
SIZE="${1:-65}"

resvg -w "$SIZE" -h "$SIZE" assets/logo.svg resources/drawables/launcher_icon.png
echo "generated resources/drawables/launcher_icon.png (${SIZE}x${SIZE})"

# Connect IQ Store cover image: fixed 500x500, PNG, <=300KB.
resvg -w 500 -h 500 assets/logo.svg assets/cover.png
echo "generated assets/cover.png (500x500)"
