import 'package:flutter/material.dart';

class DimSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  
  const DimSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: const Color(0xFF6366F1),
        inactiveTrackColor: const Color(0xFF1E1E2E),
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 14,
          elevation: 4,
        ),
        overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),
      child: Slider(
        value: value,
        min: 0.0,
        max: 0.9,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
