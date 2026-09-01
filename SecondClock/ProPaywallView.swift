import SwiftUI

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    features
                    purchaseControls
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("SecondClock Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert(
                "購入情報",
                isPresented: Binding(
                    get: { purchaseManager.errorMessage != nil },
                    set: { if !$0 { purchaseManager.clearError() } }
                )
            ) {
                Button("閉じる", role: .cancel) {
                    purchaseManager.clearError()
                }
            } message: {
                Text(purchaseManager.errorMessage ?? "不明なエラーです。")
            }
            .task {
                if purchaseManager.proProduct == nil {
                    await purchaseManager.loadProduct()
                }
            }
            .onChange(of: purchaseManager.isProUnlocked) { _, isUnlocked in
                if isUnlocked {
                    dismiss()
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 84, height: 84)
                .background(.yellow.opacity(0.13), in: Circle())

            Text("時計を、もっと自分らしく")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("一度の購入ですべてのPro機能を利用できます。月額料金はありません。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProFeatureRow(icon: "photo.fill", title: "写真を時計の背景に設定")
            ProFeatureRow(icon: "slider.horizontal.3", title: "背景写真の暗さを調整")
            ProFeatureRow(icon: "circle.lefthalf.filled", title: "グラデーションの種類を5種類から選択")
            ProFeatureRow(icon: "sparkles", title: "夕焼け・桜・夜空の限定テーマ")
            ProFeatureRow(icon: "rectangle.3.group.fill", title: "ホーム画面ウィジェットにも写真背景を反映")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private var purchaseControls: some View {
        VStack(spacing: 14) {
            if purchaseManager.isProUnlocked {
                Label("SecondClock Pro 購入済み", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if let price = purchaseManager.displayPrice {
                Button {
                    Task {
                        if await purchaseManager.purchasePro() {
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if purchaseManager.activity == .purchasing {
                            ProgressView()
                                .tint(.white)
                        }

                        Text("買い切りで購入 – \(price)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(purchaseManager.isBusy)
            } else {
                Button {
                    Task { await purchaseManager.loadProduct() }
                } label: {
                    HStack(spacing: 10) {
                        if purchaseManager.activity == .loadingProduct {
                            ProgressView()
                        }
                        Text("商品情報を再読み込み")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(purchaseManager.isBusy)

                if let message = purchaseManager.productLoadErrorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if purchaseManager.activity == .pending {
                Label("購入は承認待ちです。承認後に自動で反映されます。", systemImage: "hourglass")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("購入を復元") {
                Task {
                    if await purchaseManager.restorePurchases() {
                        dismiss()
                    }
                }
            }
            .disabled(purchaseManager.isBusy)

            Text("購入はApple IDに紐づきます。サブスクリプションではありません。")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        Label {
            Text(title)
                .font(.subheadline.weight(.medium))
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
        }
    }
}
