# SeedSim

SeedSim is a native macOS app that simulates the SenseCAP Watcher UI. It compiles the same LVGL 8.4 that the firmware uses, renders it into a 412x412 framebuffer, and draws it inside a photo of the real device. Stack: Swift 6.2 package, SwiftUI, C. Status: active, released on GitHub Releases.

## Commands

| Task | Command |
|------|---------|
| Build | `swift build` |
| Package the app | `./Scripts/package_app.sh release` |
| Package, run | `./Scripts/package_app.sh release && open SeedSim.app` |
| Kill, package (ad hoc), relaunch | `./Scripts/compile_and_run.sh` |
| Normalize device frames | `python3 Scripts/normalize_frames.py <out_dir> <art...>` |

- `normalize_frames.py` needs OpenCV and NumPy. Run it with `uv run --with opencv-python --with numpy python3 Scripts/normalize_frames.py ...`.

## Architecture

| Part | Role |
|------|------|
| `Sources/CLVGL/` | C target: vendored LVGL 8.4 (`lvgl/`), `lv_conf.h`, the engine bridge (`engine.c`, `include/watcher_engine.h`), and the UI (`ui_home.c`). |
| `Sources/SeedSim/Simulator/` | `LVGLEngine` drives the C engine. `DeviceStageView` draws the framebuffer in the device photo. |
| `Sources/SeedSim/Frames/`, `Resources/` | Device frame photos, cutouts, and `frames.json` with the shared panel geometry. |
| `Sources/SeedSim/Inspector/` | Inspector panel and the knob wheel. |
| `Sources/SeedSim/Devices/` | Device list and facts. |

## Rules

- Write the watcher UI in `Sources/CLVGL/ui_home.c` as plain LVGL 8.4 C. The same file compiles into the firmware, so do not use simulator-only APIs in it.
- The knob is an `LV_INDEV_TYPE_ENCODER` device with a default group, and touch is `LV_INDEV_TYPE_POINTER`. The firmware BSP does not attach a group to its encoder, so a screen for the device needs `lv_indev_set_group`.
- After you add or change a frame photo, run `normalize_frames.py` so that all frames share one canvas and one panel circle.
- `AppIcon.icon` is an Icon Composer package. `package_app.sh` compiles it with `actool`, because `iconutil` cannot read it.

## Release

- `version.env` sets `APP_NAME`, `BUNDLE_ID` (`com.optimalapps.seedsim`), `MARKETING_VERSION`, `BUILD_NUMBER`, `MACOS_MIN_VERSION` (26.0), and `ARCHES` (`arm64`). Increase the version there.
- For a signed build, set `APP_IDENTITY` to the Developer ID identity, and set `APP_KEYCHAIN` if the identity is in a separate keychain. With `SIGNING_MODE=adhoc` or no `APP_IDENTITY`, the script signs ad hoc.
- Releases are signed under Optimal Life Technologies. Zip `SeedSim.app` and attach it to a GitHub release on `Aayush9029/SeedSim`.
- The repository is public. Do not commit signing identities, keychain paths, or private device data.
