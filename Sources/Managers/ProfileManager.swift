import Foundation
import Combine

public final class ProfileManager: ObservableObject {
    public static let shared = ProfileManager()

    private var isInitializing = true

    @Published public var isOrdinaryActive: Bool = false {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(isOrdinaryActive, forKey: "isOrdinaryActive")
            applyCurrentSettings()
        }
    }

    // 4 Core User-Controlled Sliders
    @Published public var processorLevel: Int = 0 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(processorLevel, forKey: "processorLevel")
            if isOrdinaryActive {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    self.powerModeService.setProcessorLevel(self.processorLevel)
                }
            }
        }
    }

    @Published public var targetRefreshRate: Double = 60.0 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(targetRefreshRate, forKey: "targetRefreshRate")
            if isOrdinaryActive {
                displayService.setRefreshRate(targetRefreshRate)
            }
        }
    }

    @Published public var displayBrightness: Double = 0.40 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(displayBrightness, forKey: "displayBrightness")
            if isOrdinaryActive {
                displayBrightnessService.setBrightness(Float(displayBrightness))
            }
        }
    }

    @Published public var keyboardBrightness: Double = 0.0 {
        didSet {
            guard !isInitializing else { return }
            UserDefaults.standard.set(keyboardBrightness, forKey: "keyboardBrightness")
            if isOrdinaryActive {
                keyboardService.setBrightness(Float(keyboardBrightness))
            }
        }
    }

    @Published public var selectedPresetName: String? = "Ordinary Typing"
    @Published public var profiles: [BatteryProfile] = BatteryProfile.defaultPresets

    public var displayService = DisplayService.shared
    public var displayBrightnessService = DisplayBrightnessService.shared
    public var keyboardService = KeyboardService.shared
    public var powerModeService = PowerModeService.shared
    public var batteryMonitor = BatteryMonitorService.shared

    private init() {
        self.isOrdinaryActive = UserDefaults.standard.bool(forKey: "isOrdinaryActive")

        if UserDefaults.standard.object(forKey: "processorLevel") != nil {
            self.processorLevel = UserDefaults.standard.integer(forKey: "processorLevel")
        } else {
            self.processorLevel = 0
        }

        if let savedRate = UserDefaults.standard.object(forKey: "targetRefreshRate") as? Double {
            self.targetRefreshRate = savedRate
        } else {
            self.targetRefreshRate = 60.0
        }

        if let savedDisp = UserDefaults.standard.object(forKey: "displayBrightness") as? Double {
            self.displayBrightness = savedDisp
        } else {
            self.displayBrightness = 0.40
        }

        if let savedKb = UserDefaults.standard.object(forKey: "keyboardBrightness") as? Double {
            self.keyboardBrightness = savedKb
        } else {
            self.keyboardBrightness = 0.0
        }

        self.selectedPresetName = UserDefaults.standard.string(forKey: "selectedPresetName") ?? "Ordinary Typing"

        // Capture initial hardware baselines
        displayService.captureOriginalMode()
        displayBrightnessService.captureOriginalBrightness()
        keyboardService.captureOriginalBrightness()

        self.isInitializing = false

        // Defer applying settings until after SwiftUI app hierarchy is mounted
        DispatchQueue.main.async { [weak self] in
            if self?.isOrdinaryActive == true {
                self?.applyCurrentSettings()
            }
        }
    }

    public func loadPreset(_ preset: BatteryProfile) {
        self.selectedPresetName = preset.name
        UserDefaults.standard.set(preset.name, forKey: "selectedPresetName")

        self.processorLevel = preset.processorLevel
        self.targetRefreshRate = preset.targetRefreshRate
        self.displayBrightness = preset.displayBrightness
        self.keyboardBrightness = preset.keyboardBrightness

        if !isOrdinaryActive {
            self.isOrdinaryActive = true
        } else {
            applyCurrentSettings()
        }
    }

    public func applyCurrentSettings() {
        guard !isInitializing else { return }

        if isOrdinaryActive {
            let pLevel = self.processorLevel
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.powerModeService.setProcessorLevel(pLevel)
            }
            displayService.setRefreshRate(targetRefreshRate)
            displayBrightnessService.setBrightness(Float(displayBrightness))
            keyboardService.setBrightness(Float(keyboardBrightness))
        } else {
            // Restore native hardware baselines
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.powerModeService.setProcessorLevel(3) // Normal
            }
            displayService.restoreOriginalRefreshRate()
            displayBrightnessService.restoreOriginalBrightness()
            keyboardService.restoreOriginalBrightness()
        }
    }

    public var processorLevelName: String {
        switch processorLevel {
        case 0: return "Super Low"
        case 1: return "Low"
        case 2: return "Medium"
        default: return "Normal"
        }
    }

    public var menuBarIcon: String {
        if isOrdinaryActive {
            return "leaf.circle.fill"
        } else {
            return "leaf.circle"
        }
    }
}
