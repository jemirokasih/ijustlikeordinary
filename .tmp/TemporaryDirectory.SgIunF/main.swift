#sourceLocation(file: "-e", line: 1)

import Foundation
import IOKit

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
if service != 0 {
    var props: Unmanaged<CFMutableDictionary>?
    if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
       let dict = props?.takeRetainedValue() as? [String: Any] {
        for (k, v) in dict.sorted(by: { $0.key < $1.key }) {
            print("\(k): \(v)")
        }
    }
    IOObjectRelease(service)
}

