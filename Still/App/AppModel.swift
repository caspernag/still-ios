import FamilyControls
import Foundation
import Observation
import StillKit

/// App state and the session flow. Views read from here and call its methods.
@Observable
@MainActor
final class AppModel {
    enum Phase: Equatable {
        /// Screen 1: "Your phone, quieter."
        case onboarding
        /// Screen 3 as step 2 of onboarding.
        case onboardingChooseApps
        /// Screen 11: authorization denied or revoked.
        case noAccess
        /// Home / Session and everything reachable from them.
        case main
    }

    enum Route: Hashable {
        case settings
        case schedules
        case insights
        case chooseApps
    }

    enum Sheet: String, Identifiable {
        case paywall
        case customDuration
        var id: String { rawValue }
    }

    // MARK: Dependencies

    let config: LaunchConfiguration
    let store: SharedStore
    let clock: AppClock
    let entitlements: Entitlements
    let screenTime: ScreenTimeService
    let liveActivities = LiveActivityService()
    let notifications = NotificationService()
    var calendar: Calendar { .current }
    private var engine: SessionEngine { SessionEngine(store: store) }

    // MARK: State mirrored from the shared store

    private(set) var activeSession: Session?
    private(set) var history: [SessionRecord] = []
    private(set) var settings: StillSettings
    private(set) var flags: StillFlags
    private(set) var schedules: [StillSchedule] = []
    private(set) var selection = FamilyActivitySelection(includeEntireCategory: true)
    private(set) var selectionSummary = SelectionSummary()
    private(set) var authorization: ScreenTimeAuthorization = .notDetermined
    private(set) var urgesThisSession = 0
    private var hasRequestedAuthorization = false
    /// False for a moment after launch, while Screen Time reports its status.
    private var authorizationSettled = false

    // MARK: Presentation

    var path: [Route] = []
    var sheet: Sheet?
    /// The completed session shown on "Session complete".
    var completion: SessionRecord?
    /// The session shown in the "Session ended" dialog.
    var endedEarly: SessionRecord?
    var errorMessage: String?
    /// Start a session as soon as the user finishes choosing apps.
    private var startAfterChoosingApps = false
    /// Start a session when the automatic paywall closes ("Go again").
    private var startAfterPaywall = false
    /// Start a session once "Session complete" has finished dismissing.
    private var startAfterCompletion = false

    init(config: LaunchConfiguration = .current) {
        self.config = config
        clock = AppClock()

        #if DEBUG
        if config.isDemo {
            let defaults = UserDefaults(suiteName: "still.demo")!
            let demoStore = SharedStore(defaults: defaults)
            demoStore.reset()
            store = demoStore
            screenTime = DemoScreenTimeService(authorized: config.skipOnboarding && config.initialScreen != .noAccess)
            entitlements = Entitlements(forcedStatus: config.forcePro ? .trial(daysLeft: 5) : .free, store: demoStore)
        } else {
            store = .shared
            screenTime = LiveScreenTimeService()
            entitlements = Entitlements()
        }
        #else
        store = .shared
        screenTime = LiveScreenTimeService()
        entitlements = Entitlements()
        #endif

        settings = store.settings
        flags = store.flags

        if !flags.hasSeededSchedules {
            store.schedules = [StillSchedule.nightsExample(name: String(localized: "Nights"))]
            flags.hasSeededSchedules = true
            store.flags = flags
        }

        #if DEBUG
        if config.isDemo { prepareDemo() }
        #endif

        loadFromStore()
        authorization = screenTime.authorization
        authorizationSettled = authorization != .notDetermined || config.isDemo
        screenTime.onAuthorizationChange = { [weak self] in
            guard let self else { return }
            self.authorization = self.screenTime.authorization
            if self.authorization != .notDetermined { self.authorizationSettled = true }
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.authorizationSettled = true
        }

        #if DEBUG
        if config.initialScreen == .endedEarly, let session = try? SessionMath.makeSession(
            start: clock.now.addingTimeInterval(-12 * 60), minutes: 30, isStrict: false
        ) {
            endedEarly = SessionRecord(
                id: session.id, start: session.start, plannedEnd: session.end,
                actualEnd: clock.now, outcome: .endedEarly
            )
        }
        #endif
    }

    // MARK: Derived state

