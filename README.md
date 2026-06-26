# BatteryAlert

A lightweight macOS menu bar app that notifies you when your battery is too low or too full.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- Lives in the menu bar — no Dock icon
- Alerts at configurable low and high battery thresholds (defaults: 20% and 80%)
- Plays a system sound, sends a native notification, and flashes the screen on alert
- Per-alert sound picker with volume control
- Preview buttons to test each alert without waiting for the threshold
- Launch at login toggle
- Zero idle CPU — uses IOKit event-driven notifications instead of polling

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build)

## Building

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BatteryAlert.xcodeproj \
  -scheme BatteryAlert \
  -configuration Release \
  build
```

The app bundle is output to `build/BatteryAlert.app`. Move it to `/Applications` and double-click to run.

## Usage

Click the battery icon in the menu bar to open the settings popover:

- **Low battery alert** — threshold slider + sound picker. Fires when discharging below the threshold.
- **High battery alert** — threshold slider + sound picker. Fires when charging above the threshold.
- **Alert volume** — controls the volume of alert sounds independently of system volume.
- **Preview** — trigger either alert immediately to test your settings.
- **Start at login** — registers the app as a login item via `SMAppService`.
