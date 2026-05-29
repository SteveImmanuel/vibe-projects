import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/app_scroll.dart';

class ScrollPlatformService {
  static const _channel = MethodChannel('com.scrollmuch/scroll_tracker');

  Future<double> getTodayScrollMeters() async {
    final result = await _channel.invokeMethod<double>('getTodayScrollMeters');
    return result ?? 0.0;
  }

  Future<List<AppScroll>> getPerAppScrollMeters() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('getPerAppScrollMeters');
    if (result == null) return [];
    return result
        .map((e) => AppScroll.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Uint8List?> getAppIcon(String package) async {
    final result = await _channel
        .invokeMethod<String>('getAppIcon', {'package': package});
    if (result == null) return null;
    return base64Decode(result);
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
}
