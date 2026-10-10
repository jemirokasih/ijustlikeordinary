import XCTest
@testable import ijustlikeordinary

final class ijustlikeordinaryTests: XCTestCase {
    func testBatteryProfilePresets() throws {
        let profiles = BatteryProfile.defaultPresets
        XCTAssertEqual(profiles.count, 4)

        let typing = BatteryProfile.ordinaryTyping
        XCTAssertEqual(typing.name, "Ordinary Typing")
        XCTAssertEqual(typing.processorLevel, 0)
        XCTAssertEqual(typing.targetRefreshRate, 60.0)
        XCTAssertEqual(typing.displayBrightness, 0.40)
        XCTAssertEqual(typing.keyboardBrightness, 0.0)
    }

    func testBatteryProfileCodable() throws {
        let profile = BatteryProfile(
            name: "Custom Test",
            icon: "star",
            description: "Test description",
            processorLevel: 1,
            targetRefreshRate: 50.0,
            displayBrightness: 0.50,
            keyboardBrightness: 0.20
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BatteryProfile.self, from: data)

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.processorLevel, 1)
        XCTAssertEqual(decoded.targetRefreshRate, 50.0)
        XCTAssertEqual(decoded.displayBrightness, 0.50)
        XCTAssertEqual(decoded.keyboardBrightness, 0.20)
    }

    func testDisplayServiceRates() throws {
        let rates = DisplayService.shared.availableRefreshRates
        XCTAssertFalse(rates.isEmpty)
        XCTAssertGreaterThan(DisplayService.shared.currentRefreshRate, 0.0)
    }

    func testDisplayBrightnessService() throws {
        let brightness = DisplayBrightnessService.shared.currentBrightness
        XCTAssertGreaterThanOrEqual(brightness, 0.0)
        XCTAssertLessThanOrEqual(brightness, 1.0)
    }

    func testBatteryMonitorCalculation() throws {
        let monitor = BatteryMonitorService.shared
        monitor.refresh()
        XCTAssertGreaterThanOrEqual(monitor.percentage, 0)
        XCTAssertLessThanOrEqual(monitor.percentage, 100)
        XCTAssertFalse(monitor.formattedEstimate.isEmpty)
    }

    func testBatteryHealthService() throws {
        let health = BatteryHealthService.shared
        XCTAssertGreaterThan(health.maximumCapacity, 0)
        XCTAssertGreaterThanOrEqual(health.targetLimit, 70)
        XCTAssertLessThanOrEqual(health.targetLimit, 100)
    }
}
