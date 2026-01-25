# Midnight Filter

An Android app that applies a software-level dimming overlay to reduce screen brightness below the hardware minimum. Perfect for nighttime use.

## Features

- **Extra Dim Control**: Reduce brightness from 0% to 90% using a slider
- **Persistent Service**: Filter stays active even when app is closed
- **Quick Settings Tile**: Toggle filter from notification shade
- **Touch Passthrough**: Interact normally with apps under the dimming layer
- **Battery Optimized**: Request exemption from battery optimization

## Requirements

- Android 8.0 (API 26) or higher
- "Display over other apps" permission

## Building

```bash
flutter pub get
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

## Permissions

The app requires:
- `SYSTEM_ALERT_WINDOW` - To display the dimming overlay
- `FOREGROUND_SERVICE` - To keep the overlay running
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` - To prevent service from being killed

## Architecture

```
lib/
├── main.dart                  # App entry
├── providers/dim_provider.dart # State management
├── screens/home_screen.dart    # Main UI
├── services/overlay_channel.dart # Native bridge
└── widgets/dim_slider.dart     # Custom slider

android/.../kotlin/
├── MainActivity.kt             # MethodChannel handler
├── OverlayService.kt          # Foreground service + overlay
└── QuickSettingsTile.kt       # Quick settings toggle
```
