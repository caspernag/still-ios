# Handoff — what only you can do

> **How this was built and verified.** The code was written on a Linux machine without Xcode.
> Every iOS build and test ran on GitHub Actions macOS runners (Xcode 26.6, iOS 26 simulator) via
> `.github/workflows/ci.yml` in `caspernag/still-ios`. Screen Time itself (authorization, real
> shields, the monitor extension firing with the app killed) **cannot run in the simulator or CI**,
> so that part has not been seen working on a real device yet. Step 2 below is the first
> real-device check.

Everything else (code, tests, icons, screenshots, metadata, legal pages) is in the repo.

---

## 1. Open the project and set your team

1. `git clone https://github.com/caspernag/still-ios && cd still-ios`
2. `open Still.xcodeproj` (or run `brew install xcodegen && xcodegen generate` first if you changed `project.yml`).
3. In Xcode, select the **Still** project → for each of the 5 targets **Still, StillMonitor,
   StillShieldConfig, StillShieldAction, StillWidgets**: *Signing & Capabilities* → *Team* → your
   team (Nag Software). Leave "Automatically manage signing" on.
   Xcode creates the App IDs (`com.nagsoftware.still`, `.monitor`, `.shieldconfig`, `.shieldaction`,
   `.widgets`), the App Group `group.com.nagsoftware.still` and development profiles.
   *Tip:* to make this permanent, set `DEVELOPMENT_TEAM: "<YOUR_TEAM_ID>"` under `settings.base` in
   `project.yml` and run `xcodegen generate`.

## 2. Try it on your iPhone (development build, no Apple approval needed)

1. Plug in your iPhone, choose it as the run destination, press **Run** (⌘R).
2. Allow Screen Time access, choose a category, start a 15-minute session, open a blocked app
   (you should see "Be still."), then force-quit Still and wait for the session to end — the apps
   should unlock on their own.

## 3. Request the Family Controls (Distribution) entitlement

Needed for TestFlight and the App Store (development builds work without it).

1. Go to https://developer.apple.com/contact/request/family-controls-distribution
2. Submit one request **per bundle ID** — 4 in total:
   `com.nagsoftware.still`, `com.nagsoftware.still.monitor`,
   `com.nagsoftware.still.shieldconfig`, `com.nagsoftware.still.shieldaction`.
   Describe the app as "a self-control app that lets the user lock their own distracting apps for a
   chosen time using FamilyControls `.individual` authorization; no data leaves the device".
3. Wait for Apple's email (usually days to a few weeks). When approved, in
   https://developer.apple.com/account/resources/identifiers each of the four App IDs shows
   **Family Controls (Distribution)** under *Capabilities* — make sure it is ticked.

## 4. Create the app and subscriptions in App Store Connect

1. https://appstoreconnect.apple.com → **Apps** → **+** → **New App**:
   Platform iOS · Name **Still** · Primary language **English (U.S.)** · Bundle ID
   **com.nagsoftware.still** · SKU `still-ios` · Full access.
2. **App Information**: Category **Productivity**, secondary **Health & Fitness**. Add the
   Norwegian (Bokmål) localization (*+* next to the language menu). Paste name/subtitle from
   `AppStore/metadata.md`. Privacy Policy URL `https://nagsoftware.no/still/privacy`.
3. **App Privacy** → *Get Started* → "No, we do not collect data from this app" → Publish.
4. **Age Rating** → answer everything "None"/"No" as listed in `AppStore/metadata.md` (result 4+).
5. **Monetization → Subscriptions** → *Create* subscription group **Still Pro**, then:
   - **+** → Reference name `Still Pro Yearly`, Product ID `com.nagsoftware.still.pro.yearly`,
     Duration **1 Year**, Price **USD 29.99** (let Apple fill other countries), localizations from
     `metadata.md`, *Introductory Offers* → **+** → all countries → **Free** → **1 Week**.
   - **+** → `Still Pro Monthly`, `com.nagsoftware.still.pro.monthly`, **1 Month**, **USD 4.99**,
     same 1-week free trial.
   - Group localization: display name "Still Pro" (en and nb).
   - Each subscription needs a review screenshot: use `AppStore/screenshots/` (any) for now.
6. **Agreements** (Business): make sure the *Paid Apps* agreement, bank and tax info are active,
   otherwise subscriptions can't be sold.

## 5. Host the legal pages

Upload `AppStore/privacy.html` → `https://nagsoftware.no/still/privacy` and
`AppStore/terms.html` → `https://nagsoftware.no/still/terms` (serve them as `index.html` in
`/still/privacy/` and `/still/terms/`, or configure the server for extension-less URLs). Optionally
add a simple support page at `https://nagsoftware.no/still` (the Support URL).

## 6. Upload to TestFlight

**Option A — from GitHub (no Mac needed after setup)**
1. https://appstoreconnect.apple.com/access/integrations/api → **Team Keys** → **+** → name
   "GitHub CI", access **Admin** → *Generate* → download `AuthKey_XXXX.p8` (only once!).
   Note the **Key ID** and the **Issuer ID** above the list.
2. Your Team ID: https://developer.apple.com/account → *Membership details* → Team ID.
3. https://github.com/caspernag/still-ios/settings/secrets/actions → **New repository secret**, add:
   `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (paste the whole .p8 file contents),
   `DEVELOPMENT_TEAM`.
4. https://github.com/caspernag/still-ios/actions/workflows/testflight.yml → **Run workflow**
   (branch `claude/still-ios-app-vw4vmo` or `main`). It archives, signs and uploads; the build
   appears in App Store Connect → TestFlight after processing (~10–30 min).
   *This only succeeds after step 3 (Family Controls Distribution) is approved*, because the App
   Store profile must include the Family Controls entitlement.

**Option B — from Xcode**
Product → Archive → *Distribute App* → *App Store Connect* → *Upload*.

Then in TestFlight: answer the export-compliance question (already "No" via
`ITSAppUsesNonExemptEncryption`), add yourself under *Internal Testing* and install with the
TestFlight app.

## 7. Screenshots and submit for review

1. Screenshots (6.9" iPhone) are generated by CI into `AppStore/screenshots/` on every push
   (or run `Scripts/screenshots.sh` locally). Upload them under **iOS App → 1.0 → Previews and
   Screenshots** for both English and Norwegian.
2. Paste the description, keywords, promotional text, support URL from `AppStore/metadata.md`
   (both languages). Copyright: `2026 Nag Software`.
3. **App Review Information**: paste the review notes from `metadata.md`; sign-in not required;
   contact casper@nagsoftware.no.
4. Select the TestFlight build, add both subscriptions to the version
   (*In-App Purchases and Subscriptions* section), then **Add for Review** → **Submit**.
