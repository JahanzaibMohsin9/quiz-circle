import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;

class AnalyticsBarChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color barColor;
  final double? maxY;
  final bool showGrid;

  const AnalyticsBarChart({
    super.key,
    required this.data,
    required this.title,
    this.barColor = Colors.blue,
    this.maxY,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: fl_chart.BarChart(
            fl_chart.BarChartData(
              alignment: fl_chart.BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: fl_chart.BarTouchData(
                enabled: true,
                touchTooltipData: fl_chart.BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return fl_chart.BarTooltipItem(
                      '${data[group.x.toInt()].label}\n${data[group.x.toInt()].value.toStringAsFixed(1)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: fl_chart.FlTitlesData(
                bottomTitles: fl_chart.AxisTitles(
                  sideTitles: fl_chart.SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data[value.toInt()].label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: fl_chart.AxisTitles(
                  sideTitles: fl_chart.SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const fl_chart.AxisTitles(),
                rightTitles: const fl_chart.AxisTitles(),
              ),
              borderData: fl_chart.FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return fl_chart.BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    fl_chart.BarChartRodData(
                      toY: entry.value.value,
                      color: barColor,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              gridData: fl_chart.FlGridData(
                show: showGrid,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return fl_chart.FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnalyticsLineChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color lineColor;
  final double? maxY;
  final bool showGrid;
  final bool showDots;

  const AnalyticsLineChart({
    super.key,
    required this.data,
    required this.title,
    this.lineColor = Colors.blue,
    this.maxY,
    this.showGrid = true,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: fl_chart.LineChart(
            fl_chart.LineChartData(
              lineTouchData: fl_chart.LineTouchData(
                touchTooltipData: fl_chart.LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return fl_chart.LineTooltipItem(
                        '${data[spot.x.toInt()].label}\n${spot.y.toStringAsFixed(1)}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: fl_chart.FlGridData(
                show: showGrid,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return fl_chart.FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: fl_chart.FlTitlesData(
                bottomTitles: fl_chart.AxisTitles(
                  sideTitles: fl_chart.SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data[value.toInt()].label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: fl_chart.AxisTitles(
                  sideTitles: fl_chart.SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const fl_chart.AxisTitles(),
                rightTitles: const fl_chart.AxisTitles(),
              ),
              borderData: fl_chart.FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                fl_chart.LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return fl_chart.FlSpot(
                      entry.key.toDouble(),
                      entry.value.value,
                    );
                  }).toList(),
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: fl_chart.FlDotData(
                    show: showDots,
                    getDotPainter: (spot, percent, barData, index) {
                      return fl_chart.FlDotCirclePainter(
                        radius: 4,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: fl_chart.BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnalyticsPieChart extends StatelessWidget {
  final List<AnalyticsPieData> data;
  final String title;
  final double? radius;

  const AnalyticsPieChart({
    super.key,
    required this.data,
    required this.title,
    this.radius = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: radius! * 2 + 40,
          child: fl_chart.PieChart(
            fl_chart.PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: radius! * 0.6,
              sections: data.asMap().entries.map((entry) {
                final item = entry.value;
                return fl_chart.PieChartSectionData(
                  color: item.color,
                  value: item.value,
                  title: '${item.value.toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...data.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${item.value.toStringAsFixed(1)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}

class AnalyticsPieData {
  final String label;
  final double value;
  final Color color;

  AnalyticsPieData({
    required this.label,
    required this.value,
    required this.color,
  });
}
