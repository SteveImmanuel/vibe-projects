import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers.dart';
import '../../core/repositories/stats_repository.dart';

/// GRAPH tab: a per-day progress line for a chosen metric.
class GraphTab extends ConsumerStatefulWidget {
  const GraphTab({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends ConsumerState<GraphTab> {
  GraphMetric _metric = GraphMetric.estimated1rm;

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(
        graphProvider((exerciseId: widget.exercise.id, metric: _metric)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Metric:'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<GraphMetric>(
                  isExpanded: true,
                  value: _metric,
                  items: [
                    for (final m in GraphMetric.values)
                      DropdownMenuItem(value: m, child: Text(m.label)),
                  ],
                  onChanged: (v) => setState(() => _metric = v ?? _metric),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: points.isEmpty
              ? Center(
                  child: Text('No data yet',
                      style: TextStyle(color: Theme.of(context).hintColor)))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                  child: _chart(points),
                ),
        ),
      ],
    );
  }

  Widget _chart(List<MetricPoint> points) {
    final color = Theme.of(context).colorScheme.primary;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final labelEvery = (points.length / 4).clamp(1, double.infinity).floorToDouble();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 2,
            dotData: FlDotData(show: points.length <= 40),
            belowBarData: BarAreaData(
                show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: labelEvery,
              getTitlesWidget: (value, _) {
                final i = value.round();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].date.substring(5),
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