    var phase: Phase {
        if authorization == .approved {
            return flags.hasCompletedOnboarding ? .main : .onboardingChooseApps
        }
        if !flags.hasCompletedOnboarding && !hasRequestedAuthorization && authorization == .notDetermined {
            return .onboarding
        }
        // Right after launch the status may still read "not determined" for an approved user.
        if flags.hasCompletedOnboarding && authorization == .notDetermined && !authorizationSettled {
            return .main
        }
        return .noAccess
    }

    var hasSelection: Bool { !selectionSummary.isEmpty }

    var thisWeekSeconds: TimeInterval {
        Stats.thisWeekSeconds(records: history, now: clock.now, calendar: calendar)
    }

    var streak: Int {
        Stats.streak(records: history, now: clock.now, calendar: calendar)
    }

    /// The duration the next session will use. A custom duration falls back to
    /// 30 minutes if Pro has lapsed.
    var effectiveDurationMinutes: Int {
        if ProAccess.requiresPro(durationMinutes: settings.durationMinutes) && !entitlements.canUse(.customDuration) {
            return StillConstants.defaultDurationMinutes
        }
        return SessionMath.clamp(minutes: settings.durationMinutes)
    }

    var isStrictModeEffective: Bool {
        settings.isStrictMode && entitlements.canUse(.strictMode)
    }

    // MARK: Store sync

    private func loadFromStore() {
        activeSession = store.activeSession
        history = store.history.sorted { $0.start < $1.start }
        settings = store.settings
        flags = store.flags
        schedules = store.schedules
        selectionSummary = store.selectionSummary
        if !config.isDemo {
            selection = SelectionStorage.load(from: store)
        }
        refreshUrges()
    }

    func refreshUrges() {
        if let activeSession {
            urgesThisSession = store.urges(during: activeSession, now: clock.now)
        } else {
            urgesThisSession = 0
        }
    }

    private func updateFlags(_ change: (inout StillFlags) -> Void) {
        var newFlags = store.flags
        change(&newFlags)
        store.flags = newFlags
        flags = newFlags
    }

    private func updateSettings(_ change: (inout StillSettings) -> Void) {
        var newSettings = store.settings
        change(&newSettings)
        store.settings = newSettings
        settings = newSettings
    }

    // MARK: Lifecycle

    /// Called on launch and every time the app becomes active.
    func becameActive() {
        screenTime.refreshAuthorization()
        authorization = screenTime.authorization
        reconcile()
        Task { await entitlements.refresh() }
    }

    /// Brings state up to date: finalizes an expired session, clears leftover shields,
    /// ends stale Live Activities and shows "Session complete" if the user hasn't seen it.
    func reconcile() {
        let result = engine.reconcile(now: clock.now)
        if result.shouldClearSessionShield {
            screenTime.clearSessionShield()
            screenTime.stopAllSessionMonitoring()
        }
        liveActivities.endAll(keeping: result.activeSession?.id)
        loadFromStore()

        if let record = result.completionToShow, completion?.id != record.id, endedEarly == nil {
            completion = record
        }
    }

    // MARK: Authorization and onboarding

    func requestAuthorization() async {
        hasRequestedAuthorization = true
        do {
            try await screenTime.requestAuthorization()
        } catch {
            // Denied or cancelled: `phase` moves to `.noAccess`.
        }
        authorization = screenTime.authorization
    }

    func completeOnboarding() {
        updateFlags { $0.hasCompletedOnboarding = true }
    }

    // MARK: Selection

