# OKX AI Trader (Android)

Android app that fetches OKX market data, computes popular technical indicators, and uses Gemini 2.5 Flash to produce concise trading insights.

## Features
- OKX market candles via public REST API
- Indicators: SMA/EMA, RSI, MACD, Bollinger Bands, ATR, Stochastic, OBV, Ichimoku
- Jetpack Compose UI
- Gemini analysis (set your API key)
- GitHub Actions CI to auto-build APK on every push and upload artifact

## Local setup
1. Open the project in Android Studio (Giraffe+). Ensure JDK 17.
2. Create a `local.properties` and add:
   ```
   GEMINI_API_KEY=your_google_ai_api_key
   ```
3. Run the app. Default symbol `BTC-USDT-SWAP`, timeframe `1H`.

## CI build
- Add a repo secret `GEMINI_API_KEY` if you want AI to work in CI-built APK (optional).
- Push to any branch. Workflow `.github/workflows/android-build.yml` builds `app-debug.apk` and uploads it as an artifact.

## Notes
- This app provides educational insights only. Not financial advice.