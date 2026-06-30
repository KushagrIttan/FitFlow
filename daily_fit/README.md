# Daily Fit

A local-first, privacy-focused Flutter application for tracking your wardrobe and generating daily outfit recommendations based on weather and style.

## Getting Started

1. **Open the Project:**
   Open the `daily_fit` folder in Android Studio. Ensure you have the Flutter and Dart plugins installed.

2. **Add Your Gemini API Key:**
   In the root of the `daily_fit` directory, you will find a `.env` file. Replace `your_api_key_here` with your actual Google Gemini API key.
   ```
   GEMINI_API_KEY=your_real_api_key
   ```

3. **Running the App via USB Debugging:**
   - Enable Developer Options and USB Debugging on your Pixel 7.
   - Connect your Pixel 7 to your computer via USB.
   - In Android Studio, select your Pixel 7 from the device dropdown at the top.
   - Click the green "Play" (Run) button, or run the following in the terminal:
     ```bash
     flutter run
     ```

## Recommendation Logic Overview

The recommendation engine operates in two steps to ensure privacy and offline capability while maintaining smart recommendations:
1. **Local Pre-Scoring:** The app first filters out clothes currently in the laundry or incompatible with the current weather's warmth requirements. It then scores every possible valid permutation of Top + Bottom + Footwear based on recency (favoring items you haven't worn in a while to cycle the wardrobe) and total wear-count balancing.
2. **AI Final Selection:** The top 5 highest-scoring permutations are securely sent to the Gemini API (`gemini-1.5-flash`) along with your context (Going out vs Home, Vibe, Weather). Gemini acts as a stylist to pick the absolute best 2-3 options and provides a quick, punchy justification for why the colors and fit work well together. If the API fails or you are offline, the app falls back to displaying the highest-scoring local permutations.
