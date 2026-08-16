#!/usr/bin/env sh
# Build the watch face and load it into the Connect IQ simulator.
#
# Usage:
#   ./run.sh                 # build for the real target (venu445mm)
#   ./run.sh vivoactive6     # preview on another installed device
#
# A device that isn't listed in manifest.xml is built from a temporary copy,
# so the committed manifest stays Venu 4-only (handy for previewing on a
# device you already have installed while waiting for the real one).
#
# Requires on PATH: monkeyc, connectiq, monkeydo (Connect IQ SDK bin/) + JDK.
set -eu

cd "$(dirname "$0")"

DEVICE="${1:-venu445mm}"
OUT="bin/boussole.prg"
mkdir -p bin

if grep -q "id=\"$DEVICE\"" manifest.xml; then
  echo "building for $DEVICE..."
  monkeyc -o "$OUT" -f monkey.jungle -y developer_key.der -d "$DEVICE" -w -l 3
else
  echo "building for $DEVICE (preview; not in manifest)..."
  TMP=".preview"
  rm -rf "$TMP"
  mkdir -p "$TMP"
  cp -R source resources manifest.xml monkey.jungle "$TMP"/
  sed -i '' "s/id=\"venu445mm\"/id=\"$DEVICE\"/" "$TMP"/manifest.xml
  monkeyc -o "$OUT" -f "$TMP"/monkey.jungle -y developer_key.der -d "$DEVICE" -w -l 3
  rm -rf "$TMP"
fi

# Start the simulator if it doesn't seem to be running yet.
if ! pgrep -if "connectiq" >/dev/null 2>&1; then
  echo "starting simulator..."
  connectiq &
  sleep 3
fi

# monkeydo stays attached (it streams logs and holds the app open), which would
# block callers like watch.sh forever. Kill any previous load so reloads don't
# stack, then run it in the background and return.
pkill -f "monkeydo" >/dev/null 2>&1 || true
echo "loading onto simulator..."
monkeydo "$OUT" "$DEVICE" &
