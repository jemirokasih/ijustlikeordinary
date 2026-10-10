import Foundation
import IOKit
import IOKit.ps
import Combine

public final class BatteryMonitorService: ObservableObject {
    public static let shared = BatteryMonitorService()

    @Published public private(set) var percentage: Int = 100
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isOnACPower: Bool = false
    @Published public private(set) var powerSourceState: String = "Battery Power"
    @Published public private(set) var currentWatts: Double = 0.0
    @Published public private(set) var cycleCount: Int = 0
    @Published public private(set) var timeToEmptyMinutes: Int? = nil
    @Published public private(set) var timeToFullMinutes: Int? = nil
    @Published public private(set) var currentCapacityMAh: Int = 0
    @Published public private(set) var maxCapacityMAh: Int = 0

    // Baseline wattage when M1 Max runs unthrottled with 120Hz and full brightness
    public let normalBaselineWatts: Double = 16.5

    private var timer: AnyCancellable?

    private init() {
        refresh()
        startMonitoring()
    }

    public func startMonitoring() {
        timer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    public func refresh() {
        readIOPSInfo()
        readSmartBatteryInfo()
    }

    private func readIOPSInfo() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            if let state = desc["Power Source State"] as? String {
                self.powerSourceState = state
                self.isOnACPower = (state == "AC Power")
            }
            if let cap = desc["Current Capacity"] as? Int {
                self.percentage = cap
            }
            if let charging = desc["Is Charging"] as? Bool {
                self.isCharging = charging
            }
            if let timeEmpty = desc["Time to Empty"] as? Int, timeEmpty > 0, timeEmpty < 65535 {
                self.timeToEmptyMinutes = timeEmpty
            } else {
                self.timeToEmptyMinutes = nil
            }
            if let timeFull = desc["Time to Full Charge"] as? Int, timeFull > 0, timeFull < 65535 {
                self.timeToFullMinutes = timeFull
            } else {
                self.timeToFullMinutes = nil
            }
        }
    }

    private func readSmartBatteryInfo() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else {
            return
        }

        let voltage = dict["Voltage"] as? Double ?? 0
        let amperage = dict["Amperage"] as? Double ?? 0
        self.currentWatts = abs(voltage * amperage) / 1_000_000.0

        if let cycles = dict["CycleCount"] as? Int {
            self.cycleCount = cycles
        }
        if let currentCap = dict["CurrentCapacity"] as? Int {
            self.currentCapacityMAh = currentCap
        }
        if let maxCap = dict["MaxCapacity"] as? Int {
            self.maxCapacityMAh = maxCap
        }
        if let ext = dict["ExternalConnected"] as? Bool {
            self.isOnACPower = ext
        }

        // 1. Try reading official firmware TimeRemaining or AvgTimeToEmpty
        if !isOnACPower {
            if let tr = dict["TimeRemaining"] as? Int, tr > 0 && tr < 65535 {
                self.timeToEmptyMinutes = tr
            } else if let avg = dict["AvgTimeToEmpty"] as? Int, avg > 0 && avg < 65535 {
                self.timeToEmptyMinutes = avg
            } else if timeToEmptyMinutes == nil && currentWatts > 0.5 {
                // Accurate fallback based on real MacBook Pro battery capacity in Wh (70Wh for 14", 100Wh for 16")
                let batteryTotalWh: Double = 70.0
                let remainingWh = (Double(percentage) / 100.0) * batteryTotalWh
                let hoursRemaining = remainingWh / currentWatts
                if hoursRemaining > 0 && hoursRemaining < 48 {
                    self.timeToEmptyMinutes = Int(round(hoursRemaining * 60.0))
                }
            }
        }

        // 2. Fallback for time to full charge if charging
        if isCharging {
            if let avgFull = dict["AvgTimeToFull"] as? Int, avgFull > 0 && avgFull < 65535 {
                self.timeToFullMinutes = avgFull
            } else if let tr = dict["TimeRemaining"] as? Int, tr > 0 && tr < 65535 {
                self.timeToFullMinutes = tr
            }
        }
    }

    // Calculation formatting
    public var formattedEstimate: String {
        if isOnACPower {
            if isCharging {
                if let mins = timeToFullMinutes {
                    let h = mins / 60
                    let m = mins % 60
                    if h > 0 {
                        return "Penuh dalam \(h)j \(m)m"
                    } else {
                        return "Penuh dalam \(m) menit"
                    }
                } else {
                    return "Sedang mengisi daya..."
                }
            } else {
                return "Tersambung (Baterai Penuh)"
            }
        } else {
            if let mins = timeToEmptyMinutes {
                let h = mins / 60
                let m = mins % 60
                if h > 0 {
                    return "\(h) jam \(m) menit lagi"
                } else {
                    return "\(m) menit lagi"
                }
            } else {
                return "Menghitung estimasi..."
            }
        }
    }

    // Power savings percentage compared to unthrottled baseline
    public var estimatedSavingsPercent: Int {
        guard !isOnACPower, currentWatts > 0 else { return 0 }
        let saved = normalBaselineWatts - currentWatts
        guard saved > 0 else { return 0 }
        return min(75, Int(round((saved / normalBaselineWatts) * 100.0)))
    }
}
