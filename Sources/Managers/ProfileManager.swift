import Foundation
import Combine

public final class ProfileManager: ObservableObject {
    public static let shared = ProfileManager()

    @Published public var isOrdinaryActive: Bool = false {
        didSet {
            if isOrdinaryActive != oldValue {
                UserDefaults.standard.set(isOrdinaryActive, forKey: "isOrdinaryActive")
                applyCurrentState()
            }
        }
    }

    @Published public var activeProfile: BatteryProfile {
        didSet {
            UserDefaults.standard.set(activeProfile.id.uuidString, forKey: "activeProfileID")
            if isOrdinaryActive {
                applyCurrentState()
            }
        }
    }

    @Published public var profiles: [BatteryProfile] = BatteryProfile.defaultPresets

    public var displayService = DisplayService.shared
    public var keyboardService = KeyboardService.shared
    public var powerModeService = PowerModeService.shared
    public var batteryMonitor = BatteryMonitorService.shared

    private init() {
        let savedActiveID = UserDefaults.standard.string(forKey: "activeProfileID")
        let initialProfile = BatteryProfile.defaultPresets.first { $0.id.uuidString == savedActiveID } ?? .ordinaryTyping
        self.activeProfile = initialProfile
        self.isOrdinaryActive = UserDefaults.standard.bool(forKey: "isOrdinaryActive")

        // Capture base states
        displayService.captureOriginalMode()
        keyboardService.captureOriginalBrightness()

        if isOrdinaryActive {
            applyCurrentState()
        }
    }

    public func selectProfile(_ profile: BatteryProfile) {
        if !isOrdinaryActive {
            isOrdinaryActive = true
        }
        self.activeProfile = profile
    }

    public func toggleOrdinary() {
        isOrdinaryActive.toggle()
    }

    private func applyCurrentState() {
        if isOrdinaryActive {
            // Apply active profile settings
            if let rate = activeProfile.targetRefreshRate {
                displayService.setRefreshRate(rate)
            }
            if activeProfile.turnOffKeyboardBacklight {
                keyboardService.setBrightness(0.0)
            } else {
                keyboardService.restoreOriginalBrightness()
            }
            if activeProfile.enableLowPowerMode {
                powerModeService.setLowPowerMode(enabled: true)
            } else {
                powerModeService.setLowPowerMode(enabled: false)
            }
        } else {
            // Restore default states
            displayService.restoreOriginalRefreshRate()
            keyboardService.restoreOriginalBrightness()
            powerModeService.setLowPowerMode(enabled: false)
        }
    }

    public var menuBarIcon: String {
        if isOrdinaryActive {
            return "leaf.circle.fill"
        } else {
            return "leaf.circle"
        }
    }

    public var menuBarStatusText: String {
        let rate = Int(round(displayService.currentRefreshRate))
        let watts = String(format: "%.1fW", batteryMonitor.currentWatts)
        if isOrdinaryActive {
            return "\(activeProfile.name) (\(rate)Hz • \(watts))"
        } else {
            return "Normal (\(rate)Hz • \(watts))"
        }
    }
}

