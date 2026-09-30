# Daily Fit

A local-first, privacy-focused Flutter application for tracking your wardrobe and generating daily outfit recommendations based on weather and style.

## Getting Started

### Prerequisites
* Flutter SDK 3.7+ (`flutter --version`)
* Android SDK (API 23+) via Android Studio, or Xcode for iOS
* A device or emulator

### 1. Clone and install
```bash
git clone https://github.com/KushagrIttan/FitFlow.git
cd FitFlow/daily_fit
cp .env.example .env   # then paste your RevenueCat public key into .env
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Configure keys (both optional — the app runs free/local without them)
* **RevenueCat (Pro billing):** paste your public SDK key as
  `REVENUECAT_ANDROID_KEY=goog_...` in `.env`
  (or pass `--dart-define=REVENUECAT_ANDROID_KEY=goog_...`).
  Without it the app runs in free mode and **Settings → Daily Fit Pro**
  shows "Billing is not configured".
* **Gemini (AI styling):** open **Settings → AI Stylist** inside the app,
  paste your key (from
  [aistudio.google.com/apikey](https://aistudio.google.com/apikey)),
  tap **Verify**, then **Save Key**. It is stored encrypted
  on-device (Android Keystore) and never ships in the app binary.
  Without a key the app still works — recommendations fall back to local
  scoring (no AI styling).

### 3. Run
```bash
flutter run
# release APK:
flutter build apk --release
# verify:
flutter analyze
flutter test
```

### 4. Running via Android Studio / USB debugging
* Enable Developer Options and USB Debugging on your device.
* Connect via USB, select the device in the device dropdown, press Run.

## Recommendation Logic Overview

The recommendation engine operates in two steps to ensure privacy and offline capability while maintaining smart recommendations:
1. **Local Pre-Scoring:** The app first filters out clothes currently in the laundry or incompatible with the current weather's warmth requirements. It then scores every possible valid permutation of Top + Bottom + Footwear based on recency (favoring items you haven't worn in a while to cycle the wardrobe) and total wear-count balancing.
2. **AI Final Selection:** The top 5 highest-scoring permutations are securely sent to the Gemini API (`gemini-1.5-flash`) along with your context (Going out vs Home, Vibe, Weather). Gemini acts as a stylist to pick the absolute best 2-3 options and provides a quick, punchy justification for why the colors and fit work well together. If the API fails or you are offline, the app falls back to displaying the highest-scoring local permutations.
