# ScrollMuch - Agent Reference

## Project Overview

**ScrollMuch** is a Flutter Android app that tracks how much the user scrolls across all apps, measured in meters, with a **per-app breakdown**. It uses Android's Accessibility Service to observe scroll events system-wide.

### Key Features
- **System-wide scroll tracking** via Android Accessibility Service
- **Per-app breakdown** - today's distance per app (icon + name + distance), apps appear only once scrolled
- **Offline only** - all data stays on device, no network permission in release
- **Daily tracking** - resets at the first scroll after midnight
- **Soft toggle** - pause/resume tracking without disabling the system setting

## Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend Framework | Flutter (Dart SDK >=3.4.0-99.0.dev) |
| State Management | Provider |
| Local Storage (Flutter) | Hive (onboarding flag only) |
| Local Storage (Native) | SharedPreferences (all scroll data) |
| Native Android | Kotlin |
| Build Tool | Gradle |

## Project Structure

```
scrollmuch/
├── lib/                            # Flutter Dart code
│   ├── main.dart                   # App entry, provider setup, portrait lock
│   ├── screens/
│   │   ├── home_screen.dart        # Total + per-app scrollable list + toggle
│   │   └── onboarding_screen.dart  # First-time accessibility setup
│   ├── services/
│   │   ├── scroll_platform_service.dart  # Dart side of platform channel
│   │   └── storage_service.dart    # Hive storage (onboarding flag)
│   └── models/
│       └── app_scroll.dart         # Per-app scroll data model
├── android/app/src/main/
│   ├── kotlin/com/scrollmuch/scrollmuch/
│   │   ├── MainActivity.kt         # Platform channel handler, per-app + icon reads
│   │   └── ScrollAccessibilityService.kt  # Core scroll tracking
│   ├── res/xml/accessibility_service_config.xml
│   ├── res/values/strings.xml
│   └── AndroidManifest.xml         # Service registration + QUERY_ALL_PACKAGES
├── assets/icon.png
├── pubspec.yaml
└── analysis_options.yaml
```

> Note: `test/widget_test.dart` is the stale Flutter template (references a nonexistent `MyApp`) and will not compile; it is intentionally ignored.

## Build Commands

### Debug
```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk   # in-place; keeps the accessibility grant
```
> Prefer `adb install -r` over `flutter install` during iteration: `flutter install` may uninstall first, which clears app data **and** disables the accessibility service.

### Release (split by CPU architecture)
```bash
flutter build apk --release --split-per-abi
# Outputs under build/app/outputs/flutter-apk/:
#   app-arm64-v8a-release.apk     (most modern phones)
#   app-armeabi-v7a-release.apk
#   app-x86_64-release.apk
```
> The release build is currently signed with the **debug** key (`build.gradle` uses `signingConfig signingConfigs.debug`). Not Play-Store ready — set up a real signing config before publishing.

### Other
```bash
flutter analyze
dart run flutter_launcher_icons   # after changing assets/icon.png
```

## Platform Channel API

Single `MethodChannel` `com.scrollmuch/scroll_tracker` (request/response only; no EventChannel). Dart: `scroll_platform_service.dart`; native: `MainActivity.kt`. All calls are Dart → Native.

| Method | Args | Returns | Description |
|--------|------|---------|-------------|
| `getTodayScrollMeters` | — | `Double` | Today's total in meters (sum of per-app, excludes hidden packages) |
| `getPerAppScrollMeters` | — | `List<Map>` `{package, label, meters}` | Per-app totals today, sorted desc, excludes hidden packages |
| `getAppIcon` | `{package: String}` | `String?` (base64 PNG) or null | App launcher icon, rasterized 96×96 |
| `isServiceEnabled` | — | `Boolean` | Is the accessibility service enabled |
| `openAccessibilitySettings` | — | `true` | Opens Android accessibility settings |
| `setTrackingEnabled` | `{enabled: Boolean}` | `true` | Soft toggle - pause/resume tracking |
| `isTrackingEnabled` | — | `Boolean` | Current soft-toggle state |

## Permissions

- `BIND_ACCESSIBILITY_SERVICE` - gates the service (`AndroidManifest.xml`, `exported="false"`).
- `QUERY_ALL_PACKAGES` - required to resolve the **name and icon of arbitrary apps** for the per-app list (Android 11+ package-visibility rule). No network is requested; release has no `INTERNET` permission (it appears only in the debug/profile manifests via Flutter tooling).

