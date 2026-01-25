# ScrollMuch

A Flutter Android app that tracks how much you scroll across all apps, measured in meters.

## Features

- **System-wide scroll tracking** - Works across all apps using Android Accessibility Service
- **Offline only** - All data stays on device, no network permissions
- **Daily tracking** - Resets at midnight automatically
- **Soft toggle** - Pause/resume tracking instantly without touching system settings
- **Extensible storage** - Architecture ready for future history/charts features

## Project Structure

```
lib/
├── main.dart                           # app entry, provider setup
├── screens/
│   ├── home_screen.dart                # main UI with meter display + toggle button
│   └── onboarding_screen.dart          # first-time accessibility permission setup
├── services/
│   ├── scroll_platform_service.dart    # Dart side of platform channel
│   └── storage_service.dart            # Hive local storage for settings
└── models/
    └── scroll_record.dart              # data model (for future history feature)

android/app/src/main/
├── kotlin/com/scrollmuch/scrollmuch/
│   ├── MainActivity.kt                 # platform channel handler
│   └── ScrollAccessibilityService.kt   # core scroll tracking logic
├── res/
│   ├── xml/accessibility_service_config.xml
│   └── values/strings.xml
└── AndroidManifest.xml                 # service registration
```

## How It Works

### Scroll Tracking (Native Android)

The `ScrollAccessibilityService` extends Android's `AccessibilityService` and listens for `TYPE_VIEW_SCROLLED` events system-wide. When any app scrolls:

1. Service receives the scroll event with pixel delta
2. Converts pixels to meters using device DPI: `meters = pixels / DPI / 39.3701`
3. Accumulates total in SharedPreferences
4. Checks date and resets counter at midnight

**Current limitation**: Only tracks vertical scrolling (`scrollDeltaY`). Horizontal and diagonal scrolling are not fully captured.

### Platform Channel

Flutter communicates with native Android via a MethodChannel (`com.scrollmuch/scroll_tracker`):

| Method | Description |
|--------|-------------|
| `getTodayScrollMeters` | Returns current day's total in meters |
| `isServiceEnabled` | Checks if accessibility service is enabled |
| `openAccessibilitySettings` | Opens Android accessibility settings |
| `setTrackingEnabled` | Soft toggle - pause/resume without disabling service |
| `isTrackingEnabled` | Get current soft toggle state |
| `getScreenDpi` | Get device screen DPI |

### Pixel to Meter Conversion

```kotlin
val dpi = resources.displayMetrics.densityDpi.toFloat()
val inches = totalPixels / dpi
val meters = inches / 39.3701  // inches per meter
```

DPI is automatically detected per device, so measurements are physically accurate.

### Data Storage

- **SharedPreferences** (native): Stores scroll pixel count and date (fast access for the service)
- **Hive** (Flutter): Stores app settings like onboarding state and tracking toggle

## User Flow

1. **First launch**: Onboarding screen guides user to enable accessibility service (one-time)
2. **Normal use**: Home screen shows today's scroll distance, refreshes every 2 seconds
3. **Toggle**: User can start/stop tracking with in-app button (accessibility stays enabled)
4. **Status badge**: Shows "Active" (green) when tracking, "Inactive" (red) when stopped or service disabled

## Build & Install

```bash
# Debug build
flutter build apk --debug
flutter install --debug

# Release build (optimized, split by CPU architecture)
flutter build apk --release --split-per-abi
# Outputs: app-arm64-v8a-release.apk (~7MB), app-armeabi-v7a-release.apk, app-x86_64-release.apk
```

## App Icon

Custom icon is configured via `flutter_launcher_icons`. To regenerate after changing `assets/icon.png`:

```bash
dart run flutter_launcher_icons
```

## Dependencies

- `hive` / `hive_flutter` - Local storage
- `provider` - State management
- `flutter_launcher_icons` (dev) - App icon generation

## Known Limitations / Future Improvements

1. **Vertical only** - Currently only tracks `scrollDeltaY`. Could add horizontal + diagonal (Pythagorean distance)
2. **No history** - Shows only today's total. Model exists for daily history but not implemented
3. **No charts** - Could add weekly/monthly visualizations
4. **Momentum counts** - Fling/momentum scrolling counts even after finger lifts (measures content distance, not finger distance)

## Technical Notes

- Accessibility Service persists after one-time enable (survives app restarts, phone reboots)
- Service may be disabled after app updates (Android security feature)
- Soft toggle uses SharedPreferences flag checked by service before accumulating pixels
