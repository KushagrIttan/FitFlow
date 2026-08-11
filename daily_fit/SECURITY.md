# Security Notes — Daily Fit

## Gemini API key

Daily Fit calls the Gemini API **directly from the device** (there is no backend).
This design has one unavoidable consequence: **the API key ships inside the app
binary**. `pubspec.yaml` bundles `.env` as a Flutter asset, so the key is
extractable from any APK (`unzip app-release.apk assets/flutter_assets/.env`).

This is a known trade-off of client-side AI apps — a proxy server only moves the
problem (the key then lives on the server instead). For a personal, local-first
app, the pragmatic mitigation is **key restriction by fingerprint**:

1. Open [Google AI Studio → API keys](https://aistudio.google.com/apikey).
2. Select the key used by this app (the one in `daily_fit/.env`).
3. Choose **Restrict key** → **Android apps**.
4. Add:
   - Package name: `com.example.daily_fit`
   - SHA-1 certificate fingerprint of the **release signing key**
     (`keytool -list -v -keystore <your-release.jks> -alias <alias>`), and, if
     you debug on a device, the debug key's SHA-1
     (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`).
5. Save. If the key is ever leaked anyway, revoke it from the same page.

Even restricted, treat the key as public knowledge — never use a key that has
access to anything you couldn't share.

## .env policy

- `.env` is **gitignored** and must never be committed. It holds `GEMINI_API_KEY`.
- The app works without it (local-only mode: no AI styling, offline fallback).

## Verification

- `gitleaks` (or `git grep`) should find no `GEMINI_API_KEY=` blobs in history.
- Repo is local-only; if it ever gets a remote, re-check history before pushing.
