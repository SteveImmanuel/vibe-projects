import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_scroll.dart';
import '../services/scroll_platform_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  double _meters = 0.0;
  bool _isTracking = true;
  bool _isServiceEnabled = false;
  List<AppScroll> _apps = [];
  final Map<String, Uint8List?> _iconCache = {};
  Timer? _refreshTimer;
  bool _refreshing = false;

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
      _refresh();
    });
  }

  Future<void> _loadState() async {
    final platform = context.read<ScrollPlatformService>();

    final meters = await platform.getTodayScrollMeters();
    final tracking = await platform.isTrackingEnabled();
    final serviceEnabled = await platform.isServiceEnabled();
    final apps = await platform.getPerAppScrollMeters();
    await _ensureIcons(platform, apps);

    if (!mounted) return;
    setState(() {
      _meters = meters;
      _isTracking = tracking;
      _isServiceEnabled = serviceEnabled;
      _apps = apps;
    });
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    try {
      final platform = context.read<ScrollPlatformService>();

      final meters = await platform.getTodayScrollMeters();
      final apps = await platform.getPerAppScrollMeters();
      await _ensureIcons(platform, apps);

      if (!mounted) return;
      setState(() {
        _meters = meters;
        _apps = apps;
      });
    } finally {
      _refreshing = false;
    }
  }

  /// Fetches and caches each app's icon once, so the 2s refresh stays cheap.
  Future<void> _ensureIcons(
      ScrollPlatformService platform, List<AppScroll> apps) async {
    for (final app in apps) {
      if (_iconCache.containsKey(app.package)) continue;
      _iconCache[app.package] = await platform.getAppIcon(app.package);
    }
  }

  Future<void> _toggleTracking() async {
    final platform = context.read<ScrollPlatformService>();

    final newValue = !_isTracking;
    await platform.setTrackingEnabled(newValue);

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
              const SizedBox(height: 40),
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
                        fontSize: 64,
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
              const SizedBox(height: 32),
              Text(
                'BY APP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _apps.isEmpty
                    ? Center(
                        child: Text(
                          'No app activity yet today',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _apps.length,
                        itemBuilder: (context, index) =>
                            _buildAppTile(_apps[index]),
                      ),
              ),
              const SizedBox(height: 16),
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

  Widget _buildAppTile(AppScroll app) {
    final icon = _iconCache[app.package];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: icon != null
                ? Image.memory(
                    icon,
                    width: 36,
                    height: 36,
                    gaplessPlayback: true,
                  )
                : Container(
                    width: 36,
                    height: 36,
                    color: const Color(0xFF30363D),
                    child: const Icon(
                      Icons.apps,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatMeters(app.meters),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
