import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom bar chart drawn using standard Flutter container boxes and flex layouts.
class CustomBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color barColor;

  const CustomBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    final maxValue = values.reduce(math.max);
    final theme = Theme.of(context);

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final val = values[index];
          final pct = maxValue > 0 ? (val / maxValue) : 0.0;
          final label = labels[index];

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: pct.clamp(0.02, 1.0),
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
              ),
              Text(
                val.toStringAsFixed(0),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// A custom line graph drawn using a CustomPainter.
class CustomLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  const CustomLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.lineColor = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(values, lineColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((lbl) {
            return Text(
              lbl,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: Colors.grey),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  _LineChartPainter(this.values, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.01)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final maxValue = values.reduce(math.max);
    final points = <Offset>[];
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final val = values[i];
      final ratio = maxValue > 0 ? (val / maxValue) : 0.0;
      final x = i * stepX;
      final y = size.height - (ratio * size.height * 0.8) - 10;
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final pPrev = points[i - 1];
      final pCur = points[i];
      final cp1 = Offset(pPrev.dx + stepX / 2, pPrev.dy);
      final cp2 = Offset(pCur.dx - stepX / 2, pCur.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pCur.dx, pCur.dy);
    }

    // Draw background gradient
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw main line path
    canvas.drawPath(path, paint);

    // Draw dot markers
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, dotStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// A circular progress ring with centered info labels.
class CustomProgressRing extends StatelessWidget {
  final double percentage;
  final String centerTitle;
  final String centerSubtitle;
  final Color activeColor;

  const CustomProgressRing({
    super.key,
    required this.percentage,
    required this.centerTitle,
    required this.centerSubtitle,
    this.activeColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: CircularProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              strokeWidth: 12,
              backgroundColor: activeColor.withOpacity(0.1),
              color: activeColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTitle,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                centerSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
