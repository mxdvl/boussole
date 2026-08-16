#!/usr/bin/env sh
# Auto rebuild + reload on save: re-runs the build, which side-loads into the
# already-open simulator (no restart). Not true hot reload (app state resets
# each load), but hands-free.
#
# Uses fswatch (native macOS FSEvents) when available, else a simple mtime poll.
# For the nicer path: brew install fswatch
#
# Usage:
#   ./watch.sh                 # target venu445mm
#   ./watch.sh vivoactive5     # any installed device
set -eu

cd "$(dirname "$0")"
DEVICE="${1:-venu445mm}"
WATCHED="source resources manifest.xml monkey.jungle"

# Exit cleanly on Ctrl-C instead of letting the loop swallow the signal and
# carry on. The simulator runs in the background and is left open.
trap 'echo; echo "stopped (simulator left running)."; exit 0' INT TERM

# Initial build + launch.
./run.sh "$DEVICE" || true

if command -v fswatch >/dev/null 2>&1; then
  echo "watching with fswatch (Ctrl-C to stop)..."
  # -o batches events into a single line per change.
  fswatch -o $WATCHED | while read -r _; do
    echo ""
    echo "change detected, reloading..."
    ./run.sh "$DEVICE" || true
  done
else
  echo "fswatch not found; polling every 1s (brew install fswatch for FSEvents)."
  touch .watch_marker
  while true; do
    if [ -n "$(find $WATCHED -type f -newer .watch_marker 2>/dev/null)" ]; then
      touch .watch_marker
      echo ""
      echo "change detected, reloading..."
      ./run.sh "$DEVICE" || true
    fi
    sleep 1
  done
fi
