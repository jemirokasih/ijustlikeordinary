import Foundation
import CoreGraphics

public final class DisplayBrightnessService {
    public static let shared = DisplayBrightnessService()

    private typealias DSGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DSSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private var getBrightnessFunc: DSGetBrightnessFunc?
    private var setBrightnessFunc: DSSetBrightnessFunc?
    private var originalBrightness: Float?

    private init() {
        setupFunctions()
        captureOriginalBrightness()
    }

    private func setupFunctions() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) {
            if let symGet = dlsym(handle, "DisplayServicesGetBrightness") {
                self.getBrightnessFunc = unsafeBitCast(symGet, to: DSGetBrightnessFunc.self)
            }
            if let symSet = dlsym(handle, "DisplayServicesSetBrightness") {
                self.setBrightnessFunc = unsafeBitCast(symSet, to: DSSetBrightnessFunc.self)
            }
        }
    }

    public func captureOriginalBrightness() {
        if originalBrightness == nil {
            originalBrightness = currentBrightness
        }
    }

    public var currentBrightness: Float {
        guard let getFunc = getBrightnessFunc else { return 0.5 }
        var value: Float = 0.5
        _ = getFunc(CGMainDisplayID(), &value)
        return max(0.0, min(1.0, value))
    }

    @discardableResult
    public func setBrightness(_ value: Float) -> Bool {
        captureOriginalBrightness()
        guard let setFunc = setBrightnessFunc else { return false }
        let clamped = max(0.0, min(1.0, value))
        let result = setFunc(CGMainDisplayID(), clamped)
        return result == 0
    }

    @discardableResult
    public func restoreOriginalBrightness() -> Bool {
        guard let orig = originalBrightness, let setFunc = setBrightnessFunc else { return false }
        let result = setFunc(CGMainDisplayID(), orig)
        originalBrightness = nil
        return result == 0
    }
}
