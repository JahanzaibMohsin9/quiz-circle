import 'package:flutter/material.dart';

class SimpleBarChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color barColor;

  const SimpleBarChart({
    super.key,
    required this.data,
    required this.title,
    this.barColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
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
            child: Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final maxValue = data
        .map((item) => item.value)
        .reduce((a, b) => a > b ? a : b);
    final chartHeight = 200.0;

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
          height: chartHeight,
          child: Row(
            children: data.asMap().entries.map((entry) {
              final item = entry.value;
              final barHeight = (item.value / maxValue) * chartHeight;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SimpleLineChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color lineColor;

  const SimpleLineChart({
    super.key,
    required this.data,
    required this.title,
    this.lineColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
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
            child: Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final maxValue = data
        .map((item) => item.value)
        .reduce((a, b) => a > b ? a : b);
    final chartHeight = 200.0;

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
          height: chartHeight,
          child: CustomPaint(
            painter: LineChartPainter(
              data: data,
              maxValue: maxValue,
              lineColor: lineColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class SimplePieChart extends StatelessWidget {
  final List<PieChartData> data;
  final String title;

  const SimplePieChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
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
            child: Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
          child: Row(
            children: data.map((item) {
              final percentage = item.value;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
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

class PieChartData {
  final String label;
  final double value;
  final Color color;

  PieChartData({required this.label, required this.value, required this.color});
}

class LineChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double maxValue;
  final Color lineColor;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (data.isNotEmpty) {
      for (int i = 0; i < data.length - 1; i++) {
        final x1 = (i / (data.length - 1)) * size.width;
        final y1 = size.height - (data[i].value / maxValue) * size.height;
        final x2 = ((i + 1) / (data.length - 1)) * size.width;
        final y2 = size.height - (data[i + 1].value / maxValue) * size.height;

        path.moveTo(x1, y1);
        path.lineTo(x2, y2);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].value / maxValue) * size.height;

      canvas.drawCircle(Offset(x, y), 4.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
