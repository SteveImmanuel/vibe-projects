import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/pitch_detector.dart';
import '../practice_controller.dart';

class TunerView extends StatelessWidget {
  const TunerView({super.key, required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final target = controller.target;
    final cents = controller.cents;
    final status = !controller.listening
        ? 'Ready when you are'
        : cents == null
        ? 'Pluck an open string'
        : controller.inTune
        ? 'In tune'
        : cents < 0
        ? 'Tune up'
        : 'Tune down';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Find your sound.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text('Six strings. Standard tuning.', style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        controller.listening ? 'LISTENING' : 'MICROPHONE OFF',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: scheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  target?.label ?? '–',
                  style: TextStyle(fontSize: 76, height: 1.15, fontWeight: FontWeight.w600, color: scheme.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.frequency == null ? 'A4 = 440 Hz' : '${controller.frequency!.toStringAsFixed(1)} Hz',
                  style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Semantics(
                  label: cents == null
                      ? 'No pitch detected'
                      : '${cents.abs().toStringAsFixed(0)} cents ${cents < 0 ? 'flat' : 'sharp'}',
                  child: SizedBox(
                    height: 92,
                    width: double.infinity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (cents ?? 0).clamp(-50.0, 50.0)),
                      duration: const Duration(milliseconds: 160),
                      builder: (context, value, _) => CustomPaint(
                        painter: _TuningMeter(cents: value, active: cents != null, color: scheme.primary),
                      ),
                    ),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 2, child: Text('♭ Flat', style: TextStyle(fontSize: 12))),
                    Expanded(
                      child: Text('0', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Sharp ♯', textAlign: TextAlign.end, style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: controller.inTune ? scheme.primaryContainer : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cents == null
                      ? 'Let each note ring clearly.'
                      : '${cents > 0 ? '+' : ''}${cents.toStringAsFixed(0)} cents',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'YOUR STRINGS',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.3, fontSize: 12),
              ),
            ),
            FilterChip(
              label: const Text('Auto'),
              selected: controller.selectedString == null,
              onSelected: (_) => controller.selectString(null),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 300 ? 2 : 3;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final string in standardStrings)
                  SizedBox(
                    width: (constraints.maxWidth - 10 * (columns - 1)) / columns,
                    child: Semantics(
                      button: true,
                      selected: target == string,
                      label: 'String ${string.number}, ${string.label}, ${string.frequency.toStringAsFixed(1)} hertz',
                      child: Material(
                        color: target == string ? scheme.primaryContainer : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => controller.selectString(string),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            child: Column(
                              children: [
                                Text(
                                  '${string.number} · ${string.label}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${string.frequency.toStringAsFixed(1)} Hz',
                                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          controller.selectedString == null
              ? 'Auto finds the nearest string. Tap a string to lock it.'
              : 'Locked to string ${target!.number} · ${target.label}. Tap Auto to detect any string.',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: controller.busy ? null : controller.toggleTuner,
          icon: Icon(controller.listening ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(
            controller.busy
                ? 'Please wait…'
                : controller.listening
                ? 'Stop listening'
                : 'Listen & tune',
          ),
        ),
      ],
    );
  }
}

class _TuningMeter extends CustomPainter {
  const _TuningMeter({required this.cents, required this.active, required this.color});

  final double cents;
  final bool active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    final center = size.width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center - size.width * 0.045, 4, size.width * 0.09, size.height - 8),
        const Radius.circular(8),
      ),
      paint..color = color.withValues(alpha: 0.09),
    );
    for (var tick = 0; tick <= 20; tick++) {
      final x = 8 + tick / 20 * (size.width - 16);
      final height = tick % 5 == 0 ? 30.0 : 16.0;
      canvas.drawLine(
        Offset(x, 40 - height / 2),
        Offset(x, 40 + height / 2),
        paint
          ..color = color.withValues(alpha: tick == 10 ? 0.9 : 0.25)
          ..strokeWidth = tick == 10 ? 3 : 2,
      );
    }
    if (!active) return;
    final x = (8 + (cents + 50) / 100 * (size.width - 16)).clamp(8.0, math.max(8.0, size.width - 8)).toDouble();
    canvas.drawLine(
      Offset(x, 8),
      Offset(x, 68),
      paint
        ..color = color
        ..strokeWidth = 4,
    );
    canvas.drawCircle(Offset(x, 75), 5, paint);
  }

  @override
  bool shouldRepaint(_TuningMeter oldDelegate) =>
      cents != oldDelegate.cents || active != oldDelegate.active || color != oldDelegate.color;
}
