<p align="center">
  <img src="readme-assets/MacAppIcon.png" width="128" alt="SeedSim">
  <h1 align="center">SeedSim</h1>
  <p align="center">A native macOS simulator for SenseCAP Watcher firmware</p>
</p>

<p align="center">
  <a href="https://github.com/Aayush9029/SeedSim/releases/latest"><img src="https://img.shields.io/github/v/release/Aayush9029/SeedSim?color=2ea043" alt="Release"></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-0969da" alt="macOS 26+">
</p>

> [!WARNING]
> The device is very mid. It looks well built and the idea has real potential, but you get what you pay for.
> The docs are bleak, the SDKs are scattered, and the firmware is rough.

<p align="center">
  <img src="readme-assets/hero.jpeg" alt="SeedSim">
</p>

## What it is

The SenseCAP Watcher runs LVGL on an ESP32-S3 behind a 412x412 round panel. Iterating on that UI normally means building with ESP-IDF and flashing over USB, which is slow enough to kill the fun.

SeedSim compiles the same LVGL 8.4 the firmware uses, renders it into a framebuffer, and composites it into a photo of the real device.

<p align="center">
  <img src="readme-assets/half.jpeg" alt="Frames and knob">
</p>

## Where this is going

WIP, building while exploring. Free as in freedom hardware, that runs AI which is actually helpful, and some real OS UX practice along the way.

P.S. designing OS UX is so much fun. ty Jason for inspiring.

## How do I run my own UI

UI lives in `Sources/CLVGL/ui_home.c` as ordinary LVGL 8.4 C. The same file compiles into the firmware, so anything you build here ports across without changes.

```bash
./Scripts/package_app.sh release && open SeedSim.app
```

The knob arrives as an `LV_INDEV_TYPE_ENCODER` device with a default group already attached, and touch as `LV_INDEV_TYPE_POINTER`. Worth knowing: the firmware's BSP does not attach a group to its encoder, so a screen that works here needs `lv_indev_set_group` on device.
