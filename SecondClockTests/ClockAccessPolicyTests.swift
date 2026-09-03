import StoreKit
import StoreKitTest
import XCTest
@testable import SecondClock

final class ClockAccessPolicyTests: XCTestCase {
    func testFreeAccessKeepsBasicOptions() {
        var preferences = ClockPreferences.default
        preferences.displaySize = .large
        preferences.fontDesign = .standard
        preferences.fontWeight = .regular
        preferences.backgroundStyle = .solid

        let effective = preferences.applying(accessLevel: .free)

        XCTAssertEqual(effective.displaySize, .large)
        XCTAssertEqual(effective.fontDesign, .standard)
        XCTAssertEqual(effective.fontWeight, .regular)
        XCTAssertEqual(effective.backgroundStyle, .solid)
        XCTAssertEqual(effective.solidColor, .midnight)
    }

    func testFreeAccessPreservesTypographyAndColors() {
        var preferences = ClockPreferences.default
        preferences.fontDesign = .serif
        preferences.fontWeight = .bold
        preferences.textColor = RGBAColor(red: 1, green: 0, blue: 0)
        preferences.backgroundStyle = .gradient
        preferences.gradientStartColor = RGBAColor(red: 0, green: 1, blue: 0)
        preferences.gradientEndColor = RGBAColor(red: 0, green: 0, blue: 0)
        preferences.backgroundMotion = .none

        let effective = preferences.applying(accessLevel: .free)

        XCTAssertEqual(effective, preferences)
    }

    func testFreeAccessReplacesPhotoWithDefaultGradient() {
        var preferences = ClockPreferences.default
        preferences.backgroundStyle = .photo

        let effective = preferences.applying(accessLevel: .free)

        XCTAssertEqual(effective.backgroundStyle, .gradient)
        XCTAssertEqual(
            effective.gradientStartColor,
            ClockPreferences.default.gradientStartColor
        )
        XCTAssertEqual(
            effective.gradientEndColor,
            ClockPreferences.default.gradientEndColor
        )
    }

    func testFreeAccessUsesDefaultGradientStyle() {
        var preferences = ClockPreferences.default
        preferences.gradientStyle = .radial
        preferences.backgroundMotion = .aurora

        let effective = preferences.applying(accessLevel: .free)

        XCTAssertEqual(effective.gradientStyle, .diagonalDown)
        XCTAssertEqual(effective.backgroundMotion, .none)
    }

    func testProAccessPreservesEveryPreference() {
        var preferences = ClockPreferences.default
        preferences.fontDesign = .monospaced
        preferences.fontWeight = .bold
        preferences.textColor = RGBAColor(red: 0.8, green: 0.4, blue: 0.2)
        preferences.backgroundStyle = .photo
        preferences.gradientStyle = .radial
        preferences.backgroundMotion = .waves
        preferences.animationSpeed = 1.8
        preferences.animationIntensity = 0.9
        preferences.photoDimming = 0.6

        XCTAssertEqual(
            preferences.applying(accessLevel: .pro),
            preferences
        )
    }

    func testThemePresetAppliesGradientWithoutChangingDisplaySettings() {
        var preferences = ClockPreferences.default
        preferences.showDate = false
        preferences.displaySize = .small

        let themed = ClockThemePreset.aurora.applying(to: preferences)

        XCTAssertEqual(themed.backgroundStyle, .gradient)
        XCTAssertEqual(themed.gradientStartColor, ClockThemePreset.aurora.colors[0])
        XCTAssertEqual(themed.gradientEndColor, ClockThemePreset.aurora.colors[1])
        XCTAssertEqual(themed.textColor, .white)
        XCTAssertEqual(themed.backgroundMotion, .aurora)
        XCTAssertFalse(themed.showDate)
        XCTAssertEqual(themed.displaySize, .small)
    }

    func testThemePresetsSelectMatchingAnimation() {
        let preferences = ClockPreferences.default

        XCTAssertEqual(
            ClockThemePreset.aurora.applying(to: preferences).backgroundMotion,
            .aurora
        )
        XCTAssertEqual(
            ClockThemePreset.ocean.applying(to: preferences).backgroundMotion,
            .waves
        )
        XCTAssertEqual(
            ClockThemePreset.sunset.applying(to: preferences).backgroundMotion,
            .flowingGradient
        )
    }

    func testLegacyPreferencesDecodeWithAnimationDefaults() throws {
        let encoded = try JSONEncoder().encode(ClockPreferences.default)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "backgroundMotion")
        object.removeValue(forKey: "animationSpeed")
        object.removeValue(forKey: "animationIntensity")
        object.removeValue(forKey: "layoutStyle")
        object.removeValue(forKey: "keepsScreenAwake")
        object.removeValue(forKey: "nightMode")
        object.removeValue(forKey: "nightStartMinutes")
        object.removeValue(forKey: "nightEndMinutes")
        object.removeValue(forKey: "nightTextIntensity")
        object.removeValue(forKey: "burnInProtection")

        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(ClockPreferences.self, from: legacyData)

