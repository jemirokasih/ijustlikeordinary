import Foundation
import Combine
import AppKit

public final class BatteryHealthService: ObservableObject {
    public static let shared = BatteryHealthService()

    @Published public private(set) var maximumCapacity: Int = 100
    @Published public private(set) var cycleCount: Int = 0
    @Published public private(set) var condition: String = "Normal"
    @Published public private(set) var hasBattCLI: Bool = false

    @Published public var isBatteryGuardEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBatteryGuardEnabled, forKey: "isBatteryGuardEnabled")
            updateChargeProtection()
        }
    }

    @Published public var targetLimit: Int {
        didSet {
            UserDefaults.standard.set(targetLimit, forKey: "targetChargeLimit")
            updateChargeProtection()
        }
    }

    @Published public var isThermalProtectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isThermalProtectionEnabled, forKey: "isThermalProtectionEnabled")
        }
    }

    private var hasNotifiedThisSession: Bool = false
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.isBatteryGuardEnabled = UserDefaults.standard.object(forKey: "isBatteryGuardEnabled") as? Bool ?? true
        self.targetLimit = UserDefaults.standard.object(forKey: "targetChargeLimit") as? Int ?? 80
        self.isThermalProtectionEnabled = UserDefaults.standard.object(forKey: "isThermalProtectionEnabled") as? Bool ?? true

        checkBattCLI()
        refreshHealth()

        // Periodically refresh health and check guard thresholds
        Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.evaluateGuardState()
            }
            .store(in: &cancellables)
    }

    public func checkBattCLI() {
        let paths = ["/opt/homebrew/bin/batt", "/usr/local/bin/batt"]
        self.hasBattCLI = paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    public func refreshHealth() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let task = Process()
            task.launchPath = "/usr/sbin/system_profiler"
            task.arguments = ["SPPowerDataType"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()

            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let text = String(data: data, encoding: .utf8) else { return }

                var cycles = 0
                var cond = "Normal"
                var maxCap = 100

                for line in text.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("Cycle Count:") {
                        let parts = trimmed.components(separatedBy: ":")
                        if parts.count > 1, let c = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                            cycles = c
                        }
                    } else if trimmed.hasPrefix("Condition:") {
                        let parts = trimmed.components(separatedBy: ":")
                        if parts.count > 1 {
                            cond = parts[1].trimmingCharacters(in: .whitespaces)
                        }
                    } else if trimmed.hasPrefix("Maximum Capacity:") {
                        let clean = trimmed.replacingOccurrences(of: "Maximum Capacity:", with: "")
                            .replacingOccurrences(of: "%", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        if let mc = Int(clean) {
                            maxCap = mc
                        }
                    }
                }

                DispatchQueue.main.async {
                    self?.cycleCount = cycles
                    self?.condition = cond
                    self?.maximumCapacity = maxCap
                }
            } catch {}
        }
    }

    public func evaluateGuardState() {
        let battery = BatteryMonitorService.shared

        // Reset notification flag when battery drains below limit
        if battery.percentage < targetLimit {
            hasNotifiedThisSession = false
        }

        // 1. Check Battery Guard threshold (e.g. 80%)
        if isBatteryGuardEnabled && battery.isOnACPower && battery.percentage >= targetLimit {
            if hasBattCLI {
                applyBattLimit(targetLimit)
            } else if !hasNotifiedThisSession {
                notifyLimitReached()
                hasNotifiedThisSession = true
            }
        }

        // 2. Thermal Protection during AC charging: ensure cool CPU
        if isThermalProtectionEnabled && battery.isCharging {
            PowerModeService.shared.setLowPowerMode(enabled: true)
        }
    }

    public func updateChargeProtection() {
        if isBatteryGuardEnabled && hasBattCLI {
            applyBattLimit(targetLimit)
        } else if !isBatteryGuardEnabled && hasBattCLI {
            disableBattLimit()
        }
    }

    private func applyBattLimit(_ limit: Int) {
        let battPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/batt") ? "/opt/homebrew/bin/batt" : "/usr/local/bin/batt"
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.launchPath = battPath
            task.arguments = ["limit", "\(limit)"]
            task.standardOutput = Pipe()
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()
        }
    }

    private func disableBattLimit() {
        let battPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/batt") ? "/opt/homebrew/bin/batt" : "/usr/local/bin/batt"
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.launchPath = battPath
            task.arguments = ["disable"]
            task.standardOutput = Pipe()
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()
        }
    }

    private func notifyLimitReached() {
        let msg = "Battery reached \(targetLimit)%. Keeping charge at \(targetLimit)% extends lifespan."
        let script = "display notification \"\(msg)\" with title \"iJustLikeOrdinary\" subtitle \"Battery Health Guard\""
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        try? task.run()
    }

    public func openSystemBatterySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!
        NSWorkspace.shared.open(url)
    }
}

