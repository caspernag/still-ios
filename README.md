# Still

A calm anti-scroll app for iPhone. Pick the apps that pull you in, tap once, and they stay
locked until the timer ends. Ending early takes a deliberate 5-second hold. Built on Apple's
Screen Time APIs. Everything stays on the device: no account, no backend, no analytics.

## Architecture

```
Still (app, SwiftUI)        StillMonitor            StillShieldConfig      StillShieldAction     StillWidgets
 AppModel  ─ session flow    DeviceActivityMonitor   ShieldConfiguration    ShieldActionDelegate  Live Activity
 Entitlements ─ StoreKit 2   intervalDidStart/End    "Be still." screen     counts urges, .close  Lock Screen + Island
        │                           │                       │                     │                   │
        └───────────────── StillKit (local Swift package, linked by every target) ─────────────────────┘
          StillCore     sessions, stats, schedules, SharedStore (App Group UserDefaults) — pure Foundation
          StillKit      Shields (ManagedSettings), ActivityScheduler (DeviceActivity), SelectionStorage, ActivityAttributes
          DesignSystem  color tokens, StillFont, spacing, buttons, cards, rings, Live Activity views
```

**How a session works.** `AppModel.startSession()` saves a `Session` in the App Group
(`SessionEngine`), applies the shield to `ManagedSettingsStore(named: "still.session")`, registers a
one-off `DeviceActivitySchedule` from now to the end, starts the Live Activity
(`Text(timerInterval:)`, `staleDate` = end) and schedules the "done" notification. When the interval
ends, **StillMonitor** clears the store and records the session as completed, even if the app isn't
running. Holding "Hold to end early" for 5 s clears the store, stops monitoring, ends the Live
Activity and cancels the notification. On every launch and foreground, `AppModel.reconcile()`
finalizes an expired session, clears leftover shields and Live Activities, and shows
"Session complete" once.

**Schedules (Pro)** register one weekly activity per weekday (one daily activity for every-day
schedules). The monitor applies and clears a store named per schedule, so sessions and schedules
never clear each other.

**State.** `SharedStore` keeps Codable values in the App Group's `UserDefaults`, one key per value:
the active session, history, settings, flags, schedules, the `FamilyActivitySelection` and urge
timestamps. Streaks, weekly totals and insights are pure functions in `Stats`.

**Pro** is gated through `Entitlements` (`Transaction.currentEntitlements` + `Transaction.updates`)
and `ProAccess`. The paywall is Apple's `SubscriptionStoreView` with the design's header.

**Demo mode** (`-StillDemo`, DEBUG builds only) swaps in a fake `ScreenTimeService` and an isolated
store, so every screen runs in the simulator, in UI tests and for screenshots.

## Build and test

```sh
brew install xcodegen
xcodegen generate                      # Still.xcodeproj is committed too
open Still.xcodeproj                   # scheme "Still"; StoreKit config Still.storekit is preselected
xcodebuild test -scheme Still -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
swift test --package-path StillKit     # core logic, also runs on Linux
Scripts/screenshots.sh                 # App Store screenshots → AppStore/screenshots/
python3 Scripts/strings_audit.py       # every UI string has a Norwegian translation
```

CI (`.github/workflows/ci.yml`) builds for device in Release and runs every test on a macOS runner.
`.github/workflows/testflight.yml` archives and uploads to App Store Connect (see `HANDOFF.md`).

## Repository

| Path | What |
|---|---|
| `Still/` | App: `App/` (entry, model, formatting), `Features/` (one folder per screen), `Services/`, `Resources/` |
| `StillKit/` | Shared package: `StillCore`, `StillKit`, `DesignSystem`, plus core tests |
| `StillMonitor/`, `StillShieldConfig/`, `StillShieldAction/`, `StillWidgets/` | Extensions |
| `StillTests/`, `StillUITests/` | App unit, StoreKit and UI tests |
| `AppStore/` | Metadata (en/nb), privacy and terms pages, icon, screenshots |
| `Design/` | The approved design file and reference renders of all 12 artboards |
| `Scripts/` | Icon generation, string catalogs, screenshots |
