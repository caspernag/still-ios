import Foundation

/// Features that need Still Pro.
public enum ProFeature: String, CaseIterable, Sendable {
    case schedules
    case strictMode
    case customDuration
    case insights
}

/// The user's subscription state.
public enum ProStatus: Equatable, Sendable {
    case free
    /// In the free trial, with whole days left (rounded up).
    case trial(daysLeft: Int)
    /// Paid and active.
    case active
    /// Subscribed before, no longer active.
    case expired

    public var isPro: Bool {
        switch self {
        case .trial, .active: return true
        case .free, .expired: return false
        }
    }

    /// Days left in a trial that expires at `expiration`, rounded up and never below 0.
    public static func trialDaysLeft(expiration: Date, now: Date) -> Int {
        let seconds = expiration.timeIntervalSince(now)
        guard seconds > 0 else { return 0 }
        return Int((seconds / 86_400).rounded(.up))
    }
}

/// Gating rules for Pro features.
public enum ProAccess {
    /// Every Pro feature needs an active subscription or trial; free features are always allowed.
    public static func canUse(_ feature: ProFeature, status: ProStatus) -> Bool {
        status.isPro
    }

    /// Whether a duration needs Pro (anything that isn't a preset).
    public static func requiresPro(durationMinutes: Int) -> Bool {
        !StillConstants.presetMinutes.contains(durationMinutes)
    }

    /// Whether the automatic paywall should show after a completed session:
    /// only after the first completion, only once, and never for Pro users.
    public static func shouldShowAutomaticPaywall(flags: StillFlags, status: ProStatus) -> Bool {
        !status.isPro && !flags.hasSeenAutomaticPaywall && flags.completedSessionCount >= 1
    }

    /// Whether the review prompt should be requested now (once, after the 3rd completion).
    public static func shouldRequestReview(flags: StillFlags) -> Bool {
        !flags.hasRequestedReview && flags.completedSessionCount >= StillConstants.reviewPromptAfterCompletedSessions
    }
}
