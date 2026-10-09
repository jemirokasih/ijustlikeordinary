import XCTest
@testable import ijustlikeordinary

final class ijustlikeordinaryTests: XCTestCase {
    func testBatteryProfilePresets() throws {
        let profiles = BatteryProfile.defaultPresets
        XCTAssertEqual(profiles.count, 4)

        let typing = BatteryProfile.ordinaryTyping
        XCTAssertEqual(typing.name, "Ordinary Typing")
        XCTAssertEqual(typing.targetRefreshRate, 60.0)
        XCTAssertTrue(typing.enableLowPowerMode)
        XCTAssertTrue(typing.turnOffKeyboardBacklight)
    }

    func testBatteryProfileCodable() throws {
        let profile = BatteryProfile(
            name: "Custom Test",
            icon: "star",
            description: "Test description",
            targetRefreshRate: 50.0,
            enableLowPowerMode: true,
            turnOffKeyboardBacklight: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BatteryProfile.self, from: data)

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.targetRefreshRate, 50.0)
        XCTAssertTrue(decoded.enableLowPowerMode)
        XCTAssertFalse(decoded.turnOffKeyboardBacklight)
    }

    func testDisplayServiceRates() throws {
        let rates = DisplayService.shared.availableRefreshRates
        XCTAssertFalse(rates.isEmpty)
        XCTAssertGreaterThan(DisplayService.shared.currentRefreshRate, 0.0)
    }

    func testBatteryMonitorReadsValues() throws {
        let monitor = BatteryMonitorService.shared
        monitor.refresh()
        XCTAssertGreaterThanOrEqual(monitor.percentage, 0)
        XCTAssertLessThanOrEqual(monitor.percentage, 100)
    }
}

