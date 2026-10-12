# Still — App Store metadata

Paste these into App Store Connect → Still → App Information / iOS App → 1.0.
Character counts are checked against Apple's limits (name 30, subtitle 30,
promotional text 170, keywords 100, description 4000).

---

## English (U.S.) — the only language (the app is English-only)

**Name** (5/30)
Still

**Subtitle** (29/30)
Lock distracting apps, calmly

**Promotional text** (153/170)
Pick the apps that pull you in, tap once, and they stay locked until the timer ends. Ending early takes a slow, deliberate hold. Try Pro free for 7 days.

**Description**
Still is a calm way to put your phone down.

Pick the apps that pull you in. Tap once. They stay locked until the timer ends. If you really need to stop early, it takes a slow, deliberate 5-second hold — a small pause to ask: do I really need this?

HOW IT WORKS
• Choose apps, categories or websites with Apple's Screen Time picker
• Start a 15 minute, 30 minute, 1 hour or 2 hour session
• Blocked apps show a quiet "Be still." screen until your session ends
• Follow the countdown on the Lock Screen and in the Dynamic Island
• See how much time you reclaimed this week, and keep your streak going

STILL PRO
• Schedules that lock apps automatically, every week (for example every night 22:00–07:00)
• Strict mode, with no way to end a session early
• Custom session lengths from 15 minutes to 12 hours
• Weekly insights: reclaimed time per day, streaks, sessions and urges resisted

Still Pro is an auto-renewable subscription, yearly or monthly, with a 7-day free trial. Payment is charged to your Apple Account when the trial ends unless you cancel at least 24 hours before. The subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel it anytime in Settings → Apple Account → Subscriptions.

PRIVATE BY DESIGN
Still uses Apple's Screen Time framework. Everything stays on your iPhone: no account, no servers, no analytics. Still never sees which apps you use — Apple only gives it opaque tokens.

Terms of Use: https://nagsoftware.no/still/terms
Privacy Policy: https://nagsoftware.no/still/privacy

**Keywords** (97/100)
focus,screen time,app blocker,detox,digital wellbeing,distraction,productivity,timer,lock,mindful

**Support URL**
https://nagsoftware.no/still

**Marketing URL** (optional)
https://nagsoftware.no/still

**Copyright**
2026 Nag Software

---

## Category

- Primary: **Productivity**
- Secondary: **Health & Fitness**

## Age rating answers (App Store Connect questionnaire)

All "None" / "No":
- Cartoon or fantasy violence, realistic violence, prolonged graphic or sadistic violence: None
- Profanity or crude humor: None
- Mature or suggestive themes: None
- Horror or fear themes: None
- Medical or treatment information: None
- Alcohol, tobacco or drug use or references: None
- Simulated gambling: None
- Sexual content or nudity: None
- Contests: None
- Unrestricted web access: No
- User-generated content: No
- Messaging and chat: No
- Advertising: No
- Parental controls: No (Still is a self-control tool for the user's own device; it uses FamilyControls with `.individual` authorization)
- Age assurance: No
- Health or wellness topics: No

Expected rating: **4+**.

## App Privacy ("nutrition label")

- Does this app collect data? **No, we do not collect data from this app.**
- Result: **Data Not Collected**

Rationale: no account, no network requests, no analytics or crash SDKs. Session history,
settings and the Screen Time selection (opaque tokens) are stored only in the app's
App Group container on the device. StoreKit purchases are handled by Apple.

## Subscriptions (App Store Connect → Monetization → Subscriptions)

Subscription group: **Still Pro** (group display name "Still Pro")

| Reference name | Product ID | Duration | Price | Introductory offer |
|---|---|---|---|---|
| Still Pro Yearly | com.nagsoftware.still.pro.yearly | 1 year | USD 29.99 (tier) | Free trial, 1 week, new subscribers |
| Still Pro Monthly | com.nagsoftware.still.pro.monthly | 1 month | USD 4.99 (tier) | Free trial, 1 week, new subscribers |

Display names / descriptions (English):
- "Still Pro Yearly" / "Schedules, strict mode, custom durations and insights."
- "Still Pro Monthly" / same

Review screenshot for the subscription: use `AppStore/screenshots/` paywall (or a simulator
screenshot of Home → Custom). Review notes: "Opened from Settings → Still Pro → Try free, or
automatically once after the first completed session."

## App Review notes

> Still is a self-control app for the user's own iPhone. It uses Apple's Screen Time APIs
> (FamilyControls with `.individual` authorization, ManagedSettings and DeviceActivity) to
> shield apps the user chooses, for a limited time the user chooses. Nothing leaves the
> device; there is no account and no server.
>
> How to test (Screen Time requires a real device; it does not work in the simulator):
> 1. Launch Still and tap "Allow Screen Time access", then approve with Face ID / passcode.
> 2. Tap "Choose apps" and pick a category (for example Social) or a single app, then Done.
> 3. On Home, pick 15 min and tap "Start session". Open a blocked app: it shows the
>    "Be still." shield. Tap "Close" — this is counted as an "urge resisted".
> 4. Back in Still, the session screen shows the countdown. Touch and hold
>    "Hold to end early" for 5 seconds to end the session early. The shield is removed.
> 5. Start another 15-minute session and wait (the app may be closed): when the timer ends
>    the apps unlock on their own and "Session complete" is shown on next launch. After the
>    first completed session the Still Pro paywall is shown once.
> 6. Still Pro (subscription with a 7-day free trial) unlocks Schedules (Settings → Schedules),
>    Strict mode, a Custom duration (Home → Custom) and Insights (tap "This week" on Home).
>    Restore purchases and Manage subscription are in Settings.
>
> The FamilyControls (Distribution) entitlement has been granted for the app and its three
> Screen Time extensions.

## Screenshots

6.9" iPhone (1320 × 2868), generated by `Scripts/screenshots.sh` into `AppStore/screenshots/`:
1. Home — "3 h 12 min reclaimed · 6 day streak"
2. Session — countdown ring
3. Shield — "Be still."
4. Live Activity — Lock Screen and Dynamic Island
5. Choose apps — "What pulls you in?"
6. Insights — last 7 days
