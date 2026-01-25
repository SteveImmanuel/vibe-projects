import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dim_provider.dart';
import '../widgets/dim_slider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<DimProvider>(
          builder: (context, provider, _) {
            final allPermissionsGranted = 
                provider.hasOverlayPermission && provider.hasBatteryOptimization;
            
            return SingleChildScrollView(
              physics: allPermissionsGranted 
                  ? const NeverScrollableScrollPhysics() 
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildDimDisplay(provider),
                    const SizedBox(height: 32),
                    _buildSlider(provider),
                    const SizedBox(height: 32),
                    _buildToggleButton(provider),
                    const SizedBox(height: 24),
                    _buildPermissionCards(provider),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.nightlight_round,
          color: Color(0xFF6366F1),
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'Midnight Filter',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'extra dim for your eyes',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDimDisplay(DimProvider provider) {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: provider.isServiceRunning 
                  ? const Color(0xFF6366F1) 
                  : const Color(0xFF2A2A3E),
              width: 3,
            ),
            boxShadow: provider.isServiceRunning
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${provider.dimPercent}',
                  style: TextStyle(
                    color: provider.isServiceRunning 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.5),
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    color: provider.isServiceRunning 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.white.withOpacity(0.3),
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          provider.isServiceRunning ? 'ACTIVE' : 'INACTIVE',
          style: TextStyle(
            color: provider.isServiceRunning 
                ? const Color(0xFF6366F1) 
                : Colors.white.withOpacity(0.3),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(DimProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
              Text(
                '90%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DimSlider(
          value: provider.dimLevel,
          onChanged: provider.setDimLevel,
        ),
      ],
    );
  }

  Widget _buildToggleButton(DimProvider provider) {
    return GestureDetector(
      onTap: provider.toggleService,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: provider.isServiceRunning 
              ? const Color(0xFF6366F1) 
              : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: provider.isServiceRunning 
                ? const Color(0xFF6366F1) 
                : const Color(0xFF2A2A3E),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            provider.isServiceRunning ? 'TURN OFF' : 'TURN ON',
            style: TextStyle(
              color: provider.isServiceRunning 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCards(DimProvider provider) {
    return Column(
      children: [
        if (!provider.hasOverlayPermission)
          _buildPermissionCard(
            icon: Icons.layers,
            title: 'Display Over Apps',
            subtitle: 'Required for dimming overlay',
            onTap: provider.requestOverlayPermission,
          ),
        if (!provider.hasBatteryOptimization) ...[
          if (!provider.hasOverlayPermission) const SizedBox(height: 12),
          _buildPermissionCard(
            icon: Icons.battery_saver,
            title: 'Battery Optimization',
            subtitle: 'Keep filter running in background',
            onTap: provider.requestBatteryOptimization,
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
