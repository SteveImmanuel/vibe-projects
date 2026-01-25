import 'package:flutter/services.dart';

class OverlayChannel {
  static const _channel = MethodChannel('com.extradim.midnight_filter/overlay');
  
  static Function()? onResume;
  
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onResume') {
        onResume?.call();
      }
    });
  }
  
  static Future<bool> startService() async {
    try {
      return await _channel.invokeMethod('startService') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> stopService() async {
    try {
      return await _channel.invokeMethod('stopService') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> setDimLevel(double level) async {
    try {
      await _channel.invokeMethod('setDimLevel', {'level': level});
    } catch (e) {
      // ignore
    }
  }
  
  static Future<bool> isServiceRunning() async {
    try {
      return await _channel.invokeMethod('isServiceRunning') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<double> getCurrentDimLevel() async {
    try {
      return await _channel.invokeMethod('getCurrentDimLevel') ?? 0.5;
    } catch (e) {
      return 0.5;
    }
  }
  
  static Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod('hasOverlayPermission') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      // ignore
    }
  }
  
  static Future<bool> hasBatteryOptimization() async {
    try {
      return await _channel.invokeMethod('hasBatteryOptimization') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } catch (e) {
      // ignore
    }
  }
}
