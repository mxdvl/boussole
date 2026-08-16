#!/usr/bin/env sh
# Rasterise SVG source art (assets/) into the PNG drawables that Connect IQ
# needs. CIQ can't consume SVG at build time, so regenerate PNGs whenever the
# source SVGs change.
#
# Usage:
#   ./icons.sh            # generate at the default size
#   ./icons.sh 72         # generate at a specific pixel size
#
# Requires: resvg (https://github.com/linebender/resvg)
set -eu

cd "$(dirname "$0")"

if ! command -v resvg >/dev/null 2>&1; then
  echo "error: resvg not found on PATH" >&2
  exit 1
fi

# Placeholder size until the Venu 4 launcher-icon dimensions are confirmed
# from the installed device's compiler.json.
SIZE="${1:-60}"

resvg -w "$SIZE" -h "$SIZE" assets/logo.svg resources/drawables/launcher_icon.png
echo "generated resources/drawables/launcher_icon.png (${SIZE}x${SIZE})"
