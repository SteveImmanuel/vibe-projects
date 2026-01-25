import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scroll_platform_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isServiceEnabled = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    setState(() => _isChecking = true);
    final platform = context.read<ScrollPlatformService>();
    final enabled = await platform.isServiceEnabled();
    setState(() {
      _isServiceEnabled = enabled;
      _isChecking = false;
    });
  }

  Future<void> _openSettings() async {
    final platform = context.read<ScrollPlatformService>();
    await platform.openAccessibilitySettings();
  }

  Future<void> _completeOnboarding() async {
    final storage = context.read<StorageService>();
    await storage.setOnboardingComplete(true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'scroll\nmuch',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track how far your thumb travels.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isServiceEnabled
                                ? const Color(0xFF238636)
                                : const Color(0xFF30363D),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isServiceEnabled ? Icons.check : Icons.touch_app,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accessibility Permission',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _isServiceEnabled
                                    ? 'Enabled'
                                    : 'Required for tracking',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isServiceEnabled
                                      ? const Color(0xFF3FB950)
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ScrollMuch needs accessibility access to count scroll events across apps. Your data stays on device.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isServiceEnabled)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _openSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF238636),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Open Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (!_isServiceEnabled) const SizedBox(height: 12),
                    if (!_isServiceEnabled)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isChecking ? null : _checkServiceStatus,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.7),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white54,
                                  ),
                                )
                              : const Text(
                                  'Check Again',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isServiceEnabled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF238636),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
