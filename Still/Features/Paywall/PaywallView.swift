import DesignSystem
import StillKit
import StoreKit
import SwiftUI

/// Screen 6: the design's header as marketing content of Apple's SubscriptionStoreView.
/// StoreKit renders the plans, prices, the 7-day free trial terms, restore and the policy links.
struct PaywallView: View {
    @Environment(Entitlements.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubscriptionStoreView(productIDs: StillConstants.Products.all) {
            PaywallHeader(isTrialEligible: entitlements.isTrialEligible)
        }
        .subscriptionStoreControlStyle(.picker)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .policies)
        .storeButton(.hidden, for: .cancellation)
        .subscriptionStorePolicyDestination(url: StillConstants.termsURL, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: StillConstants.privacyURL, for: .privacyPolicy)
        .subscriptionStorePolicyForegroundStyle(StillColor.ink)
        .tint(StillColor.ink)
        .containerBackground(StillColor.background, for: .subscriptionStoreFullHeight)
        .background(StillColor.background.ignoresSafeArea())
        .onInAppPurchaseCompletion { _, result in
            guard case .success(.success(let verification)) = result else { return }
            if case .verified(let transaction) = verification {
                await transaction.finish()
            }
            await entitlements.refresh()
            dismiss()
        }
        .overlay(alignment: .topTrailing) {
            CloseButton { dismiss() }
                .padding(.trailing, 14)
                .padding(.top, 10)
        }
    }
}

/// Icon, "Get your time back.", "Try Still Pro free for 7 days." and the three Pro features.
private struct PaywallHeader: View {
    let isTrialEligible: Bool

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 18) {
                LogoEmblem(diameter: 76, dot: 16, halo: 8)
                    .padding(.top, 8)
                VStack(spacing: 6) {
                    Text("Get your time back.")
                        .stillFont(.paywallTitle)
                        .foregroundStyle(StillColor.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    (isTrialEligible ? Text("Try Still Pro free for 7 days.") : Text("Unlock everything in Still Pro."))
                        .stillFont(.subheadline)
                        .foregroundStyle(StillColor.inkSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            StillCard {
                VStack(spacing: 0) {
                    feature("clock", "Schedules that lock apps automatically")
                    StillDivider(leadingInset: 56)
                    feature("lock", "Strict mode: no ending early")
                    StillDivider(leadingInset: 56)
                    feature("chart.bar", "Weekly insights")
                    StillDivider(leadingInset: 56)
                    feature("timer", "Custom session lengths")
                }
            }
        }
        .padding(.horizontal, StillSpacing.screen)
        .padding(.top, 36)
        .padding(.bottom, 8)
    }

    private func feature(_ symbol: String, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            StillTile(size: 28, radius: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(title)
                .stillFont(.subheadline)
                .foregroundStyle(StillColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, StillSpacing.rowHorizontal)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
