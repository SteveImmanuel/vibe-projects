import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const _settingsBox = 'settings';
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyTrackingEnabled = 'tracking_enabled';

  late Box _settings;

  Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox(_settingsBox);
  }

  bool get hasCompletedOnboarding {
    return _settings.get(_keyOnboardingComplete, defaultValue: false);
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _settings.put(_keyOnboardingComplete, value);
  }

  bool get isTrackingEnabled {
    return _settings.get(_keyTrackingEnabled, defaultValue: true);
  }

  Future<void> setTrackingEnabled(bool value) async {
    await _settings.put(_keyTrackingEnabled, value);
  }
}
