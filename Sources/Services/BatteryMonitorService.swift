import Foundation
import IOKit
import IOKit.ps
import Combine

public final class BatteryMonitorService: ObservableObject {
    public static let shared = BatteryMonitorService()

    @Published public private(set) var percentage: Int = 100
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var currentWatts: Double = 0.0
    @Published public private(set) var cycleCount: Int = 0
    @Published public private(set) var timeRemainingMinutes: Int? = nil

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
            if let cap = desc["Current Capacity"] as? Int {
                self.percentage = cap
            }
            if let charging = desc["Is Charging"] as? Bool {
                self.isCharging = charging
            }
            if let time = desc["Time to Empty"] as? Int, time > 0 {
                self.timeRemainingMinutes = time
            } else {
                self.timeRemainingMinutes = nil
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
    }
}

