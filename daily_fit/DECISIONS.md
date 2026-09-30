# Architectural & Design Decisions

1. **State Management & Routing**
   - **Decision:** Used `flutter_riverpod` and `go_router`.
   - **Reasoning:** Standardized modern approach for declarative routing and reactive UI, allowing simple injection of database and preference services.

2. **Database**
   - **Decision:** Used `drift` over pure SQLite.
   - **Reasoning:** Drift provides strongly-typed tables and simple reactive streams.

3. **User Profile & Preferences**
   - **Decision:** Used `shared_preferences` instead of a separate drift table.
   - **Reasoning:** The user profile only ever contains one row of simple config (height, weight, style notes). SharedPreferences is much lighter and fits this key-value requirement perfectly.

4. **Recommendation Logic (Local vs AI)**
   - **Decision:** Built a two-stage process. First stage scores locally (O(N^3) over valid filtered clothes is very fast for a personal wardrobe), selecting the top 5. Second stage passes just those 5 to Gemini.
   - **Reasoning:** Sending the entire wardrobe database as a prompt to Gemini every time would quickly exhaust free API limits and token windows as the wardrobe grows. Pre-scoring locally ensures API usage stays minimal and ensures the rules (no repeating yesterday's shirt, ignore laundry) are strictly enforced mathematically before AI styling takes over.

5. **API Key Management**
   - **Decision:** Gemini key uses in-app configuration; RevenueCat key uses `.env`.
   - **Reasoning:** The Gemini key is a true secret, so it is entered in **Settings → AI Stylist** and stored encrypted via `flutter_secure_storage` (Android Keystore) — it never touches git or the app bundle. A "Verify" button confirms the key works before saving. The RevenueCat key is publishable by design, so it lives in `.env` (`REVENUECAT_ANDROID_KEY`, see `.env.example`, overridable with `--dart-define`) and is safe to bundle. Every `PurchasesService` call is defensive: unconfigured builds and widget tests run in free/local mode instead of throwing.

6. **Monetization (Shipaton Next Gen)**
   - **Decision:** `purchases_flutter` + `purchases_ui_flutter` (v10) with a single `fitflow_pro` entitlement; Lifetime / Yearly / Monthly products attached to the Current offering in the dashboard. Purchase UI is the remotely-configured RevenueCat Paywall (`RevenueCatUI.presentPaywallIfNeeded("fitflow_pro")` + full-screen `PaywallScreen`), account management via Customer Center; free mode keeps local recommendations fully usable.
   - **Reasoning:** Satisfies the Shipaton requirement for thoughtful RevenueCat use while keeping the app evaluable from video + code (no store listing needed): Pro status surfaces in **Settings → Daily Fit Pro** with View plans / Restore / Manage subscription, and every paywall path degrades to a clear "billing not configured" message instead of a crash. Test Store key (`test_...`) in `.env` for debug; release takes the `goog_...` platform key via `--dart-define` (code refuses test keys in release — the SDK crashes on purpose with them). Android notes: `MainActivity` must extend `FlutterFragmentActivity` for Paywalls; `minSdk 24` required by `purchases_ui_flutter`; `launchMode singleTop` already set.
