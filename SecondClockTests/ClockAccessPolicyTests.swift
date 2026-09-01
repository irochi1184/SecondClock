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

        let effective = preferences.applying(accessLevel: .free)

        XCTAssertEqual(effective.gradientStyle, .diagonalDown)
    }

    func testProAccessPreservesEveryPreference() {
        var preferences = ClockPreferences.default
        preferences.fontDesign = .monospaced
        preferences.fontWeight = .bold
        preferences.textColor = RGBAColor(red: 0.8, green: 0.4, blue: 0.2)
        preferences.backgroundStyle = .photo
        preferences.gradientStyle = .radial
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
        XCTAssertFalse(themed.showDate)
        XCTAssertEqual(themed.displaySize, .small)
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
