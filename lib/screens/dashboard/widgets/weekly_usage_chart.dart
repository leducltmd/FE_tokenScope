import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Một cột trong biểu đồ 7 ngày.
class TsWeeklyPoint {
  const TsWeeklyPoint({
    required this.label,
    required this.value,
    required this.display,
    this.isHighlighted = false,
  });

  /// Nhãn ngày — T2 … CN.
  final String label;

  /// Giá trị tuyệt đối (token) — dùng để tính tỷ lệ chiều cao cột.
  final double value;

  /// Giá trị hiển thị rút gọn — ví dụ "450k".
  final String display;

  final bool isHighlighted;
}

/// Biểu đồ cột 7 ngày — cột nổi bật màu xanh dương rực kèm thẻ tooltip.
///
/// Cột vẽ bằng [CustomPainter]; thẻ giá trị hiển thị phía trên cột nổi bật.
class TsWeeklyChart extends StatefulWidget {
  const TsWeeklyChart({
    super.key,
    required this.points,
    this.height = 168,
    this.maxValue = 500000,
  });

  final List<TsWeeklyPoint> points;
  final double height;

  /// Ngưỡng trên cùng của trục — mọi cột chuẩn hoá theo giá trị này.
  final double maxValue;

  @override
  State<TsWeeklyChart> createState() => _TsWeeklyChartState();
}

class _TsWeeklyChartState extends State<TsWeeklyChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _WeeklyChartPainter(
                    points: widget.points,
                    maxValue: widget.maxValue,
                    progress: Curves.easeOutCubic.transform(_controller.value),
                    textDirection: Directionality.of(context),
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              for (final point in widget.points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: point.isHighlighted
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: point.isHighlighted
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

class _WeeklyChartPainter extends CustomPainter {
  _WeeklyChartPainter({
    required this.points,
    required this.maxValue,
    required this.progress,
    required this.textDirection,
  });

  final List<TsWeeklyPoint> points;
  final double maxValue;
  final double progress;
  final TextDirection textDirection;

  static const _restColor = Color(0xFFDDE3F5);
  static const _highlightColor = AppColors.azure;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || maxValue <= 0) return;

    const barRadius = Radius.circular(6);
    final slot = size.width / points.length;
    final barWidth = (slot - 14).clamp(10.0, 26.0);
    const labelSpace = 26.0;
    final chartHeight = size.height - labelSpace;

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final normalized = (point.value / maxValue).clamp(0.08, 1.0);
      final barHeight = chartHeight * normalized * progress;
      final left = slot * i + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight),
        topLeft: barRadius,
        topRight: barRadius,
      );

      canvas.drawRRect(
        rect,
        Paint()
          ..color = point.isHighlighted ? _highlightColor : _restColor
          ..style = PaintingStyle.fill,
      );

      if (point.isHighlighted) {
        _paintTooltip(
          canvas,
          size,
          point,
          left,
          barWidth,
          chartHeight - barHeight,
        );
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

  /// Thẻ tooltip giá trị phía trên cột nổi bật.
  void _paintTooltip(
    Canvas canvas,
    Size size,
    TsWeeklyPoint point,
    double left,
    double barWidth,
    double top,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: point.display,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    const padH = 8.0;
    const padV = 5.0;
    final boxW = painter.width + padH * 2;
    final boxH = painter.height + padV * 2;

    var boxLeft = left + (barWidth - boxW) / 2;
    boxLeft = boxLeft.clamp(0.0, size.width - boxW);
    var boxTop = top - boxH - 8;
    if (boxTop < 0) boxTop = top + 8;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, boxTop, boxW, boxH),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, Paint()..color = AppColors.azure);

    // Mũi tên nhỏ nối thẻ với cột.
    final tail = Path()
      ..moveTo(left + barWidth / 2 - 5, boxTop + boxH - 1)
      ..lineTo(left + barWidth / 2 + 5, boxTop + boxH - 1)
      ..lineTo(left + barWidth / 2, boxTop + boxH + 5)
      ..close();
    canvas.drawPath(tail, Paint()..color = AppColors.azure);

    painter.paint(canvas, Offset(boxLeft + padH, boxTop + padV));
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.maxValue != maxValue;
  }
}
