# KokoShots

AI-powered screenshot manager for Android.

## Current setup

- Flutter Android app scaffold is complete.
- Screenshot discovery uses Android photo/media access.
- Local metadata and chat history are stored in SQLite.
- Gemini analysis is wired, but needs your API key at run/build time.
- First launch requests photo access and starts indexing.
- While the app is open, KokoShots polls periodically for new screenshots.

## Run

Without Gemini AI analysis:

```powershell
flutter run
```

With Gemini AI analysis:

```powershell
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Optional model override:

```powershell
flutter run --dart-define=GEMINI_API_KEY=your_key_here --dart-define=GEMINI_MODEL=gemini-2.0-flash
```

## Build APK

```powershell
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

## Items needing your attention

- Add your real Gemini API key using `--dart-define=GEMINI_API_KEY=...`.
- Before publishing, replace debug signing with a real Android release keystore.
- On first run, approve Android photo access so KokoShots can index screenshots.
- Keep the app open during the first large scan; Gemini analysis can take time on big screenshot libraries.