        XCTAssertEqual(decoded.backgroundMotion, ClockPreferences.default.backgroundMotion)
        XCTAssertEqual(decoded.animationSpeed, ClockPreferences.default.animationSpeed)
        XCTAssertEqual(decoded.animationIntensity, ClockPreferences.default.animationIntensity)
        XCTAssertEqual(decoded.layoutStyle, .classic)
        XCTAssertTrue(decoded.keepsScreenAwake)
        XCTAssertEqual(decoded.nightMode, .off)
        XCTAssertTrue(decoded.burnInProtection)
    }

    func testFreeAccessFallsBackFromProDesignAndScheduledNightMode() {
        var preferences = ClockPreferences.default
        preferences.layoutStyle = .secondsRing
        preferences.nightMode = .scheduled

        let effective = preferences.applying(accessLevel: .free)

        XCTAssertEqual(effective.layoutStyle, .classic)
        XCTAssertEqual(effective.nightMode, .off)
    }

    func testNightModeScheduleAcrossMidnight() throws {
        var preferences = ClockPreferences.default
        preferences.nightMode = .scheduled
        preferences.nightStartMinutes = 22 * 60
        preferences.nightEndMinutes = 7 * 60
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        let lateNight = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 23))
        )
        let earlyMorning = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 6))
        )
        let daytime = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 12))
        )

        XCTAssertTrue(preferences.isNightModeActive(at: lateNight, calendar: calendar))
        XCTAssertTrue(preferences.isNightModeActive(at: earlyMorning, calendar: calendar))
        XCTAssertFalse(preferences.isNightModeActive(at: daytime, calendar: calendar))
    }

    func testPresetScheduleSelectsDayAndNightPreset() throws {
        let dayID = UUID()
        let nightID = UUID()
        let schedule = ClockPresetSchedule(
            isEnabled: true,
            dayPresetID: dayID,
            nightPresetID: nightID,
            dayStartMinutes: 7 * 60,
            nightStartMinutes: 22 * 60
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let noon = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))
        )
        let midnight = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 0))
        )

        XCTAssertEqual(schedule.presetID(at: noon, calendar: calendar), dayID)
        XCTAssertEqual(schedule.presetID(at: midnight, calendar: calendar), nightID)
    }

    func testThemePresetAccessLevels() {
        XCTAssertFalse(ClockThemePreset.aurora.requiresPro)
        XCTAssertFalse(ClockThemePreset.ocean.requiresPro)
        XCTAssertTrue(ClockThemePreset.sunset.requiresPro)
        XCTAssertTrue(ClockThemePreset.sakura.requiresPro)
        XCTAssertTrue(ClockThemePreset.nightSky.requiresPro)
    }

    func testFreePresetLimitAndUnlimitedProAccess() {
        XCTAssertTrue(
            ClockPresetAccessPolicy.canCreatePreset(
                currentCount: 2,
                isProUnlocked: false
            )
        )
        XCTAssertFalse(
            ClockPresetAccessPolicy.canCreatePreset(
                currentCount: 3,
                isProUnlocked: false
            )
        )
        XCTAssertTrue(
            ClockPresetAccessPolicy.canCreatePreset(
                currentCount: 100,
                isProUnlocked: true
            )
        )
    }

    func testPresetCollectionUsesSelectedPreferences() throws {
        var firstPreferences = ClockPreferences.default
        firstPreferences.displaySize = .small
        var secondPreferences = ClockPreferences.default
        secondPreferences.displaySize = .large

        let first = ClockPreset(name: "プリセット 1", preferences: firstPreferences)
        let second = ClockPreset(name: "プリセット 2", preferences: secondPreferences)
        let collection = ClockPresetCollection(
            presets: [first, second],
            activePresetID: second.id
        )

        XCTAssertEqual(collection.activePreferences.displaySize, .large)

        let data = try JSONEncoder().encode(collection)
        let decoded = try JSONDecoder().decode(ClockPresetCollection.self, from: data)
        XCTAssertEqual(decoded, collection)
    }

    @MainActor
    func testPresetStoreCapsFreeCreationAndUpdatesSharedPreferences() {
        let store = ClockSettingsStore()
        store.restoreDefaults()
        let firstPresetID = store.activePresetID
        store.preferences.displaySize = .small

        XCTAssertTrue(store.addPreset(isProUnlocked: false))
        XCTAssertTrue(store.addPreset(isProUnlocked: false))
        XCTAssertFalse(store.addPreset(isProUnlocked: false))
        XCTAssertEqual(store.presets.count, ClockPresetAccessPolicy.freeLimit)

        store.preferences.displaySize = .large
        XCTAssertTrue(store.selectAdjacentPreset(forward: true))
        XCTAssertEqual(store.activePresetID, firstPresetID)
        XCTAssertEqual(store.preferences.displaySize, .small)
        XCTAssertEqual(SharedClockStorage.loadPreferences(), store.preferences)

        store.restoreDefaults()
    }

    @MainActor
    func testStoreKitConfigurationProvidesLifetimeProProduct() async throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let configurationURL = repositoryRoot
            .appendingPathComponent("SecondClock/SecondClock.storekit")

        let session = try SKTestSession(contentsOf: configurationURL)
        session.disableDialogs = true
        session.clearTransactions()

        let products = try await Product.products(for: [PurchaseManager.proProductID])
        let product = try XCTUnwrap(products.first)

        XCTAssertEqual(product.id, PurchaseManager.proProductID)
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertFalse(product.displayPrice.isEmpty)
    }
}
