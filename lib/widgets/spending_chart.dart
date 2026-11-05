import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Reusable, dependency-free bar chart driven entirely by real saved data.
///
/// Used for:
///  • Dashboard "spending overview" (last 7 days)
///  • Statistics "monthly overview" (last 6 months)
///  • Statistics "daily spending" (current month)
class SpendingChart extends StatelessWidget {
  const SpendingChart({
    super.key,
    required this.labels,
    required this.values,
    this.height = 150,
    this.showValueLabels = false,
    this.animateIntrinsicColors = true,
    this.secondaryValues,
  });

  /// One label per bar (already formatted by the caller).
  final List<String> labels;

  /// Bar heights; must match [labels] length. All-nonzero series auto-scale.
  final List<double> values;

  /// Optional second series (e.g. income) — when provided each slot renders
  /// a paired group of two bars (values = expenses, secondary = income).
  final List<double>? secondaryValues;

  final double height;
  final bool showValueLabels;

  /// Paint bars with the theme's primary colour (always) — this flag exists
  /// to visually single out the max bar via opacity differences.
  final bool animateIntrinsicColors;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    assert(
      labels.length == values.length,
      'SpendingChart labels and values must be parallel lists',
    );

    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final bool grouped =
        secondaryValues != null && secondaryValues!.length == values.length;
    final double maxValue;
    if (grouped) {
      final double m1 = values.reduce((double a, double b) => a > b ? a : b);
      final double m2 = secondaryValues!
          .reduce((double a, double b) => a > b ? a : b);
      maxValue = m1 > m2 ? m1 : m2;
    } else {
      maxValue = values.reduce((double a, double b) => a > b ? a : b);
    }
    final int maxIndex = values.indexOf(
      values.reduce((double a, double b) => a > b ? a : b),
    );

