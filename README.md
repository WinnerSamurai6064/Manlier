# 🏃 MANLIER
### Built by TREYTEK

A running app for serious runners. Liquid Glass UI, real sensor tracking, leaderboard — all offline.

---

## Features
- **Splash** — MANLIER logo + animated runner silhouette + "built by TREYTEK"
- **Onboarding** — Name, height, body type, weight
- **Hub** — 3 live circle stats (Steps · Calories · Fitness), activity cards, week bar chart
- **Run Tracker** — Accelerometer step detection, live pace/speed/distance, pause/resume
- **Leaderboard** — Podium top 3, weekly/monthly/all-time tabs, your rank highlighted

## Stack
- Flutter 3.22+ / Dart 3.0+
- `sensors_plus` — accelerometer step detection
- `shared_preferences` — offline persistence
- `google_fonts` — Barlow + Rajdhani
- `fl_chart` — charts

---

## Build Locally

```bash
flutter pub get
flutter build apk --release
# APK → build/app/outputs/flutter-apk/app-release.apk
```

## Build via GitHub Actions

1. Push this repo to GitHub
2. Actions → **Build Manlier APK** runs automatically
3. Download the APK from **Artifacts** when complete

---

## Color Palette
| Token | Hex |
|---|---|
| Primary Orange | `#FF6B00` |
| Soft Orange | `#FF9A3C` |
| Warm Orange | `#FFB347` |
| Background | `#080808` |
| Surface | `#141414` |
