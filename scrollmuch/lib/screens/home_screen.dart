import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scroll_platform_service.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  double _meters = 0.0;
  bool _isTracking = true;
  bool _isServiceEnabled = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshMeters();
    });
  }

  Future<void> _loadState() async {
    final platform = context.read<ScrollPlatformService>();

    final meters = await platform.getTodayScrollMeters();
    final tracking = await platform.isTrackingEnabled();
    final serviceEnabled = await platform.isServiceEnabled();

    setState(() {
      _meters = meters;
      _isTracking = tracking;
      _isServiceEnabled = serviceEnabled;
    });
  }

  Future<void> _refreshMeters() async {
    if (!mounted) return;
    final platform = context.read<ScrollPlatformService>();
    final meters = await platform.getTodayScrollMeters();
    if (mounted) {
      setState(() => _meters = meters);
    }
  }

  Future<void> _toggleTracking() async {
    final platform = context.read<ScrollPlatformService>();
    final storage = context.read<StorageService>();

    final newValue = !_isTracking;
    await platform.setTrackingEnabled(newValue);
    await storage.setTrackingEnabled(newValue);

    setState(() => _isTracking = newValue);
  }

  Future<void> _openSettings() async {
    final platform = context.read<ScrollPlatformService>();
    await platform.openAccessibilitySettings();
  }

  String _formatMeters(double meters) {
    if (meters < 1) {
      return '${(meters * 100).toStringAsFixed(0)} cm';
    } else if (meters < 1000) {
      return '${meters.toStringAsFixed(2)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'scroll much',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Builder(builder: (context) {
                    final isActive = _isServiceEnabled && _isTracking;
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF238636).withOpacity(0.2)
                            : const Color(0xFFDA3633).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF3FB950)
                                  : const Color(0xFFF85149),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? const Color(0xFF3FB950)
                                  : const Color(0xFFF85149),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatMeters(_meters),
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'scrolled',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!_isServiceEnabled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDA3633).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF85149).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF85149),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Accessibility service disabled',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openSettings,
                        child: const Text(
                          'Fix',
                          style: TextStyle(
                            color: Color(0xFFF85149),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isServiceEnabled ? _toggleTracking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking
                        ? const Color(0xFFDA3633)
                        : const Color(0xFF238636),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF30363D),
                    disabledForegroundColor: Colors.white.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTracking ? Icons.pause : Icons.play_arrow,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTracking ? 'Stop Tracking' : 'Start Tracking',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
