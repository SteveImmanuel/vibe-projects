import 'package:flutter/services.dart';

class ScrollPlatformService {
  static const _channel = MethodChannel('com.scrollmuch/scroll_tracker');

  Future<double> getTodayScrollMeters() async {
    final result = await _channel.invokeMethod<double>('getTodayScrollMeters');
    return result ?? 0.0;
  }

  Future<bool> isServiceEnabled() async {
    final result = await _channel.invokeMethod<bool>('isServiceEnabled');
    return result ?? false;
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    await _channel.invokeMethod('setTrackingEnabled', {'enabled': enabled});
  }

  Future<bool> isTrackingEnabled() async {
    final result = await _channel.invokeMethod<bool>('isTrackingEnabled');
    return result ?? true;
  }

  Future<int> getScreenDpi() async {
    final result = await _channel.invokeMethod<int>('getScreenDpi');
    return result ?? 400;
  }
}
