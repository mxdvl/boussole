# Boussole

A custom Garmin Connect IQ **watch face**, built with the Monkey C SDK.

Current state: concentric rings filling clockwise from 12 o'clock — a steps
arc at the rim, and a single 12-hour time arc with an outward tick to the
minutes and an inward tick to the hour. Named _boussole_ ("compass" in French) —
the design will grow toward a compass theme.

## Target devices

- `venu445mm` — Venu 4, 45 mm, 454 × 454 round AMOLED

Install this device image from the **Connect IQ SDK Manager → Devices** tab
before building/simulating.

## Prerequisites

Add both the JDK and the SDK to your `PATH`. The Homebrew OpenJDK 26 is
keg-only, and this SDK's tools run fine on it:

```fish
fish_add_path /opt/homebrew/opt/openjdk/bin
fish_add_path "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2/bin"
```

- The `venu445mm` device image, installed via **SDK Manager → Devices**.
- `developer_key.der` in the project root (already generated; git-ignored).

## Build & run

One command builds and side-loads into the simulator:

```sh
./run.sh
```

Or manually:

```sh
mkdir -p bin
monkeyc -o bin/boussole.prg -f monkey.jungle -y developer_key.der -d venu445mm -w -l 2
connectiq                       # launch the simulator (once)
monkeydo bin/boussole.prg venu445mm
```

In the simulator, pick a watch face via **Settings** if it doesn't show
automatically. Use **File → Time** to fast-forward the clock and watch the
hands move.

## Editor support

Monkey C's full IntelliSense (completion, go-to-definition, inline API docs,
semantic type checking) is provided by Garmin's official **VS Code "Monkey C"
extension** — that's the paved-road editor experience.

In Zed there is no official Monkey C language server. Options:

- Install a community **Monkey C** extension from Zed's extensions panel
  (`zed: extensions`) for tree-sitter syntax highlighting, if available.
- Rely on **build-time type checking**: `monkeyc -l 2` (or `-l 3` for strict)
  reports type errors and warnings; `run.sh` uses `-l 2`.
- Keep VS Code + the CIQ extension around when you want deep IntelliSense,
  and do day-to-day editing in Zed.

## Assets / icons

Source art lives in `assets/` as SVG. Connect IQ can't use SVG directly, so
`icons.sh` rasterises it to the PNG drawables with [`resvg`](https://github.com/linebender/resvg):

```sh
./icons.sh        # regenerate launcher_icon.png from assets/logo.svg
./icons.sh 72     # at a specific pixel size
```

Re-run it whenever the SVGs change. The size is a placeholder until the Venu 4
launcher-icon dimensions are read from the installed device's `compiler.json`.

## Project layout

```
manifest.xml                     # app id, type=watchface, target products
monkey.jungle                    # build config
resources/strings/strings.xml    # app name
resources/drawables/             # launcher icon + drawable defs
source/BoussoleApp.mc            # Application entry point
source/BoussoleView.mc           # reads the device, builds the scene, renders it
source/Layout.mc                 # track radii and polar maths, from screen size
source/Shapes.mc                 # plain drawing records (Arc, Line, Dot, Box)
source/StepsRing.mc              # pure: steps arc at the rim
source/TimeRing.mc               # pure: arc between the hands, hour points, ticks, sun marker
source/Numerals.mc               # pure: roman numerals as strokes
source/SunCalc.mc                # pure: sunrise equation + next sun event
source/Render.mc                 # the only code that draws
```

## Notes / next steps

- The Venu 4 is AMOLED. For always-on display support you'll later want
  burn-in protection (a low-color, low-pixel "always-on" variant drawn in
  `onUpdate` when the device is in low-power mode). Not needed for this
  first step, which updates once per minute.
