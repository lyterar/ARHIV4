import 'package:flutter/material.dart';

import '../../logic/date_utils.dart';
import '../../logic/period_stats.dart';
import '../format.dart';
import '../theme.dart';

/// Линейный график показателя по дням. Нарисован вручную через CustomPainter,
/// без сторонних библиотек: ось Y — от минимума до максимума, ось X — дни.
class LineChart extends StatelessWidget {
  const LineChart({super.key, required this.points, this.digits = 0, this.height = 200});

  final List<Point> points;
  final int digits;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ChartPainter(points, digits)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.points, this.digits);

  final List<Point> points;
  final int digits;

  static const _left = 44.0; // место под подписи оси Y
  static const _bottom = 22.0; // место под подписи оси X
  static const _top = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final w = size.width - _left - 8;
    final h = size.height - _bottom - _top;

    var lo = points.first.value, hi = points.first.value;
    for (final p in points) {
      if (p.value < lo) lo = p.value;
      if (p.value > hi) hi = p.value;
    }
    // Ровная линия: раздвигаем ось, чтобы она не схлопнулась в ноль.
    if (hi == lo) {
      final base = lo;
      hi = base + 1;
      lo = base >= 1 ? base - 1 : 0.0;
    }

    double x(int i) => _left + (points.length == 1 ? w / 2 : w * i / (points.length - 1));
    double y(double v) => _top + h - (v - lo) / (hi - lo) * h;

    // Сетка: 3 горизонтальные линии с подписями.
    final grid = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final v = lo + (hi - lo) * k / 2;
      final yy = y(v);
      canvas.drawLine(Offset(_left, yy), Offset(_left + w, yy), grid);
      _text(canvas, fmtNum(v, digits: digits), Offset(0, yy - 7), 40, TextAlign.right);
    }

    // Подписи оси X: первая, средняя и последняя даты.
    final idx = <int>{0, points.length ~/ 2, points.length - 1};
    for (final i in idx) {
      _text(canvas, ruShort(points[i].day), Offset(x(i) - 20, _top + h + 6), 40, TextAlign.center);
    }

    // Заливка под линией + сама линия.
    final line = Path()..moveTo(x(0), y(points[0].value));
    for (var i = 1; i < points.length; i++) {
      line.lineTo(x(i), y(points[i].value));
    }
    final fill = Path.from(line)
      ..lineTo(x(points.length - 1), _top + h)
      ..lineTo(x(0), _top + h)
      ..close();
    canvas.drawPath(fill, Paint()..color = AppColors.accent.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Точки по дням (при 30 точках — помельче).
    final dot = Paint()..color = AppColors.accent;
    final r = points.length > 10 ? 2.5 : 4.0;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(x(i), y(points[i].value)), r, dot);
    }
  }

  void _text(Canvas c, String s, Offset at, double width, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, at);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.points != points || old.digits != digits;
}
