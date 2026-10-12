import DesignSystem
import StillKit
import StoreKit
import SwiftUI

/// Screen 10: Settings.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(Entitlements.self) private var entitlements
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dismiss) private var dismiss
    @State private var showManageSubscriptions = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    var body: some View {
        StillScreen(spacing: 20) {
            StillTopBar {
                CircleIconButton(systemImage: "chevron.left", accessibilityLabel: "Back") {
                    dismiss()
                }
                .accessibilityIdentifier("backButton")
            }

            Text("Settings")
                .stillFont(.title)
                .foregroundStyle(StillColor.ink)
                .accessibilityAddTraits(.isHeader)

            section("Subscription") {
                VStack(spacing: 0) {
                    subscriptionRow
                    StillDivider(leadingInset: 58)
                    Button {
                        Task { await restore() }
                    } label: {
                        Text("Restore purchases")
                            .stillFont(.callout)
                            .foregroundStyle(StillColor.ink)
                            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                            .padding(.leading, 58)
                            .padding(.trailing, StillSpacing.rowHorizontal)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isRestoring)
                    .accessibilityIdentifier("restorePurchases")
                }
            }

            section("Sessions") {
                VStack(spacing: 0) {
                    Button {
                        model.openSchedules()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Schedules")
                                .stillFont(.callout)
                                .foregroundStyle(StillColor.ink)
                            Spacer(minLength: 8)
                            Text(schedulesSummary)
                                .stillFont(.subheadline)
                                .foregroundStyle(StillColor.inkSecondary)
                                .lineLimit(1)
                            if !entitlements.canUse(.schedules) {
                                StillBadge("Pro")
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(StillColor.inkMuted)
                        }
                        .padding(.horizontal, StillSpacing.rowHorizontal)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("schedulesRow")

                    StillDivider()

                    Toggle(isOn: Binding(
                        get: { model.isStrictModeEffective },
                        set: { model.setStrictMode($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text("Strict mode")
                                    .stillFont(.callout)
                                    .foregroundStyle(StillColor.ink)
                                if !entitlements.canUse(.strictMode) {
                                    StillBadge("Pro")
                                }
                            }
                            Text("No way to end a session early")
                                .stillFont(.caption)
                                .foregroundStyle(StillColor.inkSecondary)
                        }
                    }
                    .stillToggleTint()
                    .padding(.horizontal, StillSpacing.rowHorizontal)
                    .frame(minHeight: 52)
                    .disabled(model.activeSession != nil)
                    .accessibilityIdentifier("strictModeToggle")

                    StillDivider()

                    Toggle(isOn: Binding(
                        get: { model.settings.notifyWhenDone },
                        set: { model.setNotifyWhenDone($0) }
                    )) {
                        Text("Notify when done")
                            .stillFont(.callout)
                            .foregroundStyle(StillColor.ink)
                    }
                    .stillToggleTint()
                    .padding(.horizontal, StillSpacing.rowHorizontal)
                    .frame(minHeight: 52)
                    .accessibilityIdentifier("notifyToggle")
                }
            }

            section("About") {
                VStack(spacing: 0) {
                    linkRow("Privacy") { openURL(StillConstants.privacyURL) }
                    StillDivider()
                    linkRow("Terms") { openURL(StillConstants.termsURL) }
                    StillDivider()
                    linkRow("Contact") {
                        if let url = URL(string: "mailto:\(StillConstants.supportEmail)?subject=Still") {
                            openURL(url)
                        }
                    }
                    StillDivider()
                    linkRow("Rate Still") { rate() }
                }
            }

            Spacer(minLength: 8)

            Text("Still \(appVersion) · Made in Bergen")
                .stillFont(.caption)
                .foregroundStyle(StillColor.inkSecondary)
                .frame(maxWidth: .infinity)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .alert(
            Text("Restore purchases"),
            isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } }),
            presenting: restoreMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: Rows

    private var subscriptionRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: StillRadius.tile, style: .continuous)
                .fill(StillColor.logo)
                .frame(width: 30, height: 30)
                .overlay(Circle().fill(StillColor.accent).frame(width: 8, height: 8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "Still Pro")
                    .stillFont(.calloutMedium)
                    .foregroundStyle(StillColor.ink)
                Text(statusText)
                    .stillFont(.footnote)
                    .foregroundStyle(StillColor.inkSecondary)
            }
            Spacer(minLength: 8)
            Button {
                if entitlements.isPro {
                    showManageSubscriptions = true
                } else {
                    model.sheet = .paywall
                }
            } label: {
                (entitlements.isPro ? Text("Manage") : (entitlements.isTrialEligible ? Text("Try free") : Text("Upgrade")))
                    .stillFont(.subheadline)
                    .foregroundStyle(StillColor.ink)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("manageSubscription")
        }
        .padding(.horizontal, StillSpacing.rowHorizontal)
        .padding(.vertical, 4)
    }

    private var statusText: String {
        switch entitlements.status {
        case .trial(let days):
            days == 1 ? String(localized: "Free trial · 1 day left") : String(localized: "Free trial · \(days) days left")
        case .active:
            String(localized: "Active")
        case .free, .expired:
            entitlements.isTrialEligible ? String(localized: "Try it free for 7 days") : String(localized: "Not subscribed")
        }
    }

    private var schedulesSummary: String {
        let enabled = model.schedules.filter(\.isEnabled)
        if !entitlements.canUse(.schedules) || enabled.isEmpty { return String(localized: "Off") }
        if enabled.count == 1 { return enabled[0].name }
        return String(localized: "\(enabled.count) on")
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StillSectionHeader(title)
            StillCard { content() }
        }
    }

    private func linkRow(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .stillFont(.callout)
                .foregroundStyle(StillColor.ink)
                .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                .padding(.horizontal, StillSpacing.rowHorizontal)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Opens the App Store review page once the app's App Store ID is set;
    /// until then (e.g. TestFlight) falls back to the in-app prompt.
    private func rate() {
        if let id = StillConstants.appStoreID,
           let url = URL(string: "https://apps.apple.com/app/id\(id)?action=write-review") {
            openURL(url)
        } else {
            requestReview()
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await entitlements.refresh()
            restoreMessage = entitlements.isPro
                ? String(localized: "Still Pro is active.")
                : String(localized: "No active subscription was found for this Apple Account.")
        } catch {
            restoreMessage = String(localized: "Couldn't reach the App Store. Please try again.")
        }
    }
}
