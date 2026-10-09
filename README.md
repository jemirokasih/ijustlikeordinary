# iJustLikeOrdinary

A native macOS Menu Bar application built in Swift & SwiftUI designed to optimize battery life on Apple Silicon MacBooks (M1 Max, M1 Pro, M2/M3/M4 Max/Pro with ProMotion displays).

## Key Features

- **SoC CPU Throttling (Low Power Mode)**: Toggles macOS Low Power Mode to limit clock frequencies on M1 Max P-cores and schedule workloads on high-efficiency E-cores.
- **Refresh Rate Limiter**: Cuts display refresh rate from ProMotion 120Hz down to 60Hz or 48Hz (cinema rate) using native `CoreGraphics`.
- **Keyboard Backlight Controller**: Automatically turns off or dims keyboard backlights when saving battery using `CoreBrightness`.
- **Real-Time Wattage & Battery Gauge**: Reads live battery discharge rate (in Watts, e.g. `8.2W`) directly from `AppleSmartBattery` IOKit.
- **Menu Bar Tray Native UI**: Runs unobtrusively in the macOS menu bar (`LSUIElement`).
- **Profile Presets**:
  - **Ordinary Typing**: 60Hz, Low Power Mode on, Keyboard Backlight off.
  - **Movie & Stream**: 48Hz cinema rate, Low Power Mode on, Keyboard Backlight off.
  - **Ultra Saver**: 48Hz, Low Power Mode on, Keyboard Backlight off.
  - **Full Beast**: 120Hz ProMotion, Low Power Mode off, Keyboard Backlight restored.

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

