import Foundation
import CoreGraphics

public final class DisplayService {
    public static let shared = DisplayService()

    private var originalMode: CGDisplayMode?

    private init() {
        captureOriginalMode()
    }

    public func captureOriginalMode() {
        if originalMode == nil {
            originalMode = CGDisplayCopyDisplayMode(CGMainDisplayID())
        }
    }

    public var currentRefreshRate: Double {
        guard let mode = CGDisplayCopyDisplayMode(CGMainDisplayID()) else { return 60.0 }
        return mode.refreshRate
    }

    public var availableRefreshRates: [Double] {
        let displayID = CGMainDisplayID()
        let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let modes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode],
              let current = CGDisplayCopyDisplayMode(displayID) else {
            return [60.0]
        }

        // Filter modes that match current pixel resolution
        let matched = modes.filter {
            $0.pixelWidth == current.pixelWidth && $0.pixelHeight == current.pixelHeight
        }

        let rates = Set(matched.map { round($0.refreshRate) }).sorted()
        return rates.isEmpty ? [current.refreshRate] : rates
    }

    @discardableResult
    public func setRefreshRate(_ targetRate: Double) -> Bool {
        let displayID = CGMainDisplayID()
        captureOriginalMode()

        let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let modes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode],
              let current = CGDisplayCopyDisplayMode(displayID) else {
            return false
        }

        // Find candidate with matching resolution and closest refresh rate
        let candidates = modes.filter {
            $0.pixelWidth == current.pixelWidth && $0.pixelHeight == current.pixelHeight
        }

        guard let targetMode = candidates.first(where: { abs($0.refreshRate - targetRate) < 1.0 }) else {
            return false
        }

        let result = CGDisplaySetDisplayMode(displayID, targetMode, nil)
        return result == .success
    }

    @discardableResult
    public func restoreOriginalRefreshRate() -> Bool {
        guard let original = originalMode else { return false }
        let displayID = CGMainDisplayID()
        let result = CGDisplaySetDisplayMode(displayID, original, nil)
        return result == .success
    }
}

