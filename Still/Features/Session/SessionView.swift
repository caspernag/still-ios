import DesignSystem
import StillKit
import SwiftUI

/// Screen 4: a running session.
struct SessionView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppClock.self) private var clock
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if let session = model.activeSession {
            content(session)
                .task(id: session.id) {
                    await waitForEnd(of: session)
                }
                .task(id: session.id) {
                    // Keep "urges resisted" fresh while the app is open.
                    while !Task.isCancelled {
                        model.refreshUrges()
                        try? await Task.sleep(for: .seconds(5))
                    }
                }
        }
    }

    private func content(_ session: Session) -> some View {
        StillScreen {
            StillTopBar {
                LogoLockup()
            } trailing: {
                StatusPill("Session on")
            }

            Spacer(minLength: 16)

            CountdownRing(session: session)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 16)

            StatPairCard(
                leadingValue: Text(verbatim: "\(model.selectionSummary.total)"),
                leadingLabel: Text(Formatters.lockedLabel(model.selectionSummary)),
                trailingValue: Text(verbatim: "\(model.urgesThisSession)"),
                trailingLabel: Text(Formatters.urgesLabel(model.urgesThisSession))
            )

            VStack(spacing: StillSpacing.buttonGap) {
                if session.isStrict {
                    StrictModeRow()
                } else {
                    HoldButton("Hold to end early", duration: StillConstants.holdToEndSeconds) {
                        model.endSessionEarly()
                    }
                    .accessibilityIdentifier("holdToEnd")

                    Text("Hold for 5 seconds. A pause to ask: do I really need this?")
                        .stillFont(.footnote)
                        .foregroundStyle(StillColor.inkSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                #if DEBUG
                if model.config.isDemo {
                    Button { model.fastForward() } label: { Text(verbatim: "Demo: fast-forward") }
                        .stillFont(.footnote)
                        .foregroundStyle(StillColor.inkSecondary)
                        .accessibilityIdentifier("demoFastForward")
                }
                #endif
            }
        }
    }

    /// Finalizes the session when its end time arrives while the app is open.
    private func waitForEnd(of session: Session) async {
        let remaining = SessionMath.remaining(session, now: clock.now)
        if remaining > 0 {
            // A short delay lets the monitor extension finalize first; finalizing is idempotent.
            try? await Task.sleep(for: .seconds(remaining + 2))
        }
        guard !Task.isCancelled else { return }
        model.reconcile()
    }
}

/// The 280 pt white circle with the progress ring and the live countdown.
private struct CountdownRing: View {
    let session: Session
    @Environment(AppClock.self) private var clock

    var body: some View {
        ZStack {
            Circle()
                .fill(StillColor.surface.shadow(.inner(color: .black.opacity(0.04), radius: 3, x: 0, y: -2)))
                .overlay(Circle().strokeBorder(StillColor.border, lineWidth: 1).padding(-1))
                .shadow(color: StillColor.shadow.opacity(0.22), radius: 30, x: 0, y: 30)

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                ProgressRing(progress: SessionMath.remainingFraction(session, now: clock.now))
                    .padding(18)
                    .animation(.linear(duration: 1), value: SessionMath.remainingFraction(session, now: clock.now))
            }

            VStack(spacing: 6) {
                Text(timerInterval: displayInterval, countsDown: true)
                    .stillFont(.timer)
                    .foregroundStyle(StillColor.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 36)
                    .accessibilityIdentifier("countdown")
                Text("until your apps return")
                    .stillFont(.subheadline)
                    .foregroundStyle(StillColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(width: StillSize.ring, height: StillSize.ring)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Session ends at \(session.end, style: .time)"))
    }

    /// `Text(timerInterval:)` counts against the real clock; shift by the demo offset.
    private var displayInterval: ClosedRange<Date> {
        let offset = clock.offset
        let start = session.start.addingTimeInterval(-offset)
        let end = session.end.addingTimeInterval(-offset)
        return start...max(start, end)
    }
}

/// Replaces the hold button in strict mode.
private struct StrictModeRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("Strict mode is on")
                .stillFont(.button)
        }
        .foregroundStyle(StillColor.inkSecondary)
        .frame(maxWidth: .infinity, minHeight: StillSize.button)
        .background {
            RoundedRectangle(cornerRadius: StillRadius.card, style: .continuous)
                .fill(StillColor.fill)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("This session can't be ended early."))
        .accessibilityIdentifier("strictModeRow")
    }
}