    return SizedBox(
      height: height,
      child: Column(
        children: <Widget>[
          if (grouped)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _LegendDot(
                      color: AppTheme.expenseRed, label: 'Expenses'),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppTheme.incomeGreen, label: 'Income'),
                ],
              ),
            ),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(
                labels: labels,
                values: values,
                secondaryValues: grouped ? secondaryValues : null,
                maxValue: maxValue <= 0 ? 1 : maxValue,
                maxIndex: maxIndex,
                barColor: grouped ? AppTheme.expenseRed : scheme.primary,
                secondaryColor: AppTheme.incomeGreen,
                trackColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                trackOutlineColor: scheme.outlineVariant.withValues(alpha: 0.8),
                labelColor: scheme.onSurfaceVariant,
                valueLabelColor: scheme.onSurface,
                textStyle: theme.textTheme.labelSmall!,
                showValueLabels: showValueLabels,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small colour legend dot + label used by the grouped chart mode.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.labels,
    required this.values,
    required this.secondaryValues,
    required this.maxValue,
    required this.maxIndex,
    required this.barColor,
    required this.secondaryColor,
    required this.trackColor,
    required this.trackOutlineColor,
    required this.labelColor,
    required this.valueLabelColor,
    required this.textStyle,
    required this.showValueLabels,
  });

  final List<String> labels;
  final List<double> values;
  final List<double>? secondaryValues;
  final double maxValue;
  final int maxIndex;
  final Color barColor;
  final Color secondaryColor;
  final Color trackColor;
  final Color trackOutlineColor;
  final Color labelColor;
  final Color valueLabelColor;
  final TextStyle textStyle;
  final bool showValueLabels;

  static const double _barSpacing = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final int count = values.length;
    if (count == 0) return;
    final List<double>? secondary = secondaryValues;
    final bool grouped = secondary != null && secondary.length == count;

    const double bottomLabelHeight = 18;
    final double topInset = showValueLabels ? 16 : 4;
    final double plotHeight = size.height - bottomLabelHeight - topInset;
    if (plotHeight <= 0) return;

    final double slot = size.width / count;

    // ── Grouped mode: paired income/expense bars per slot ────────────────
    if (grouped) {
      final double groupWidth =
          (slot - _barSpacing).clamp(12.0, 56.0).toDouble();
      final double barWidth = groupWidth * 0.44;
      final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

      for (int i = 0; i < count; i++) {
        final double slotCenter = slot * i + slot / 2;
        final double left = slotCenter - groupWidth / 2;
        final double expH =
            plotHeight * (values[i] / maxValue).clamp(0.0, 1.0);
        final double incH =
            plotHeight * (secondary[i] / maxValue).clamp(0.0, 1.0);

        void drawBar(double x, double h, Color color) {
          if (h <= 0) return;
          final Rect r = Rect.fromLTWH(x, topInset + plotHeight - h, barWidth, h);
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              r,
              topLeft: const Radius.circular(4),
              topRight: const Radius.circular(4),
            ),
            Paint()..color = color,
          );
        }

        drawBar(left, expH, barColor);
        drawBar(left + groupWidth - barWidth, incH, secondaryColor);

        tp.text = TextSpan(
          text: labels[i],
          style: textStyle.copyWith(color: labelColor),
        );
        tp.layout(maxWidth: slot + 6);
        tp.paint(
          canvas,
          Offset(slotCenter - tp.width / 2, size.height - bottomLabelHeight),
        );
      }
      return;
    }

    // Slim capsule bars — a deliberately different silhouette from the
    // classic wide rounded-rectangle bars.
    final double barWidth =
        (slot - _barSpacing).clamp(8.0, 46.0).toDouble() * 0.55;

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    // Horizontal grid lines (dashed) give the chart a ledger-like look.
    final Paint gridPaint = Paint()
      ..color = labelColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int g = 1; g <= 3; g++) {
      final double y = topInset + plotHeight * g / 4;
      final Path line = Path();
      for (double x = 0; x < size.width; x += 8) {
        line.moveTo(x, y);
        line.lineTo(x + 4, y);
      }
      canvas.drawPath(line, gridPaint);
    }

    // Trade-graph style trend line behind the bars: connects each day's
    // value across the full plot area so the week's shape reads at a glance.
    if (count > 1) {
      final Path trend = Path();
      for (int i = 0; i < count; i++) {
        final double slotCenter = slot * i + slot / 2;
        final double barH =
            plotHeight * (values[i] / maxValue).clamp(0.0, 1.0);
        final double y = topInset + plotHeight - barH;
        if (i == 0) {
          trend.moveTo(slotCenter, y);
        } else {
          trend.lineTo(slotCenter, y);
        }
      }
      canvas.drawPath(
        trend,
        Paint()
          ..color = barColor.withValues(alpha: 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (int i = 0; i < count; i++) {
      final double slotCenter = slot * i + slot / 2;
      final double barH = plotHeight * (values[i] / maxValue).clamp(0.0, 1.0);

      // Track (full-height neutral bar) only for days that actually have
      // spending. Empty days get a subtle outline so they stay visible
      // against the background without competing with real data.
      final Rect trackRect = Rect.fromLTWH(
        slotCenter - barWidth / 2,
        topInset,
        barWidth,
        plotHeight,
      );
      final RRect trackRRect = RRect.fromRectAndCorners(
        trackRect,
        topLeft: Radius.circular(barWidth / 2),
        topRight: Radius.circular(barWidth / 2),
        bottomLeft: Radius.circular(barWidth / 2),
        bottomRight: Radius.circular(barWidth / 2),
      );
      if (values[i] > 0) {
        canvas.drawRRect(trackRRect, Paint()..color = trackColor);
      } else {
        canvas.drawRRect(
          trackRRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = trackOutlineColor,
        );
      }

      if (values[i] > 0) {
        final Rect barRect = Rect.fromLTWH(
          slotCenter - barWidth / 2,
          topInset + plotHeight - barH,
          barWidth,
          barH,
        );
        final RRect barRRect = RRect.fromRectAndCorners(
          barRect,
          topLeft: Radius.circular(barWidth / 2),
          topRight: Radius.circular(barWidth / 2),
          bottomLeft: Radius.circular(barWidth / 2),
          bottomRight: Radius.circular(barWidth / 2),
        );
        // Peak bar fully opaque; others slightly dimmed for hierarchy.
        final Paint paint = Paint()
          ..color = i == maxIndex
              ? barColor
              : barColor.withValues(alpha: 0.85);
        canvas.drawRRect(barRRect, paint);
      }

      // X label under each bar.
      tp.text = TextSpan(text: labels[i], style: textStyle.copyWith(color: labelColor));
      tp.layout(maxWidth: slot + 6);
      tp.paint(
        canvas,
        Offset(slotCenter - tp.width / 2, size.height - bottomLabelHeight),
      );

      // Optional value above the peak bar.
      if (showValueLabels && i == maxIndex && values[i] > 0) {
        final String valueText = CurrencyFormatter.formatShort(values[i]);
        tp.text = TextSpan(
          text: valueText,
          style: textStyle.copyWith(color: valueLabelColor, fontWeight: FontWeight.w700),
        );
        tp.layout(maxWidth: size.width);
        tp.paint(
          canvas,
          Offset(
            slotCenter - tp.width / 2,
            (topInset + plotHeight - barH - 16).clamp(0.0, size.height),
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.values != values ||
      oldDelegate.secondaryValues != secondaryValues ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.maxIndex != maxIndex ||
      oldDelegate.barColor != barColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.trackOutlineColor != trackOutlineColor ||
      oldDelegate.showValueLabels != showValueLabels;
}
