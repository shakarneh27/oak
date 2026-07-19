import 'package:flutter/material.dart';

import 'parent_palette.dart';

/// Orange area chart of learning minutes per weekday — a dependency-free
/// port of the reference's Recharts AreaChart.
class WeeklyMinutesChart extends StatelessWidget {
  final List<int> minutes;
  final List<String> dayLabels;

  const WeeklyMinutesChart({
    super.key,
    required this.minutes,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _AreaChartPainter(minutes: minutes),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final label in dayLabels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8.5, color: Colors.grey.shade400),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<int> minutes;

  _AreaChartPainter({required this.minutes});

  @override
  void paint(Canvas canvas, Size size) {
    if (minutes.isEmpty) return;
    final maxValue = minutes
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(10, 1 << 30);
    final stepX = size.width / (minutes.length - 1).clamp(1, 100);

    Offset point(int i) => Offset(
      // RTL: first day (Sunday) on the right
      size.width - i * stepX,
      size.height - (minutes[i] / maxValue) * (size.height - 10) - 4,
    );

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < minutes.length; i++) {
      final prev = point(i - 1);
      final curr = point(i);
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      line.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      if (i == minutes.length - 1) line.lineTo(curr.dx, curr.dy);
    }

    // gradient fill under the line
    final area = Path.from(line)
      ..lineTo(point(minutes.length - 1).dx, size.height)
      ..lineTo(point(0).dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ParentPalette.orange.withValues(alpha: 0.3),
            ParentPalette.orange.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = ParentPalette.orange,
    );

    final dot = Paint()..color = ParentPalette.orange;
    for (var i = 0; i < minutes.length; i++) {
      canvas.drawCircle(point(i), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) =>
      oldDelegate.minutes != minutes;
}
