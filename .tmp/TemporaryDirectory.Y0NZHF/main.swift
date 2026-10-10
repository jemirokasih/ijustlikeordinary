#sourceLocation(file: "-e", line: 1)

import Foundation
import IOKit

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
if service != 0 {
    var props: Unmanaged<CFMutableDictionary>?
    if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
       let dict = props?.takeRetainedValue() as? [String: Any] {
        let tr = dict["TimeRemaining"] as? Int ?? -1
        let avg = dict["AvgTimeToEmpty"] as? Int ?? -1
        let isCharging = dict["IsCharging"] as? Bool ?? false
        let ext = dict["ExternalConnected"] as? Bool ?? false
        print("tr:", tr, "avg:", avg, "charging:", isCharging, "ext:", ext)
        
        let batteryMins = (tr > 0 && tr < 65535) ? tr : ((avg > 0 && avg < 65535) ? avg : nil)
        if let mins = batteryMins {
            print("Parsed Time Remaining:", "\(mins / 60) jam \(mins % 60) menit")
        }
    }
    IOObjectRelease(service)
}

