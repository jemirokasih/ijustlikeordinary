import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        DisplayService.shared.restoreOriginalRefreshRate()
        DisplayBrightnessService.shared.restoreOriginalBrightness()
        KeyboardService.shared.restoreOriginalBrightness()
    }
}

@main
struct ijustlikeordinaryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var batteryMonitor = BatteryMonitorService.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: profileManager.menuBarIcon)
                if batteryMonitor.currentWatts > 0 {
                    Text(String(format: "%.1fW", batteryMonitor.currentWatts))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