    func saveSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        if !config.isDemo {
            SelectionStorage.save(newSelection, to: store)
        }
        selectionSummary = config.isDemo ? selectionSummary : SelectionStorage.summary(of: newSelection)
        reapplyRunningShields()
        try? register(schedules)
    }

    #if DEBUG
    /// Demo mode can't show real tokens, so it toggles a fake "3 categories" selection.
    func toggleDemoSelection() {
        let summary = selectionSummary.isEmpty ? SelectionSummary(categories: 3) : SelectionSummary()
        store.selectionSummary = summary
        selectionSummary = summary
    }
    #endif

    /// Applies a changed selection to a running session and any schedule that is active now.
    private func reapplyRunningShields() {
        guard hasSelection else { return }
        if activeSession != nil {
            screenTime.applySessionShield(selection)
        }
        if entitlements.canUse(.schedules) {
            for active in ScheduleMapping.activeSchedules(in: schedules, at: clock.now, calendar: calendar) {
                screenTime.applyScheduleShield(selection, scheduleID: active.schedule.id)
            }
        }
    }

    /// "Done" on Choose apps.
    func finishChoosingApps() {
        if phase == .onboardingChooseApps {
            completeOnboarding()
        } else if path.last == .chooseApps {
            path.removeLast()
        }
        if startAfterChoosingApps {
            startAfterChoosingApps = false
            if hasSelection { startSession() }
        }
    }

    /// "Back" on Choose apps: never starts a pending session.
    func cancelChoosingApps() {
        startAfterChoosingApps = false
        if path.last == .chooseApps { path.removeLast() }
    }

    func openChooseApps() {
        path.append(.chooseApps)
    }

    // MARK: Duration

    func selectPreset(_ minutes: Int) {
        updateSettings {
            $0.durationMinutes = minutes
            $0.isCustomDuration = false
        }
    }

    func tapCustomDuration() {
        if entitlements.canUse(.customDuration) {
            sheet = .customDuration
        } else {
            sheet = .paywall
        }
    }

    func setCustomDuration(_ minutes: Int) {
        let clamped = SessionMath.clamp(minutes: minutes)
        updateSettings {
            $0.durationMinutes = clamped
            $0.isCustomDuration = !StillConstants.presetMinutes.contains(clamped)
        }
        sheet = nil
    }

    // MARK: Sessions

    func startSession() {
        guard activeSession == nil else { return }
        guard hasSelection else {
            startAfterChoosingApps = true
            openChooseApps()
            return
        }

        let session: Session
        do {
            session = try engine.start(minutes: effectiveDurationMinutes, isStrict: isStrictModeEffective, now: clock.now)
        } catch {
            errorMessage = String(localized: "Couldn't start the session. Please try again.")
            return
        }

        screenTime.applySessionShield(selection)
        do {
            try screenTime.startMonitoring(session)
        } catch {
            // Without monitoring the shield could outlive the app; roll back.
            screenTime.clearSessionShield()
            store.activeSession = nil
            loadFromStore()
            errorMessage = String(localized: "Screen Time couldn't schedule the session. Please try again.")
            return
        }

        liveActivities.start(session, summary: Formatters.lockedSummary(selectionSummary))
        if settings.notifyWhenDone {
            scheduleDoneNotification(for: session)
        }
        loadFromStore()
    }

    private func scheduleDoneNotification(for session: Session) {
        let hypothetical = SessionRecord(
            id: session.id, start: session.start, plannedEnd: session.end, actualEnd: session.end, outcome: .completed
        )
        let streakAfter = Stats.streak(records: history + [hypothetical], now: session.end, calendar: calendar)
        let amount = Formatters.longDuration(minutes: session.plannedMinutes)
        notifications.scheduleSessionDone(
            session,
            title: String(localized: "\(amount), reclaimed"),
            body: String(localized: "Your apps are back. \(streakAfter) day streak.")
        )
    }

    /// Called when the 5-second hold completes.
    func endSessionEarly() {
        guard let session = activeSession, !session.isStrict else { return }
        guard let record = engine.endEarly(now: clock.now) else {
            reconcile()
            return
        }
        screenTime.clearSessionShield()
        screenTime.stopMonitoring(session.id)
        liveActivities.endAll()
        notifications.cancel(session.id)
        loadFromStore()
        if record.outcome == .endedEarly {
            endedEarly = record
        } else {
            reconcile()
        }
    }

    /// "OK" / "Start a new session" in the ended-early dialog.
    func dismissEndedEarly(startNew: Bool) {
        endedEarly = nil
        if startNew { startSession() }
        reconcile()
    }

    #if DEBUG
    /// Demo mode: jump the clock to the end of the running session.
    func fastForward() {
        guard let session = activeSession else { return }
        clock.advance(by: SessionMath.remaining(session, now: clock.now) + 1)
        reconcile()
    }
    #endif

    // MARK: Session complete

    /// Called when "Session complete" appears. Asks for notification permission after
    /// the first completed session. Returns whether to request an App Store review now.
    func completionAppeared() -> Bool {
        if !flags.hasRequestedNotificationPermission {
            updateFlags { $0.hasRequestedNotificationPermission = true }
            if !config.isDemo {
                Task { await notifications.requestAuthorization() }
            }
        }
        if ProAccess.shouldRequestReview(flags: flags) {
            updateFlags { $0.hasRequestedReview = true }
            return true
        }
        return false
    }

    /// "Done" / "Go again" on Session complete.
    func dismissCompletion(goAgain: Bool) {
        engine.markCompletionSeen()
        flags = store.flags
        startAfterCompletion = goAgain
        completion = nil
    }

    /// Called from the full-screen cover's onDismiss. Shows the paywall once after the first
    /// completed session, but only once the subscription status is known, so a subscriber
    /// never sees it (and the one-time flag isn't spent) on a cold launch.
    func completionDismissed() {
        let goAgain = startAfterCompletion
        startAfterCompletion = false
        if entitlements.isLoaded {
            finishCompletion(goAgain: goAgain)
        } else {
            Task {
                await entitlements.refresh()
                finishCompletion(goAgain: goAgain)
            }
        }
    }

    private func finishCompletion(goAgain: Bool) {
        if ProAccess.shouldShowAutomaticPaywall(flags: flags, status: entitlements.status) {
            updateFlags { $0.hasSeenAutomaticPaywall = true }
            startAfterPaywall = goAgain
            sheet = .paywall
        } else if goAgain {
            startSession()
        }
    }

    func sheetDismissed(_ dismissed: Sheet) {
        if dismissed == .paywall && startAfterPaywall {
            startAfterPaywall = false
            startSession()
        }
    }

    // MARK: Pro-gated navigation and settings

    func openSettings() { path.append(.settings) }

    func openSchedules() {
        if entitlements.canUse(.schedules) {
            path.append(.schedules)
        } else {
            sheet = .paywall
        }
    }

    func openInsights() {
        if entitlements.canUse(.insights) {
            path.append(.insights)
        } else {
            sheet = .paywall
        }
    }

    func setStrictMode(_ isOn: Bool) {
        if isOn && !entitlements.canUse(.strictMode) {
            sheet = .paywall
            return
        }
        updateSettings { $0.isStrictMode = isOn }
    }

    func setNotifyWhenDone(_ isOn: Bool) {
        updateSettings { $0.notifyWhenDone = isOn }
        if isOn && !config.isDemo {
            Task {
                if await !notifications.requestAuthorization() {
                    updateSettings { $0.notifyWhenDone = false }
                    errorMessage = String(localized: "Notifications are off for Still. Turn them on in Settings → Notifications → Still.")
                }
            }
        }
    }

    // MARK: Schedules

    /// Saves schedules and registers them. Returns false (and keeps the old ones) if they don't fit.
    @discardableResult
    func saveSchedules(_ newSchedules: [StillSchedule]) -> Bool {
        let previous = schedules
        do {
            try register(newSchedules)
        } catch ActivitySchedulerError.tooManySchedules {
            errorMessage = String(localized: "Too many schedules are on. Turn one off and try again.")
            try? register(previous)
            return false
        } catch {
            errorMessage = String(localized: "Screen Time couldn't update your schedules. Please try again.")
            try? register(previous)
            return false
        }
        store.schedules = newSchedules
        schedules = newSchedules
        return true
    }

    func upsertSchedule(_ schedule: StillSchedule) {
        var updated = schedules
        if let index = updated.firstIndex(where: { $0.id == schedule.id }) {
            updated[index] = schedule
        } else {
            updated.append(schedule)
        }
        saveSchedules(updated)
    }

    func deleteSchedule(_ id: UUID) {
        saveSchedules(schedules.filter { $0.id != id })
        screenTime.clearScheduleShield(id)
    }

    func setSchedule(_ id: UUID, enabled: Bool) {
        guard let index = schedules.firstIndex(where: { $0.id == id }) else { return }
        var updated = schedules
        updated[index].isEnabled = enabled
        saveSchedules(updated)
    }

    /// Re-registers schedules after the entitlement changes (schedules pause without Pro).
    func entitlementsChanged() {
        guard entitlements.isLoaded else { return }
        try? register(schedules)
    }

    private func register(_ list: [StillSchedule]) throws {
        let effective = entitlements.canUse(.schedules) && hasSelection
            ? list
            : list.map { var copy = $0; copy.isEnabled = false; return copy }
        let stopped = try screenTime.registerSchedules(effective)
        // Clear shields of schedules that are off, deleted or no longer monitored.
        let enabledIDs = Set(effective.filter(\.isEnabled).map(\.id))
        let toClear = stopped.union(list.map(\.id)).subtracting(enabledIDs)
        for id in toClear {
            screenTime.clearScheduleShield(id)
        }
        // Schedules that are active right now get their shield immediately.
        for active in ScheduleMapping.activeSchedules(in: effective, at: clock.now, calendar: calendar) {
            screenTime.applyScheduleShield(selection, scheduleID: active.schedule.id)
        }
    }

    // MARK: Insights

    var lastSevenDays: [DayTotal] {
        Stats.dailyTotals(records: history, days: 7, now: clock.now, calendar: calendar)
    }

    var lastSevenDaysInterval: DateInterval {
        Stats.lastDays(7, now: clock.now, calendar: calendar)
    }

    /// Every tap on the shield's "Close" in the last 7 days, during sessions and schedules.
    var urgesLastSevenDays: Int {
        Stats.urges(events: store.urgeEvents, in: lastSevenDaysInterval)
    }

    var sessionsLastSevenDays: Int {
        Stats.sessionCount(records: history, in: lastSevenDaysInterval)
    }

    // MARK: Demo

    #if DEBUG
    private func prepareDemo() {
        if config.skipOnboarding {
            var demoFlags = store.flags
            demoFlags.hasCompletedOnboarding = true
            store.flags = demoFlags
            store.selectionSummary = SelectionSummary(categories: 3)
        }
        if config.seedHistory {
            seedDemoHistory()
        }
        switch config.initialScreen {
        case .session?:
            if store.selectionSummary.isEmpty { store.selectionSummary = SelectionSummary(categories: 3) }
            if let session = try? SessionMath.makeSession(start: clock.now.addingTimeInterval(-342), minutes: 30, isStrict: false) {
                store.activeSession = session
                store.recordUrge(at: clock.now.addingTimeInterval(-200))
                store.recordUrge(at: clock.now.addingTimeInterval(-60))
            }
        case .insights?:
            path = [.insights]
        case .chooseApps?:
            path = [.chooseApps]
        case .settings?:
            path = [.settings]
        case .schedules?:
            path = [.schedules]
        case .paywall?:
            sheet = .paywall
        case .customDuration?:
            sheet = .customDuration
        case .complete?:
            let end = clock.now.addingTimeInterval(-60)
            let record = SessionRecord(
                id: UUID(), start: end.addingTimeInterval(-30 * 60), plannedEnd: end, actualEnd: end, outcome: .completed
            )
            store.appendRecord(record)
            var demoFlags = store.flags
            demoFlags.unseenCompletionID = record.id
            demoFlags.completedSessionCount += 1
            demoFlags.hasSeenAutomaticPaywall = true
            demoFlags.hasRequestedReview = true
            demoFlags.hasRequestedNotificationPermission = true
            store.flags = demoFlags
        default:
            break
        }
    }

    /// A believable week: 6-day streak, a few hours reclaimed.
    private func seedDemoHistory() {
        let now = clock.now
        let plan: [(daysAgo: Int, hour: Int, minutes: Int, early: Int?)] = [
            (5, 21, 60, nil), (4, 8, 30, nil), (4, 20, 30, 22), (3, 22, 15, nil),
            (2, 7, 30, nil), (1, 21, 60, nil), (0, 9, 15, nil),
        ]
        for item in plan {
            guard let day = calendar.date(byAdding: .day, value: -item.daysAgo, to: now),
                  let start = calendar.date(bySettingHour: item.hour, minute: 0, second: 0, of: day),
                  start < now
            else { continue }
            let plannedEnd = start.addingTimeInterval(TimeInterval(item.minutes * 60))
            let actualEnd = item.early.map { start.addingTimeInterval(TimeInterval($0 * 60)) } ?? plannedEnd
            store.appendRecord(SessionRecord(
                id: UUID(), start: start, plannedEnd: plannedEnd, actualEnd: min(actualEnd, now),
                outcome: item.early == nil ? .completed : .endedEarly, urgesResisted: item.daysAgo % 3
            ))
        }
        var demoFlags = store.flags
        demoFlags.completedSessionCount = 5
        demoFlags.hasSeenAutomaticPaywall = true
        demoFlags.hasRequestedReview = true
        demoFlags.hasRequestedNotificationPermission = true
        store.flags = demoFlags
    }
    #endif
}
