import Foundation

public struct BatteryProfile: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var description: String
    public var targetRefreshRate: Double?
    public var enableLowPowerMode: Bool
    public var turnOffKeyboardBacklight: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        description: String,
        targetRefreshRate: Double? = nil,
        enableLowPowerMode: Bool = false,
        turnOffKeyboardBacklight: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.targetRefreshRate = targetRefreshRate
        self.enableLowPowerMode = enableLowPowerMode
        self.turnOffKeyboardBacklight = turnOffKeyboardBacklight
    }

    public static let ordinaryTyping = BatteryProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Ordinary Typing",
        icon: "pencil.and.scribble",
        description: "60Hz, Low Power Mode, no keyboard glow",
        targetRefreshRate: 60.0,
        enableLowPowerMode: true,
        turnOffKeyboardBacklight: true
    )

    public static let movieStreaming = BatteryProfile(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        name: "Movie & Stream",
        icon: "film",
        description: "48Hz cinema rate, Low Power Mode",
        targetRefreshRate: 48.0,
        enableLowPowerMode: true,
        turnOffKeyboardBacklight: true
    )

    public static let ultraSaver = BatteryProfile(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        name: "Ultra Saver",
        icon: "leaf.fill",
        description: "Max endurance: 48Hz, Low Power Mode",
        targetRefreshRate: 48.0,
        enableLowPowerMode: true,
        turnOffKeyboardBacklight: true
    )

    public static let fullBeast = BatteryProfile(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        name: "Full Beast",
        icon: "bolt.fill",
        description: "ProMotion 120Hz, full power M1 Max",
        targetRefreshRate: 120.0,
        enableLowPowerMode: false,
        turnOffKeyboardBacklight: false
    )

    public static let defaultPresets: [BatteryProfile] = [
        .ordinaryTyping,
        .movieStreaming,
        .ultraSaver,
        .fullBeast
    ]
}

