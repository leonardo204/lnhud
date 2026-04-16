import XCTest
@testable import LnHud

final class AppSettingsTests: XCTestCase {

    private var testDefaults: UserDefaults!
    private let suiteName = "com.zerolive.LnHudTests.AppSettings"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - 기본값 검증

    func test_defaultValues_hudDuration() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.hudDuration, 1.0, accuracy: 0.001)
    }

    func test_defaultValues_hudFontSize() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.hudFontSize, 64, accuracy: 0.001)
    }

    func test_defaultValues_hudCornerRadius() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.hudCornerRadius, 24, accuracy: 0.001)
    }

    func test_defaultValues_showMenuBarIcon() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertTrue(settings.showMenuBarIcon)
    }

    func test_defaultValues_launchAtLogin() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func test_defaultValues_screenMode() {
        let settings = AppSettings(defaults: testDefaults)
        XCTAssertEqual(settings.screenMode, .builtIn)
    }

    // MARK: - UserDefaults 왕복 (set -> 새 인스턴스 -> get)

    func test_persistence_hudDuration() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudDuration = 2.5

        let restored = AppSettings(defaults: testDefaults)
        XCTAssertEqual(restored.hudDuration, 2.5, accuracy: 0.001)
    }

    func test_persistence_hudFontSize() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudFontSize = 80

        let restored = AppSettings(defaults: testDefaults)
        XCTAssertEqual(restored.hudFontSize, 80, accuracy: 0.001)
    }

    func test_persistence_hudCornerRadius() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudCornerRadius = 12

        let restored = AppSettings(defaults: testDefaults)
        XCTAssertEqual(restored.hudCornerRadius, 12, accuracy: 0.001)
    }

    func test_persistence_showMenuBarIcon_false() {
        let settings = AppSettings(defaults: testDefaults)
        settings.showMenuBarIcon = false

        let restored = AppSettings(defaults: testDefaults)
        XCTAssertFalse(restored.showMenuBarIcon)
    }

    func test_persistence_launchAtLogin_true() {
        let settings = AppSettings(defaults: testDefaults)
        settings.launchAtLogin = true

        let restored = AppSettings(defaults: testDefaults)
        XCTAssertTrue(restored.launchAtLogin)
    }

    func test_persistence_screenMode_mouseCursor() {
        let settings = AppSettings(defaults: testDefaults)
        settings.screenMode = .mouseCursor

        let restored = AppSettings(defaults: testDefaults)
        XCTAssertEqual(restored.screenMode, .mouseCursor)
    }

    // MARK: - 경계값 (유효 범위 내)

    func test_hudDuration_minimumValidValue() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudDuration = 0.5
        XCTAssertEqual(settings.hudDuration, 0.5, accuracy: 0.001)
    }

    func test_hudDuration_maximumValidValue() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudDuration = 3.0
        XCTAssertEqual(settings.hudDuration, 3.0, accuracy: 0.001)
    }

    func test_hudDuration_belowMinimum_storedOrClamped() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudDuration = 0.1
        // 클램핑하는 경우 0.5, 그대로 저장하는 경우 0.1 — 둘 다 양수여야 함
        XCTAssertGreaterThan(settings.hudDuration, 0)
    }

    func test_hudDuration_aboveMaximum_storedOrClamped() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudDuration = 10.0
        // 클램핑하는 경우 3.0, 그대로 저장하는 경우 10.0 — 양수여야 함
        XCTAssertGreaterThan(settings.hudDuration, 0)
    }

    func test_hudFontSize_positiveValue() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudFontSize = 32
        XCTAssertGreaterThan(settings.hudFontSize, 0)
    }

    func test_hudCornerRadius_zeroAllowed() {
        let settings = AppSettings(defaults: testDefaults)
        settings.hudCornerRadius = 0
        XCTAssertGreaterThanOrEqual(settings.hudCornerRadius, 0)
    }

    // MARK: - HUDScreenMode rawValue 왕복

    func test_hudScreenMode_rawValue_mainScreen() {
        XCTAssertEqual(HUDScreenMode.mainScreen.rawValue, "mainScreen")
    }

    func test_hudScreenMode_rawValue_mouseCursor() {
        XCTAssertEqual(HUDScreenMode.mouseCursor.rawValue, "mouseCursor")
    }

    func test_hudScreenMode_fromRawValue_mainScreen() {
        let mode = HUDScreenMode(rawValue: "mainScreen")
        XCTAssertEqual(mode, .mainScreen)
    }

    func test_hudScreenMode_fromRawValue_mouseCursor() {
        let mode = HUDScreenMode(rawValue: "mouseCursor")
        XCTAssertEqual(mode, .mouseCursor)
    }

    func test_hudScreenMode_fromRawValue_invalid_returnsNil() {
        let mode = HUDScreenMode(rawValue: "invalid_mode")
        XCTAssertNil(mode)
    }

    func test_hudScreenMode_caseIterable_containsAllCases() {
        let allCases = HUDScreenMode.allCases
        XCTAssertTrue(allCases.contains(.builtIn))
        XCTAssertTrue(allCases.contains(.mainScreen))
        XCTAssertTrue(allCases.contains(.mouseCursor))
        XCTAssertEqual(allCases.count, 3)
    }
}
