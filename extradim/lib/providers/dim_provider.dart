import 'package:flutter/foundation.dart';
import '../services/overlay_channel.dart';

class DimProvider extends ChangeNotifier {
  double _dimLevel = 0.5;
  bool _isServiceRunning = false;
  bool _hasOverlayPermission = false;
  bool _hasBatteryOptimization = false;
  
  double get dimLevel => _dimLevel;
  bool get isServiceRunning => _isServiceRunning;
  bool get hasOverlayPermission => _hasOverlayPermission;
  bool get hasBatteryOptimization => _hasBatteryOptimization;
  int get dimPercent => (_dimLevel * 100).round();
  
  DimProvider() {
    _init();
  }
  
  Future<void> _init() async {
    OverlayChannel.init();
    OverlayChannel.onResume = refresh;
    await refresh();
  }
  
  Future<void> refresh() async {
    _hasOverlayPermission = await OverlayChannel.hasOverlayPermission();
    _hasBatteryOptimization = await OverlayChannel.hasBatteryOptimization();
    _isServiceRunning = await OverlayChannel.isServiceRunning();
    _dimLevel = await OverlayChannel.getCurrentDimLevel();
    notifyListeners();
  }
  
  Future<void> setDimLevel(double level) async {
    _dimLevel = level.clamp(0.0, 0.9);
    notifyListeners();
    
    if (_isServiceRunning) {
      await OverlayChannel.setDimLevel(_dimLevel);
    }
  }
  
  Future<bool> toggleService() async {
    if (!_hasOverlayPermission) {
      await OverlayChannel.requestOverlayPermission();
      return false;
    }
    
    if (_isServiceRunning) {
      await OverlayChannel.stopService();
      _isServiceRunning = false;
    } else {
      final success = await OverlayChannel.startService();
      if (success) {
        _isServiceRunning = true;
        await OverlayChannel.setDimLevel(_dimLevel);
      }
    }
    
    notifyListeners();
    return _isServiceRunning;
  }
  
  Future<void> requestOverlayPermission() async {
    await OverlayChannel.requestOverlayPermission();
  }
  
  Future<void> requestBatteryOptimization() async {
    await OverlayChannel.requestBatteryOptimization();
  }
}
