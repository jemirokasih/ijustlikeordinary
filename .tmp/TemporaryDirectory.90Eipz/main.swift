#sourceLocation(file: "-e", line: 1)

import Foundation
import IOKit.ps
import IOKit

let blob = IOPSCopyPowerSourcesInfo().takeRetainedValue()
let list = IOPSCopyPowerSourcesList(blob).takeRetainedValue() as [CFTypeRef]
for s in list {
    if let desc = IOPSGetPowerSourceDescription(blob, s).takeUnretainedValue() as? [String: Any] {
        print("IOPS:")
        for (k, v) in desc.sorted(by: { $0.key < $1.key }) {
            print("  \(k): \(v)")
        }
    }
}

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
if service != 0 {
    var props: Unmanaged<CFMutableDictionary>?
    if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
       let dict = props?.takeRetainedValue() as? [String: Any] {
        print("\nSmartBattery:")
        for k in ["Amperage", "InstantAmperage", "Voltage", "CurrentCapacity", "MaxCapacity", "DesignCapacity", "TimeRemaining", "AvgTimeToEmpty", "AvgTimeToFull", "ExternalConnected", "IsCharging", "FullyCharged"] {
            print("  \(k): \(dict[k] ?? "nil")")
        }
    }
    IOObjectRelease(service)
}