## Key Implementation Details

### Scroll Tracking Logic (Native — `ScrollAccessibilityService`)
Listens for `TYPE_VIEW_SCROLLED` events system-wide and, for each, attributes a pixel distance to the event's package. Counting is skipped for **excluded packages**: the app itself (avoids the in-app list feeding back into the total), `com.android.systemui`, and the home launcher(s) (resolved dynamically via the `HOME` intent). Excluded packages are persisted to SharedPreferences so `MainActivity` also hides them from the list/total.

`scrollDeltaX/Y` is unreliable on most apps (commonly `0` or direction-only `±1`), so distance is derived as follows, per event:
1. **Real per-event delta** - if `|scrollDeltaX| > 1` or `|scrollDeltaY| > 1`, use `sqrt(dx² + dy²)`.
2. **Absolute-position delta** - otherwise, diff the absolute `scrollX`/`scrollY` against the per-package baseline. A change is counted as pixels only when:
   - the scroller is **pixel-scale** (`scrollY`/`maxScrollY` ≥ `COARSE_MAX_SCROLL = 500`) — distinguishes pixel scrollers (Claude/Outlook/Immich: `scrollY` in the thousands) from coarse/index scrollers (Reddit: `scrollY` 0–66);
   - it's within `[1 .. maxPixelDelta]` where `maxPixelDelta = screenHeightPx × 4` (rejects teleports);
   - the scroller didn't switch (detected via a >4× change in `maxScroll`, only compared when both maxima are positive).
3. **Gesture-end fallback** - if neither yields pixels (coarse/zero-signal scroller), schedule a debounced 300ms `Runnable` that credits a flat `FALLBACK_CM = 5cm`. This fallback is **gated**: apps that have ever reported real pixels (`hasRealPixels`) never use it, so the 5cm estimate can't inflate pixel-accurate apps. This is what keeps Reddit counting.

Pixels accumulate per app under `app_pixels_<package>`; meters are computed on read: `pixels / DPI / 39.3701`.

### Storage
**Native SharedPreferences** `scroll_tracker_prefs` (source of truth for scroll data):
- `app_pixels_<package>` (Long) - per-app pixel total for the day
- `tracked_packages` (StringSet) - packages with data today (for enumeration/reset)
- `excluded_packages` (StringSet) - packages hidden from list/total
- `tracking_date` (String, `LocalDate`) - for the daily reset
- `tracking_enabled` (Boolean, default true) - soft toggle

`MainActivity` derives the **daily total as the sum of per-app pixels minus excluded packages**, so the total always matches the list and stale/excluded data can't pollute it (there is no separate `total_pixels` key).

**Hive box** `settings` (Flutter): only `onboarding_complete` (Bool).

### Daily Reset
Lazy: on the first scroll after `LocalDate.now()` changes, `checkAndResetForNewDay` clears the per-app keys, `tracked_packages`, pending fallback gestures, and the in-memory position baselines.

### UI (`home_screen.dart`)
Total (large, top) + a `BY APP` scrollable `ListView` of `_buildAppTile` rows (cached icon + name + distance). Refreshes every 2s via `Timer.periodic` (guarded against overlap) and on app resume. App is **portrait-locked** (`main.dart`). `_formatMeters`: `<1m → cm`, `<1000m → m`, else `km`.

## Known Limitations
1. **Some apps are untrackable** - apps that emit **no** `TYPE_VIEW_SCROLLED` events (e.g. YouTube / ReVanced, whose feed only fires `TYPE_WINDOW_CONTENT_CHANGED`) cannot be tracked via accessibility and won't appear. `TYPE_WINDOW_CONTENT_CHANGED` is not a usable scroll signal (it also fires during video playback/animations).
2. **Coarse/fallback apps are approximate** - apps without pixel-scale position data (e.g. Reddit) get a flat ~5cm-per-gesture estimate, not a true distance.
3. **No history / charts** - only today's totals are shown.
4. **Momentum counts** - fling/momentum scrolling counts content distance, not finger distance.
5. **Multiple scrollers per app** - an app's secondary scrollers (e.g. a small bottom sheet) may fall back to the 5cm estimate or be ignored once the app is known to report pixels.

## Localization
Hardcoded English. App name: `ScrollMuch` (the on-screen header reads `scroll much`). Accessibility description in `res/values/strings.xml`.
