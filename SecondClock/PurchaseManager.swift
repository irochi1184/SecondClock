import StoreKit
import SwiftUI
import WidgetKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let proProductID = "com.irochi.SecondClock.pro.lifetime"

    enum Activity: Equatable {
        case idle
        case loadingProduct
        case purchasing
        case pending
        case restoring
    }

    @Published private(set) var proProduct: Product?
    @Published private(set) var isProUnlocked: Bool
    @Published private(set) var activity: Activity = .idle
    @Published private(set) var productLoadErrorMessage: String?
    @Published var errorMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?
    private var hasStarted = false
    private let screenshotPrice: String?
    private let isScreenshotSession: Bool

    init() {
        #if DEBUG && targetEnvironment(simulator)
        let environment = ProcessInfo.processInfo.environment
        screenshotPrice = environment["SECOND_CLOCK_SCREENSHOT_PRICE"]
        isScreenshotSession = environment["SECOND_CLOCK_SCREENSHOT_MODE"] != nil
        isProUnlocked = environment["SECOND_CLOCK_SCREENSHOT_PRO"] == "1"
            || SharedClockStorage.isProEntitlementCached
        #else
        screenshotPrice = nil
        isScreenshotSession = false
        isProUnlocked = SharedClockStorage.isProEntitlementCached
        #endif
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var displayPrice: String? {
        screenshotPrice ?? proProduct?.displayPrice
    }

    var isBusy: Bool {
        switch activity {
        case .loadingProduct, .purchasing, .restoring:
            true
        case .idle, .pending:
            false
        }
    }

    func start() async {
        guard !isScreenshotSession else { return }

        if !hasStarted {
            hasStarted = true
            observeTransactionUpdates()
        }

        await refreshEntitlements()
        await loadProduct()
    }

    func refreshEntitlements() async {
        var hasProEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.proProductID,
                  transaction.revocationDate == nil
            else {
                continue
            }

            hasProEntitlement = true
            break
        }

        updateEntitlement(hasProEntitlement)
    }

    func loadProduct() async {
        guard !isScreenshotSession else { return }
        guard proProduct == nil else { return }

        let previousActivity = activity
        activity = .loadingProduct
        productLoadErrorMessage = nil

        do {
            proProduct = try await Product.products(for: [Self.proProductID]).first

            if proProduct == nil {
                productLoadErrorMessage = PurchaseError.productUnavailable.localizedDescription
            }
        } catch {
            productLoadErrorMessage = "商品情報を取得できませんでした。通信状態を確認して、もう一度お試しください。"
        }

        activity = previousActivity == .pending ? .pending : .idle
    }

    @discardableResult
    func purchasePro() async -> Bool {
        guard let proProduct else {
            await loadProduct()
            if self.proProduct == nil {
                errorMessage = PurchaseError.productUnavailable.localizedDescription
                return false
            }
            return await purchasePro()
        }

        activity = .purchasing
        errorMessage = nil

        do {
            let result = try await proProduct.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try verified(verificationResult)
                guard transaction.productID == Self.proProductID else {
                    throw PurchaseError.unexpectedProduct
                }

                updateEntitlement(true)
                await transaction.finish()
                activity = .idle
                return true

            case .pending:
                activity = .pending
                return false

            case .userCancelled:
                activity = .idle
                return false

            @unknown default:
                activity = .idle
                return false
            }
        } catch {
            activity = .idle
            errorMessage = "購入を完了できませんでした。\(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        activity = .restoring
        errorMessage = nil

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            activity = .idle

            if !isProUnlocked {
                errorMessage = PurchaseError.noPurchaseToRestore.localizedDescription
            }

            return isProUnlocked
        } catch {
            activity = .idle
            errorMessage = "購入を復元できませんでした。\(error.localizedDescription)"
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func observeTransactionUpdates() {
        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }

                if case .verified(let transaction) = result,
                   transaction.productID == Self.proProductID
                {
                    await self.refreshEntitlements()
                    if self.activity == .pending {
                        self.activity = .idle
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func updateEntitlement(_ isUnlocked: Bool) {
        guard isProUnlocked != isUnlocked
                || SharedClockStorage.isProEntitlementCached != isUnlocked
        else {
            return
        }

        isProUnlocked = isUnlocked
        SharedClockStorage.cacheProEntitlement(isUnlocked)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedClockStorage.widgetKind)
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            value
        case .unverified:
            throw PurchaseError.failedVerification
        }
    }
}

private enum PurchaseError: LocalizedError {
    case productUnavailable
    case failedVerification
    case unexpectedProduct
    case noPurchaseToRestore

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            "商品情報を取得できませんでした。しばらくしてからもう一度お試しください。"
        case .failedVerification:
            "購入情報を確認できませんでした。"
        case .unexpectedProduct:
            "購入した商品を確認できませんでした。"
        case .noPurchaseToRestore:
            "復元できる購入履歴が見つかりませんでした。"
        }
    }
}
