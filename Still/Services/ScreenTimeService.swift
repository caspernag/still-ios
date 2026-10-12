import Combine
import FamilyControls
import Foundation
import StillKit

enum ScreenTimeAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case approved
}

/// Everything the app does with FamilyControls, ManagedSettings and DeviceActivity,
/// behind a protocol so demo mode (simulator, UI tests) can skip the real calls.
@MainActor
protocol ScreenTimeService: AnyObject {
    var authorization: ScreenTimeAuthorization { get }
    /// Called whenever the system reports a new authorization status.
    var onAuthorizationChange: (@MainActor () -> Void)? { get set }
    func refreshAuthorization()
    func requestAuthorization() async throws

    func applySessionShield(_ selection: FamilyActivitySelection)
    func clearSessionShield()
    func startMonitoring(_ session: Session) throws
    func stopMonitoring(_ sessionID: UUID)
    func stopAllSessionMonitoring()

    func applyScheduleShield(_ selection: FamilyActivitySelection, scheduleID: UUID)
    func clearScheduleShield(_ scheduleID: UUID)
    /// Registers the enabled schedules. Returns IDs of schedules that are no longer monitored.
    func registerSchedules(_ schedules: [StillSchedule]) throws -> Set<UUID>
}

/// The real implementation.
@MainActor
final class LiveScreenTimeService: ScreenTimeService {
    private(set) var authorization: ScreenTimeAuthorization = .notDetermined
    var onAuthorizationChange: (@MainActor () -> Void)?
    private var subscription: AnyCancellable?

    init() {
        refreshAuthorization()
        // The status can settle a moment after launch; follow it instead of reading it once.
        subscription = AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.authorization = Self.map(status)
                    self.onAuthorizationChange?()
                }
            }
    }

    func refreshAuthorization() {
        authorization = Self.map(AuthorizationCenter.shared.authorizationStatus)
    }

    /// Any approved variant (iOS 26.4 added one with data access) counts as approved.
    private static func map(_ status: AuthorizationStatus) -> ScreenTimeAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .approved
        }
    }

    func requestAuthorization() async throws {
        defer { refreshAuthorization() }
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    func applySessionShield(_ selection: FamilyActivitySelection) {
        Shields.apply(selection, to: .stillSession)
    }

    func clearSessionShield() {
        Shields.clear(.stillSession)
    }

    func startMonitoring(_ session: Session) throws {
        try ActivityScheduler.startMonitoring(session)
    }

    func stopMonitoring(_ sessionID: UUID) {
        ActivityScheduler.stopMonitoring(sessionID)
    }

    func stopAllSessionMonitoring() {
        ActivityScheduler.stopAllSessionActivities()
    }

    func applyScheduleShield(_ selection: FamilyActivitySelection, scheduleID: UUID) {
        Shields.apply(selection, to: .stillSchedule(scheduleID))
    }

    func clearScheduleShield(_ scheduleID: UUID) {
        Shields.clear(.stillSchedule(scheduleID))
    }

    func registerSchedules(_ schedules: [StillSchedule]) throws -> Set<UUID> {
        try ActivityScheduler.registerSchedules(schedules)
    }
}

#if DEBUG
/// Demo mode: authorization is granted instantly and no system calls are made.
@MainActor
final class DemoScreenTimeService: ScreenTimeService {
    var onAuthorizationChange: (@MainActor () -> Void)?
    private(set) var authorization: ScreenTimeAuthorization
    private(set) var sessionShieldActive = false
    private(set) var monitoredSessions = Set<UUID>()
    private(set) var registeredSchedules: [StillSchedule] = []

    init(authorized: Bool) {
        authorization = authorized ? .approved : .notDetermined
    }

    func refreshAuthorization() {}

    func requestAuthorization() async throws {
        authorization = .approved
    }

    func applySessionShield(_ selection: FamilyActivitySelection) { sessionShieldActive = true }
    func clearSessionShield() { sessionShieldActive = false }
    func startMonitoring(_ session: Session) throws { monitoredSessions.insert(session.id) }
    func stopMonitoring(_ sessionID: UUID) { monitoredSessions.remove(sessionID) }
    func stopAllSessionMonitoring() { monitoredSessions.removeAll() }
    func applyScheduleShield(_ selection: FamilyActivitySelection, scheduleID: UUID) {}
    func clearScheduleShield(_ scheduleID: UUID) {}

    func registerSchedules(_ schedules: [StillSchedule]) throws -> Set<UUID> {
        guard ScheduleMapping.fitsActivityBudget(schedules) else { throw ActivitySchedulerError.tooManySchedules }
        let before = Set(registeredSchedules.filter(\.isEnabled).map(\.id))
        registeredSchedules = schedules
        return before.subtracting(schedules.filter(\.isEnabled).map(\.id))
    }
}
#endif
