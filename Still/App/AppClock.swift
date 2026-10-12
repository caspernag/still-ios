import Foundation
import Observation

/// The app's notion of "now". In demo mode it can be fast-forwarded so UI tests
/// can reach "Session complete" without waiting 15 minutes.
@Observable
@MainActor
final class AppClock {
    private(set) var offset: TimeInterval = 0

    var now: Date { Date().addingTimeInterval(offset) }

    func advance(by seconds: TimeInterval) {
        offset += max(0, seconds)
    }
}
