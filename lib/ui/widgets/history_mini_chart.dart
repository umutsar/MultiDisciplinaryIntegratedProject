import 'package:flutter/material.dart';
import 'package:ai_vehicle_counter/models/vehicle_count.dart';
import 'package:ai_vehicle_counter/l10n/app_localizations.dart';

/// Basit ve bağımlılıksız mini grafik (line chart).
///
/// - Yatay eksen: zaman (liste sırası; soldan sağa eski -> yeni)
/// - Dikey eksen: count
class HistoryMiniChart extends StatelessWidget {
  const HistoryMiniChart({
    super.key,
    required this.items,
    this.height = 140,
  });

  final List<HistoryItem> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            l10n?.noData ?? 'No data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    // Ekranda soldan sağa eski -> yeni göstermek için ters çeviriyoruz
    final points = items.reversed.toList(growable: false);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _HistoryMiniChartPainter(
          theme: Theme.of(context),
          points: points,
        ),
      ),
    );
  }
}

class _HistoryMiniChartPainter extends CustomPainter {
  _HistoryMiniChartPainter({
    required this.theme,
    required this.points,
  });

  final ThemeData theme;
  final List<HistoryItem> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Card zaten arka plan rengi veriyor; burada ekstra "iç kutu" hissi
    // yaratmamak için background doldurmuyoruz.

    // Dark mode'da yan boşluk hissini azaltmak için yatay padding'i minimumda tut.
    // Alt kısım label alanı için korunuyor.
    const adjustedPadding = EdgeInsets.fromLTRB(0, 12, 0, 18);
    final chart = Rect.fromLTWH(
      adjustedPadding.left,
      adjustedPadding.top,
      size.width - adjustedPadding.left - adjustedPadding.right,
      size.height - adjustedPadding.top - adjustedPadding.bottom,
    );

    if (chart.width <= 0 || chart.height <= 0) return;

    final values = points.map((e) => e.count).toList(growable: false);
    // "3 değeri 0 gibi görünüyor" algısını azaltmak için grafiği 0 tabanlı ölçekle.
    // (Count negatif olamaz varsayımı.)
    int minV = 0;
    int maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV == minV) maxV = minV + 1;

    final gridPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    // 3 yatay grid çizgisi
    for (int i = 0; i <= 2; i++) {
      final y = chart.top + (chart.height * i / 2);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    final n = points.length;
    final dx = n <= 1 ? 0.0 : chart.width / (n - 1);

    double mapY(int v) {
      final t = (v - minV) / (maxV - minV);
      return chart.bottom - (t * chart.height);
    }

    final List<Offset> pts = List<Offset>.generate(n, (i) {
      final x = chart.left + dx * i;
      final y = mapY(points[i].count);
      return Offset(x, y);
    }, growable: false);

    Path smoothPath(List<Offset> p) {
      if (p.isEmpty) return Path();
      if (p.length == 1) {
        return Path()..addOval(Rect.fromCircle(center: p.first, radius: 1));
      }
      const double tension = 1.0;
      final path = Path()..moveTo(p[0].dx, p[0].dy);
      for (int i = 0; i < p.length - 1; i++) {
        final p0 = p[i == 0 ? i : i - 1];
        final p1 = p[i];
        final p2 = p[i + 1];
        final p3 = p[(i + 2) < p.length ? (i + 2) : (p.length - 1)];

        final cp1 = p1 + (p2 - p0) * (tension / 6.0);
        final cp2 = p2 - (p3 - p1) * (tension / 6.0);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      }
      return path;
    }

    final linePath = smoothPath(pts);
    final fillPath = Path()
      ..moveTo(chart.left, chart.bottom)
      ..lineTo(pts.first.dx, pts.first.dy)
      ..addPath(linePath, Offset.zero)
      ..lineTo(chart.right, chart.bottom)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.28),
        theme.colorScheme.primary.withValues(alpha: 0.00),
      ],
    );
    fillPaint.shader = fillGradient.createShader(chart);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // Noktalar
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(pts[i], 2.5, dotPaint);
    }

    // Alt etiketler: sadece ilk ve son zamanı yaz (kalabalık olmasın)
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
    );
    if (textStyle != null) {
      const labelInset = 8.0;
      void drawLabel(String text, double x, TextAlign align) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.ltr,
          textAlign: align,
        )..layout(maxWidth: chart.width);
        final dx = align == TextAlign.right
            ? x - tp.width
            : align == TextAlign.center
                ? x - tp.width / 2
                : x;
        // Etiketler card'dan taşmasın diye biraz içeri al.
        final clampedDx = dx.clamp(labelInset, size.width - tp.width - labelInset);
        tp.paint(canvas, Offset(clampedDx, chart.bottom + 4));
      }

      drawLabel(points.first.time, chart.left, TextAlign.left);
      drawLabel(points.last.time, chart.right, TextAlign.right);
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryMiniChartPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      final a = oldDelegate.points[i];
      final b = points[i];
      if (a.count != b.count ||
          a.time != b.time ||
          a.timestamp.millisecondsSinceEpoch != b.timestamp.millisecondsSinceEpoch) {
        return true;
      }
    }
    return false;
  }
}

