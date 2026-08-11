# Security Notes — Daily Fit

## Gemini API key

Daily Fit calls the Gemini API **directly from the device** (there is no backend).

**Where the key lives:** the key is configured **in the app** (Settings → AI
Stylist) and stored encrypted on-device with `flutter_secure_storage`
(Android Keystore / iOS Keychain). It is:

- never committed to git,
- never bundled in the APK (no `.env` asset — the app bundle is key-free),
- only sent to Google's Gemini API endpoint when generating recommendations.

**Key restriction (recommended):** even though the key no longer ships in the
binary, restricting it adds a hard second layer. In
[Google AI Studio → API keys](https://aistudio.google.com/apikey), choose
**Restrict key → Android apps** and add:

- Package name: `com.example.daily_fit`
- SHA-1 fingerprints of your signing keys:
  - Release: `keytool -list -v -keystore <your-release.jks> -alias <alias>`
  - Debug (if you run on a device): `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`

If a key is ever leaked anyway, revoke it from the same page.

## Local data

- Wardrobe, photos, outfit history, and the API key never leave the device.
- Photo files are deleted from disk when an item is removed.
- The only network calls are: open-meteo (weather) and Gemini (AI styling).

## Verification

- `gitleaks` / `git grep` should find no `GEMINI_API_KEY=` blobs in history.
- The release APK must contain no `.env` asset:
  `unzip -l app-release.apk | grep -c env` → 0
- Repo is local-only; if it ever gets a remote, re-check history before pushing.
