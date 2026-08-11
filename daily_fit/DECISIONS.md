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
   - **Decision:** Replaced `flutter_dotenv` + `.env` asset with in-app configuration.
   - **Reasoning:** Bundling `.env` as a Flutter asset shipped the key inside the
     APK — extractable by anyone. The key is now entered in **Settings → AI
     Stylist** and stored encrypted via `flutter_secure_storage` (Android
     Keystore). The binary is key-free and the key never touches git.
     A "Verify" button confirms the key works before saving.
