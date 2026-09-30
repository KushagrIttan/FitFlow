# Security Notes — Daily Fit

## Gemini API key

Daily Fit calls the Gemini API **directly from the device** (there is no backend).

**Where the key lives:** the key is configured **in the app** (Settings → AI
Stylist) and stored encrypted on-device with `flutter_secure_storage`
(Android Keystore / iOS Keychain). It is:

- never committed to git,
- never bundled in the APK (the `.env` asset holds only the publishable
  RevenueCat key — never the Gemini key),
- only sent to Google's Gemini API endpoint when generating recommendations.

**Key restriction (recommended):** even though the key no longer ships in the
binary, restricting it adds a hard second layer. In
[Google AI Studio → API keys](https://aistudio.google.com/apikey), choose
**Restrict key → Android apps** and add:

- Package name: `com.fitflow.dailyfit`
- SHA-1 fingerprints of your signing keys:
  - Release: `keytool -list -v -keystore <your-release.jks> -alias <alias>`
  - Debug (if you run on a device): `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`

If a key is ever leaked anyway, revoke it from the same page.

## RevenueCat public key

Pro billing uses the RevenueCat **public** SDK key, which is publishable by
design (it cannot be used to spend or refund anything).

**Where the key lives:** `.env` as `REVENUECAT_ANDROID_KEY=goog_...`
(loaded via `flutter_dotenv`, overridable with
`--dart-define=REVENUECAT_ANDROID_KEY=...`). It is:

- the only secret allowed in `.env` / the app bundle,
- safe to ship in the APK — but still gitignored locally (`.env.example`
  is the committed template),
- only sent to RevenueCat's API when checking Pro status / purchasing.

**Test vs release keys:** `.env` currently holds a Test Store key (`test_...`),
which works in debug builds with RC test products and no Play setup. It must
**never ship in a release/Play build** — the SDK crashes on purpose with test
keys in release. Release builds take the Google platform key (`goog_...`) via
`--dart-define=REVENUECAT_ANDROID_KEY=...`; `PurchasesService.init()` also
refuses to configure a test key in release mode as a second guard.

Without a key the app runs fully in free/local mode and
**Settings → Daily Fit Pro** shows "Billing is not configured".

## Local data

- Wardrobe, photos, outfit history, and the API key never leave the device.
- Photo files are deleted from disk when an item is removed.
- The only network calls are: open-meteo (weather), Gemini (AI styling),
  and RevenueCat (Pro status / purchases).

## Verification

- `gitleaks` / `git grep` should find no `GEMINI_API_KEY=` blobs in history.
- `.env` must never contain a Gemini key:
  `grep -ri gemini .env .env.example` → only comments, no `AIza` value.
- `.env` and `.env.example` are scanned in CI for `AIza` values.
