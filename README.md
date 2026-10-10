# iJustLikeOrdinary

A native macOS Menu Bar application built in Swift & SwiftUI designed to optimize battery life on Apple Silicon MacBooks (M1 Max, M1 Pro, M2/M3/M4 Max/Pro with ProMotion displays).

## Key Features

- **Master Ordinary Mode Toggle**: 1-click toggle to instantly drop power consumption across display, CPU, and backlight.
- **4 Granular Hardware Sliders**:
  - **Processor Level**: Super Low, Low, Medium, Normal (via macOS Low Power Mode).
  - **Refresh Rate**: 48Hz (cinema), 50Hz, 60Hz, 120Hz (ProMotion) via native `CoreGraphics`.
  - **Display Brightness**: 0% – 100% slider using `DisplayServices`.
  - **Keyboard Backlight**: 0% – 100% slider using `CoreBrightness`.
- **Optional Presets Dropdown**: Quick selection for *Ordinary Typing*, *Movie & Stream*, *Ultra Saver*, *Full Beast*, or *Custom*.
- **Accurate Real-Time Battery Calculations**:
  - Live wattage draw (`W`) and power savings percentage.
  - Accurate time to empty (hours and minutes remaining on battery).
  - Time until full charge when plugged into AC power.
- **Battery Longevity & Health Guard**:
  - Live health metrics: Maximum Capacity %, Cycle Count, and Battery Condition.
  - Charge Limit Protection (80% sweet spot to reduce high-voltage chemical wear).
  - Cool Charging (Thermal Guard) notifications to avoid degradation from charging heat.
  - Quick link to native macOS Battery Settings.
- **Native & Unobtrusive**: Pure Swift/SwiftUI running as a lightweight Menu Bar extra (`LSUIElement`). Safe user-space APIs with automatic hardware restoration on exit.

## Requirements

- macOS 13.0+ (Ventura, Sonoma, Sequoia, Tahoe)
- Apple Silicon MacBook (M1 / M2 / M3 / M4)

## Quick Start

### Run the App
Double-click `iJustLikeOrdinary.app` or launch from terminal:
```bash
open iJustLikeOrdinary.app
```

Or run directly from the release build:
```bash
./.build/release/ijustlikeordinary
```

### Optional: 1-Click Passwordless Low Power Mode
Display refresh rate (120Hz $\rightarrow$ 60Hz/48Hz) and keyboard backlight control work **without any root permission**.

To allow instant, passwordless switching of macOS Low Power Mode (`pmset`), run this one-line command once in Terminal:
```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pmset -a lowpowermode *" | sudo tee /etc/sudoers.d/ijustlikeordinary && sudo chmod 0440 /etc/sudoers.d/ijustlikeordinary
```
*(This command is also copyable with 1-click right inside the app's menu bar popover!)*

## Build from Source

```bash
# Compile and run unit tests
swift test

# Build release executable
swift build -c release

# Package into .app bundle
./scripts/bundle_app.sh
```

