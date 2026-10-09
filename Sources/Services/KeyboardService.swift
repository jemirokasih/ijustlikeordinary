import Foundation

public final class KeyboardService {
    public static let shared = KeyboardService()

    private var client: AnyObject?
    private var keyboardIDs: [UInt64] = []
    private var originalBrightness: [UInt64: Float] = [:]

    private init() {
        setupClient()
    }

    private func setupClient() {
        guard let bundle = Bundle(path: "/System/Library/PrivateFrameworks/CoreBrightness.framework") else {
            return
        }
        bundle.load()

        guard let clientClass = NSClassFromString("KeyboardBrightnessClient") as? NSObject.Type else {
            return
        }
        let instance = clientClass.init()
        self.client = instance

        if let ids = instance.perform(Selector(("copyKeyboardBacklightIDs")))?.takeRetainedValue() as? [NSNumber] {
            self.keyboardIDs = ids.map { $0.uint64Value }
        }
    }

    public func captureOriginalBrightness() {
        guard let client = client else { return }
        for id in keyboardIDs {
            if originalBrightness[id] == nil {
                let brightness = getBrightness(for: id, client: client)
                originalBrightness[id] = brightness
            }
        }
    }

    public func getBrightness(for id: UInt64? = nil) -> Float {
        guard let client = client else { return 0.0 }
        let targetID = id ?? keyboardIDs.first ?? 1
        return getBrightness(for: targetID, client: client)
    }

    private func getBrightness(for id: UInt64, client: AnyObject) -> Float {
        let selector = Selector(("brightnessForKeyboard:"))
        guard client.responds(to: selector),
              let method = client.method(for: selector) else {
            return 0.0
        }
        typealias Getter = @convention(c) (AnyObject, Selector, UInt64) -> Float
        let function = unsafeBitCast(method, to: Getter.self)
        return function(client, selector, id)
    }

    public func setBrightness(_ value: Float) {
        guard let client = client else { return }
        captureOriginalBrightness()

        let selector = Selector(("setBrightness:forKeyboard:"))
        guard client.responds(to: selector),
              let method = client.method(for: selector) else {
            return
        }
        typealias Setter = @convention(c) (AnyObject, Selector, Float, UInt64) -> Void
        let function = unsafeBitCast(method, to: Setter.self)

        let targetIDs = keyboardIDs.isEmpty ? [1] : keyboardIDs
        for id in targetIDs {
            function(client, selector, max(0.0, min(1.0, value)), id)
        }
    }

    public func restoreOriginalBrightness() {
        guard let client = client else { return }
        let selector = Selector(("setBrightness:forKeyboard:"))
        guard client.responds(to: selector),
              let method = client.method(for: selector) else {
            return
        }
        typealias Setter = @convention(c) (AnyObject, Selector, Float, UInt64) -> Void
        let function = unsafeBitCast(method, to: Setter.self)

        for (id, val) in originalBrightness {
            function(client, selector, val, id)
        }
        originalBrightness.removeAll()
    }
}

