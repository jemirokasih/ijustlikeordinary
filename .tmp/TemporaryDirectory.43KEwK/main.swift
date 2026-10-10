#sourceLocation(file: "-e", line: 1)

import Foundation
import IOKit

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
if service != 0 {
    var props: Unmanaged<CFMutableDictionary>?
    if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
       let dict = props?.takeRetainedValue() as? [String: Any] {
        let timeRemaining = dict["TimeRemaining"] as? Int ?? -1
        let isCharging = dict["IsCharging"] as? Bool ?? false
        let extConnected = dict["ExternalConnected"] as? Bool ?? false
        print("TimeRemaining:", timeRemaining, "mins (\(timeRemaining / 60)h \(timeRemaining % 60)m)")
        print("ExternalConnected:", extConnected)
        print("IsCharging:", isCharging)
    }
    IOObjectRelease(service)
}

