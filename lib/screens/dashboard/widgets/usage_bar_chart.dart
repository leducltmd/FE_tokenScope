import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../dashboard_models.dart';

/// Biểu đồ cột chiều dọc — hiển thị lượng token theo từng ngày trong tuần.
///
/// Cột được vẽ bằng [CustomPainter] để giữ nhịp cách 4 / 8 px và bo góc
/// mềm ở đỉnh.
class TsUsageBarChart extends StatelessWidget {
  const TsUsageBarChart({
    super.key,
    required this.points,
    this.height = 150,
    this.highlightColor = AppColors.primary,
    this.restColor = AppColors.primaryBorder,
  });

  final List<UsagePoint> points;
  final double height;
  final Color highlightColor;
  final Color restColor;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<int>(
      0,
      (max, p) => p.value > max ? p.value : max,
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _BarChartPainter(
                points: points,
                maxValue: maxValue,
                highlightColor: highlightColor,
                restColor: restColor,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              for (final point in points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.points,
    required this.maxValue,
    required this.highlightColor,
    required this.restColor,
  });

  final List<UsagePoint> points;
  final int maxValue;
  final Color highlightColor;
  final Color restColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || maxValue <= 0) return;

    const barRadius = Radius.circular(4);
    final slot = size.width / points.length;
    final barWidth = (slot - AppSpacing.space8).clamp(8.0, 32.0);

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final ratio = point.value / maxValue;
      final barHeight = (size.height * ratio).clamp(4.0, size.height);
      final left = slot * i + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
        topLeft: barRadius,
        topRight: barRadius,
      );

      canvas.drawRRect(
        rect,
        Paint()
          ..color = point.isHighlighted ? highlightColor : restColor
          ..style = PaintingStyle.fill,
      );
    }

    // Đường nền của trục.
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.restColor != restColor;
  }
}
