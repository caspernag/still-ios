import DesignSystem
import StillKit
import StoreKit
import SwiftUI

/// Chooses between onboarding, the no-access screen and the main flow,
/// and hosts the app-wide sheets, covers and dialogs.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(Entitlements.self) private var entitlements

    var body: some View {
        @Bindable var model = model

        ZStack {
            switch model.phase {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .onboardingChooseApps:
                ChooseAppsView(isOnboarding: true)
                    .transition(.opacity)
            case .noAccess:
                NoAccessView()
                    .transition(.opacity)
            case .main:
                MainStack()
                    .transition(.opacity)
            }

            if let record = model.endedEarly {
                EndedEarlyDialog(record: record)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.phase)
        .animation(.easeInOut(duration: 0.2), value: model.endedEarly)
        .tint(StillColor.ink)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .sheet(item: $model.sheet, onDismiss: nil) { sheet in
            switch sheet {
            case .paywall:
                PaywallView()
                    .onDisappear { model.sheetDismissed(.paywall) }
            case .customDuration:
                CustomDurationSheet(initialMinutes: model.settings.durationMinutes)
                    .presentationDetents([.height(470), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(StillRadius.sheet)
                    .presentationBackground(StillColor.background)
            }
        }
        .fullScreenCover(item: $model.completion, onDismiss: { model.completionDismissed() }) { record in
            SessionCompleteView(record: record)
        }
        .alert(
            Text("Something went wrong"),
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            ),
            presenting: model.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .onChange(of: entitlements.status) { _, _ in model.entitlementsChanged() }
        .onChange(of: entitlements.isLoaded) { _, _ in model.entitlementsChanged() }
        .onAppear { model.becameActive() }
        #if DEBUG
        .preferredColorScheme(model.config.forceDark ? .dark : nil)
        #endif
    }
}

/// Home (or the running Session) with pushes to Settings, Schedules, Insights and Choose apps.
private struct MainStack: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $model.path) {
            Group {
                if model.activeSession != nil {
                    SessionView()
                        .transition(.opacity)
                } else {
                    HomeView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: model.activeSession)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppModel.Route.self) { route in
                Group {
                    switch route {
                    case .settings: SettingsView()
                    case .schedules: SchedulesView()
                    case .insights: InsightsView()
                    case .chooseApps: ChooseAppsView(isOnboarding: false)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        #if DEBUG
        .overlay {
            DemoScreenOverlay()
        }
        #endif
    }
}

/// Re-enables the swipe-back gesture while the navigation bar is hidden.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
