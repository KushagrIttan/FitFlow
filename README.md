# FitFlow 👕✨

**FitFlow** is a privacy-focused, local-first wardrobe management system and context-aware style engine. Built to eliminate daily decision fatigue, FitFlow treats your personal closet as a deterministic state machine—tracking laundry availability, parsing style notes, and factoring in real-time weather to algorithmically recommend your daily outfit.

---

## 🚀 Features

* **Deterministic Laundry Engine:** Real-time state management for every clothing item (`Clean`, `In Wash`, `Drying`, `Dry Cleaning`). Items not marked as `Clean` are automatically excluded from recommendation pools.
* **Context & Weather Integration:** Toggle "Heading Out" mode to automatically pull local weather conditions and exclude home-only loungewear.
* **AI Stylist (Optional):** Integrated optional support for Google Gemini API to parse natural language style notes while keeping all personal photos and closet metadata on-device.
* **Local-First & Private:** Wardrobe photos and outfit logs never leave your device. Sensitive API keys are encrypted locally via Android Keystore.
* **Tactile UI & Micro-Interactions:** Features a translucent floating navigation bar, haptic feedback, dark mode, and custom UI sound effects.
* **Data Backup:** Full JSON export and import support for user data control.

---

## 🛠️ Architecture & Tech Stack

* **UI / Framework:** Cross-Platform Mobile Architecture (Translucent Floating Bar, Custom Design System)
* **AI & NLP:** Google Gemini API (Optional Natural Language Styling)
* **Monetization Engine:** RevenueCat SDK (WIP — Freemium Gating & In-App Subscriptions for Shipaton Next Gen)
* **Storage & Security:** Local SQLite Database, Android Keystore Encryption
* **APIs:** Open-Meteo API / Device Location Services

---

## 🧮 Mathematical Model

FitFlow filters items using a deterministic state check before running candidate outfits through a weighted scoring function:

$$\text{Score}(\text{Outfit}) = \alpha \cdot W(i) + \beta \cdot V(i) - \gamma \cdot R(i)$$

Where:
* $W(i)$ = Weather compatibility score
* $V(i)$ = Style context & vibe match ("Heading Out" vs. "Home")
* $R(i)$ = Wear frequency penalty (prevents repeating recent outfits)

---

## 📦 Getting Started

### Prerequisites
* Flutter SDK 3.7+ / Dart 3.7+
* Android SDK (API 23+) or Xcode for iOS
* (Optional) Google Gemini API Key for AI styling features
* (Optional) RevenueCat public SDK key for Pro billing

```bash
git clone https://github.com/KushagrIttan/FitFlow.git
cd FitFlow/daily_fit
cp .env.example .env   # paste REVENUECAT_ANDROID_KEY into .env
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Full steps (keys, release build, tests): see [`daily_fit/README.md`](daily_fit/README.md).

