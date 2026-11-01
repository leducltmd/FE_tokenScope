import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Một phần trong biểu đồ tròn (donut) của nhà cung cấp.
class TsDonutSlice {
  const TsDonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Biểu đồ tròn rỗng (donut) — vẽ bằng [CustomPainter].
///
/// Ở giữa hiển thị tổng chi phí, xung quanh là các lát cung theo tỷ lệ
/// chi phí của từng nhà cung cấp.
class TsDonutChart extends StatelessWidget {
  const TsDonutChart({
    super.key,
    required this.slices,
    required this.totalLabel,
    this.totalCaption = 'TỔNG',
    this.size = 132,
  });

  final List<TsDonutSlice> slices;
  final String totalLabel;
  final String totalCaption;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(
              slices: slices,
              textDirection: Directionality.of(context),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                totalCaption,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalLabel,
                style: AppTypography.h3.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.textDirection});

  final List<TsDonutSlice> slices;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final strokeWidth = outerRadius * 0.34;
    final rect = Rect.fromCircle(
      center: center,
      radius: outerRadius - strokeWidth / 2,
    );

    const gap = 0.045; // góc bỏ trống giữa các lát.
    var start = -math.pi / 2;

    for (final slice in slices) {
      final sweep = (slice.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

/// Thanh tiến trình ngang cho danh sách mô hình AI.
class TsAnalysisProgressBar extends StatelessWidget {
  const TsAnalysisProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.trackColor = const Color(0xFFEEF2F7),
    this.height = 6,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: trackColor)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.65), color],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Biểu đồ cột 7 ngày dùng riêng cho trang phân tích.
///
/// Cột nổi bật có màu xanh dương đậm và thẻ giá trị phía trên.
class TsAnalysisWeekChart extends StatelessWidget {
  const TsAnalysisWeekChart({
    super.key,
    required this.values,
    required this.labels,
    this.highlightIndex = 3,
    this.height = 150,
  });

  /// Giá trị tuyệt đối của từng ngày.
  final List<double> values;

  /// Nhãn ngày — T2 … CN.
  final List<String> labels;
  final int highlightIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(0, (max, v) => v > max ? v : max);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _AnalysisWeekPainter(
                values: values,
                maxValue: maxValue,
                highlightIndex: highlightIndex,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      fontWeight: i == highlightIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == highlightIndex
                          ? AppColors.navy
                          : AppColors.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisWeekPainter extends CustomPainter {
  _AnalysisWeekPainter({
    required this.values,
    required this.maxValue,
    required this.highlightIndex,
    required this.textDirection,
  });

  final List<double> values;
  final double maxValue;
  final int highlightIndex;
  final TextDirection textDirection;

  static const _restColor = Color(0xFFDCE3F2);
  static const _highlightColor = AppColors.azure;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || maxValue <= 0) return;

    const barRadius = Radius.circular(5);
    final slot = size.width / values.length;
    final barWidth = (slot - 16).clamp(8.0, 22.0);
    const labelSpace = 20.0;
    final chartHeight = size.height - labelSpace;

    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] / maxValue).clamp(0.10, 1.0);
      final barHeight = chartHeight * normalized;
      final left = slot * i + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight),
        topLeft: barRadius,
        topRight: barRadius,
      );

      canvas.drawRRect(
        rect,
        Paint()
          ..color = i == highlightIndex ? _highlightColor : _restColor
          ..style = PaintingStyle.fill,
      );

      if (i == highlightIndex) {
        _paintTooltip(canvas, size, values[i], left, barWidth, chartHeight - barHeight);
      }
    }

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 1,
    );
  }

  void _paintTooltip(
    Canvas canvas,
    Size size,
    double value,
    double left,
    double barWidth,
    double top,
  ) {
    final label = _formatCompact(value);

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    const padH = 7.0;
    const padV = 4.0;
    final boxW = painter.width + padH * 2;
    final boxH = painter.height + padV * 2;

    var boxLeft = left + (barWidth - boxW) / 2;
    boxLeft = boxLeft.clamp(0.0, math.max(0.0, size.width - boxW));
    var boxTop = top - boxH - 7;
    if (boxTop < 0) boxTop = top + 7;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxW, boxH),
        const Radius.circular(7),
      ),
      Paint()..color = _highlightColor,
    );

    final tail = Path()
      ..moveTo(left + barWidth / 2 - 4.5, boxTop + boxH - 1)
      ..lineTo(left + barWidth / 2 + 4.5, boxTop + boxH - 1)
      ..lineTo(left + barWidth / 2, boxTop + boxH + 4.5)
      ..close();
    canvas.drawPath(tail, Paint()..color = _highlightColor);

    painter.paint(canvas, Offset(boxLeft + padH, boxTop + padV));
  }

  static String _formatCompact(double value) {
    if (value >= 1000000) {
      final v = value / 1000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _AnalysisWeekPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}
