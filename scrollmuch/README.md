# ScrollMuch

A Flutter Android app that tracks how much you scroll across all apps, measured in meters — with a per-app breakdown.

## Features

- **System-wide scroll tracking** - works across all apps using Android Accessibility Service
- **Per-app breakdown** - see today's distance for each app you scrolled, with its icon and name
- **Offline only** - all data stays on device, no network permission
- **Daily tracking** - resets each day
- **Soft toggle** - pause/resume tracking instantly without touching system settings

## Project Structure

```
lib/
├── main.dart                           # app entry, provider setup, portrait lock
├── screens/
│   ├── home_screen.dart                # total + per-app list + toggle button
│   └── onboarding_screen.dart          # first-time accessibility permission setup
├── services/
│   ├── scroll_platform_service.dart    # Dart side of platform channel
│   └── storage_service.dart            # Hive storage (onboarding flag)
└── models/
    └── app_scroll.dart                 # per-app scroll data model

android/app/src/main/
├── kotlin/com/scrollmuch/scrollmuch/
│   ├── MainActivity.kt                 # platform channel handler, per-app + icon reads
│   └── ScrollAccessibilityService.kt   # core scroll tracking logic
├── res/xml/accessibility_service_config.xml
├── res/values/strings.xml
└── AndroidManifest.xml                 # service registration + QUERY_ALL_PACKAGES
```

## How It Works

### Scroll Tracking (Native Android)

`ScrollAccessibilityService` listens for `TYPE_VIEW_SCROLLED` events system-wide and attributes a pixel distance to each event's app.

In practice Android's `scrollDeltaX/Y` is unreliable — most apps report `0` or a direction-only `±1` rather than the real pixel delta. So distance is derived per event:

1. **Real delta** — if `scrollDeltaX/Y` has a real magnitude (`>1`), use `sqrt(dx² + dy²)`.
2. **Absolute position** — otherwise diff the app's absolute `scrollY`/`scrollX` against its last value, counting it when the scroller reports pixel-scale positions (filters out coarse/index scrollers) and the change is plausible (not a teleport or scroller switch).
3. **Gesture estimate** — if an app gives no usable pixel signal at all, fall back to a fixed ~5cm-per-gesture estimate (only for apps that never report real pixels, so it can't inflate the accurate ones).

Pixels accumulate per app and convert to meters using device DPI: `meters = pixels / DPI / 39.3701`. Scrolling in this app itself, the home launcher, and the system UI shell are excluded.

### Per-App List

The home screen shows today's total (large) with a scrollable list beneath it: one row per app you scrolled, with its icon, name, and distance, sorted by distance. The total is the sum of the per-app distances. App icons/names are resolved natively (requires the `QUERY_ALL_PACKAGES` permission; still no network access).

### Platform Channel

Flutter ↔ native over `MethodChannel('com.scrollmuch/scroll_tracker')`:

| Method | Description |
|--------|-------------|
| `getTodayScrollMeters` | Today's total in meters |
| `getPerAppScrollMeters` | Per-app `{package, label, meters}` list (sorted) |
| `getAppIcon` | App icon (base64 PNG) for a package |
| `isServiceEnabled` | Is the accessibility service enabled |
| `openAccessibilitySettings` | Open Android accessibility settings |
| `setTrackingEnabled` / `isTrackingEnabled` | Soft toggle pause/resume |

### Data Storage

- **SharedPreferences** (native): per-app pixel counts, tracked/excluded package sets, date, and the toggle flag — the source of truth for scroll data.
- **Hive** (Flutter): onboarding-complete flag only.

## User Flow

1. **First launch**: onboarding guides you to enable the accessibility service (one-time, manual via system settings).
2. **Normal use**: home screen shows today's total + per-app breakdown, refreshing every 2 seconds.
3. **Toggle**: start/stop tracking in-app (the accessibility service stays enabled).
4. **Status badge**: "Active" (green) when tracking, "Inactive" (red) when stopped or the service is disabled.

## Build & Install

```bash
# Debug (install in-place to keep the accessibility grant)
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Release, split by CPU architecture
flutter build apk --release --split-per-abi
# Outputs: app-arm64-v8a-release.apk, app-armeabi-v7a-release.apk, app-x86_64-release.apk
```

> The release build is currently signed with the debug key — fine for sideloading, but set up a proper signing config before publishing.

## App Icon

Configured via `flutter_launcher_icons`. Regenerate after changing `assets/icon.png`:

```bash
dart run flutter_launcher_icons
```

## Dependencies

- `hive` / `hive_flutter` - local storage (onboarding flag)
- `provider` - state management
- `flutter_launcher_icons` (dev) - app icon generation

## Known Limitations

1. **Some apps can't be tracked** - apps that emit no scroll accessibility events (e.g. YouTube / ReVanced, whose feed only fires generic "content changed" events) won't appear at all.
2. **Fallback apps are approximate** - apps without pixel-scale scroll data (e.g. Reddit) use a fixed per-gesture estimate rather than a true distance.
3. **No history / charts** - only today's totals are shown.
4. **Momentum counts** - fling/momentum scrolling counts content distance, not finger distance.

## Technical Notes

- Accessibility Service persists after a one-time enable (survives restarts/reboots); Android may disable it after app updates.
- Soft toggle is a SharedPreferences flag the service checks before counting.
- The UI is portrait-locked.
