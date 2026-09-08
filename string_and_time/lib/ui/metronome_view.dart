import 'dart:async';

import 'package:flutter/material.dart';

import '../practice_controller.dart';

class MetronomeView extends StatelessWidget {
  const MetronomeView({super.key, required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Settle into rhythm.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text('Make every beat count.', style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('TEMPO', style: TextStyle(fontSize: 12, letterSpacing: 1.8, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Decrease tempo',
                        onPressed: controller.busy || controller.bpm == 40 ? null : () => _stepTempo(-1),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(width: 24),
                      Semantics(
                        label: '${controller.bpm} beats per minute',
                        child: Text(
                          '${controller.bpm}',
                          style: TextStyle(
                            fontSize: 80,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        tooltip: 'Increase tempo',
                        onPressed: controller.busy || controller.bpm == 240 ? null : () => _stepTempo(1),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const Text('beats per minute'),
                const SizedBox(height: 16),
                Slider(
                  value: controller.bpm.toDouble(),
                  min: 40,
                  max: 240,
                  divisions: 200,
                  label: '${controller.bpm} BPM',
                  semanticFormatterCallback: (value) => '${value.round()} beats per minute',
                  onChanged: controller.busy ? null : (value) => controller.setTempo(value.round()),
                  onChangeEnd: (_) => controller.applyMetronomeSettings(),
                ),
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('40'), Text('240')]),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: controller.busy ? null : controller.tapTempo,
                  icon: const Icon(Icons.touch_app_outlined),
                  label: const Text('Tap tempo'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap twice or more to set your pace.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var beat = 0; beat < controller.beatsPerBar; beat++)
              Semantics(
                label: 'Beat ${beat + 1}',
                selected: controller.playing && controller.beat == beat,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 42,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: controller.playing && controller.beat == beat
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: beat == 0 && controller.accent ? Border.all(color: scheme.primary, width: 2) : null,
                  ),
                  child: Text(
                    '${beat + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: controller.playing && controller.beat == beat ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('BEATS PER BAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final beats in [2, 3, 4, 6])
              ChoiceChip(
                label: Text('$beats beats'),
                selected: controller.beatsPerBar == beats,
                onSelected: controller.busy ? null : (_) => controller.setBeats(beats),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Accent the first beat'),
          subtitle: const Text('A brighter click at the start of each bar.'),
          value: controller.accent,
          onChanged: controller.busy ? null : controller.setAccent,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(controller.volume == 0 ? Icons.volume_off_outlined : Icons.volume_up_outlined),
            Expanded(
              child: Slider(
                value: controller.volume,
                divisions: 20,
                label: '${(controller.volume * 100).round()}%',
                semanticFormatterCallback: (value) => 'Volume ${(value * 100).round()} percent',
                onChanged: controller.busy ? null : controller.setVolume,
                onChangeEnd: (_) => controller.applyMetronomeSettings(),
              ),
            ),
            Text('${(controller.volume * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: controller.busy ? null : controller.toggleMetronome,
          icon: Icon(controller.playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
          label: Text(
            controller.busy
                ? 'Please wait…'
                : controller.playing
                ? 'Stop metronome'
                : 'Start metronome',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Use your phone’s media volume to adjust the speaker level.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _stepTempo(int delta) {
    controller.setTempo(controller.bpm + delta);
    unawaited(controller.applyMetronomeSettings());
  }
}
