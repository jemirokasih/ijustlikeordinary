import Foundation

public struct BatteryProfile: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var description: String

    // 4 Core Sliders
    public var processorLevel: Int          // 0: Super Low, 1: Low, 2: Medium, 3: Normal
    public var targetRefreshRate: Double    // 48.0, 50.0, 60.0, 120.0
    public var displayBrightness: Double    // 0.0 ... 1.0
    public var keyboardBrightness: Double   // 0.0 ... 1.0

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        description: String,
        processorLevel: Int = 1,
        targetRefreshRate: Double = 60.0,
        displayBrightness: Double = 0.45,
        keyboardBrightness: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.processorLevel = processorLevel
        self.targetRefreshRate = targetRefreshRate
        self.displayBrightness = displayBrightness
        self.keyboardBrightness = keyboardBrightness
    }

    public static let ordinaryTyping = BatteryProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Ordinary Typing",
        icon: "pencil.and.scribble",
        description: "Super Low CPU, 60Hz, redup & tanpa keyboard",
        processorLevel: 0,
        targetRefreshRate: 60.0,
        displayBrightness: 0.40,
        keyboardBrightness: 0.0
    )

    public static let movieStreaming = BatteryProfile(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        name: "Movie & Stream",
        icon: "film",
        description: "Low CPU, 48Hz cinema rate, layar nyaman",
        processorLevel: 1,
        targetRefreshRate: 48.0,
        displayBrightness: 0.55,
        keyboardBrightness: 0.0
    )

    public static let ultraSaver = BatteryProfile(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        name: "Ultra Saver",
        icon: "leaf.fill",
        description: "Super Low CPU, 48Hz, hemat baterai maksimal",
        processorLevel: 0,
        targetRefreshRate: 48.0,
        displayBrightness: 0.25,
        keyboardBrightness: 0.0
    )

    public static let fullBeast = BatteryProfile(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        name: "Full Beast",
        icon: "bolt.fill",
        description: "Normal CPU, ProMotion 120Hz, daya penuh",
        processorLevel: 3,
        targetRefreshRate: 120.0,
        displayBrightness: 0.80,
        keyboardBrightness: 0.50
    )

    public static let defaultPresets: [BatteryProfile] = [
        .ordinaryTyping,
        .movieStreaming,
        .ultraSaver,
        .fullBeast
    ]
}
