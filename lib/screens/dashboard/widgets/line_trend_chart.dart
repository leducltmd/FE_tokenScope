import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Điểm dữ liệu trên biểu đồ đường xu hướng 30 ngày.
class TsLinePoint {
  const TsLinePoint({
    required this.label,
    required this.value,
    this.date,
    this.isPeak = false,
  });

  /// Nhãn hiển thị (ví dụ "12/10" hoặc "N1").
  final String label;

  /// Số lượng token (giá trị trục Y).
  final double value;

  /// Ngày tương ứng (tùy chọn).
  final DateTime? date;

  /// Đánh dấu điểm cao nhất để hiển thị tooltip nổi bật.
  final bool isPeak;
}

/// Biểu đồ đường mượt mà hiển thị xu hướng sử dụng token 30 ngày qua.
///
/// Thiết kế theo phong cách Minimalism & Modern Analytics:
/// - Đường cong Bezier mượt mà (smooth cubic spline) với hiệu ứng gradient phủ mờ bên dưới.
/// - Điểm đỉnh (Peak indicator) có vòng hào quang và thẻ giá trị nổi bật.
/// - Đường lưới mờ và các mốc thời gian phân bổ đều ở đáy.
/// - Hiệu ứng hoạt họa chuyển cảnh mượt mà khi người dùng chọn tab 30 ngày.
class TsLineTrendChart extends StatefulWidget {
  const TsLineTrendChart({
    super.key,
    required this.points,
    this.height = 180,
  });

  final List<TsLinePoint> points;
  final double height;

  @override
  State<TsLineTrendChart> createState() => _TsLineTrendChartState();
}

class _TsLineTrendChartState extends State<TsLineTrendChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  @override
  void didUpdateWidget(covariant TsLineTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 32,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Chưa có dữ liệu xu hướng 30 ngày',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Xác định điểm cao nhất
    final maxValue = widget.points.fold<double>(
      0,
      (max, p) => p.value > max ? p.value : max,
    );

    final normalizedPoints = widget.points.map((p) {
      final isPeak = maxValue > 0 && p.value == maxValue;
      return TsLinePoint(
        label: p.label,
        value: p.value,
        date: p.date,
        isPeak: isPeak,
      );
    }).toList();

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _LineTrendPainter(
              points: normalizedPoints,
              maxValue: maxValue <= 0 ? 1000 : maxValue,
              progress: Curves.easeOutCubic.transform(_controller.value),
              lineColor: AppColors.primary,
              textDirection: Directionality.of(context),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _LineTrendPainter extends CustomPainter {
  _LineTrendPainter({
    required this.points,
    required this.maxValue,
    required this.progress,
    required this.lineColor,
    required this.textDirection,
  });

  final List<TsLinePoint> points;
  final double maxValue;
  final double progress;
  final Color lineColor;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const topPadding = 28.0;
    const bottomPadding = 24.0;
    const horizontalPadding = 16.0;

    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - topPadding - bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    // 1. Vẽ các đường lưới ngang mờ (Grid lines)
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridLines = 3;
    for (var i = 0; i <= gridLines; i++) {
      final y = topPadding + (chartHeight / gridLines) * i;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    // 2. Tính toán toạ độ (X, Y) của các điểm
    final count = points.length;
    final stepX = count <= 1 ? 0.0 : chartWidth / (count - 1);

    final offsets = <Offset>[];
    int peakIndex = -1;
    double maxVal = -1;

    for (var i = 0; i < count; i++) {
      final pt = points[i];
      final x = horizontalPadding + i * stepX;
      // Chuẩn hoá tỷ lệ theo maxValue
      final ratio = (pt.value / maxValue).clamp(0.0, 1.0);
      final y = topPadding + chartHeight * (1.0 - ratio * progress);
      offsets.add(Offset(x, y));

      if (pt.value > maxVal) {
        maxVal = pt.value;
        peakIndex = i;
      }
    }

    // 3. Xây dựng đường cong Bezier (Cubic Spline Path)
    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);

    for (var i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 4. Vẽ vùng phủ gradient (Area fill) dưới đường cong
    final fillPath = Path.from(linePath);
    fillPath.lineTo(offsets.last.dx, topPadding + chartHeight);
    fillPath.lineTo(offsets.first.dx, topPadding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.30 * progress),
          lineColor.withValues(alpha: 0.02 * progress),
        ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Vẽ viền đường cong chính (Line stroke)
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // 6. Vẽ điểm đỉnh (Peak point highlight) và tooltip
    if (peakIndex >= 0 && peakIndex < offsets.length && progress > 0.6) {
      final peakOffset = offsets[peakIndex];
      final alphaAnim = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);

      // Quầng hào quang ngoài
      final haloPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.22 * alphaAnim)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peakOffset, 8, haloPaint);

      // Chấm viền chính
      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peakOffset, 4.5, dotBorderPaint);

      final dotCenterPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peakOffset, 3, dotCenterPaint);

      // Thẻ giá trị đỉnh nổi trên điểm đỉnh
      final peakPt = points[peakIndex];
      final text = peakPt.value >= 1000
          ? '${(peakPt.value / 1000).toStringAsFixed(1)}k'
          : peakPt.value.toStringAsFixed(0);
      final labelText = 'Đỉnh: $text';

      final tp = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: textDirection,
      )..layout();

      const pillPaddingH = 6.0;
      const pillPaddingV = 2.5;
      final pillW = tp.width + pillPaddingH * 2;
      final pillH = tp.height + pillPaddingV * 2;

      // Giữ tooltip không bị tràn lề 2 bên
      final pillX = (peakOffset.dx - pillW / 2).clamp(
        horizontalPadding,
        size.width - horizontalPadding - pillW,
      );
      final pillY = math.max(2.0, peakOffset.dy - pillH - 6.0);

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillX, pillY, pillW, pillH),
        const Radius.circular(6),
      );

      final pillPaint = Paint()
        ..color = AppColors.navy.withValues(alpha: 0.92 * alphaAnim)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(pillRect, pillPaint);

      tp.paint(
        canvas,
        Offset(pillX + pillPaddingH, pillY + pillPaddingV),
      );
    }

    // 7. Nhãn các mốc ngày ở trục X dưới đáy (chọn tối đa 5 mốc phân bổ đều)
    if (count > 0) {
      final labelIndices = <int>[];
      if (count <= 5) {
        for (var i = 0; i < count; i++) {
          labelIndices.add(i);
        }
      } else {
        labelIndices.add(0);
        labelIndices.add((count * 0.25).round());
        labelIndices.add((count * 0.5).round());
        labelIndices.add((count * 0.75).round());
        labelIndices.add(count - 1);
      }

      for (final idx in labelIndices) {
        final pt = points[idx];
        final x = offsets[idx].dx;
        final tp = TextPainter(
          text: TextSpan(
            text: pt.label,
            style: TextStyle(
              color: AppColors.secondaryText.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: textDirection,
        )..layout();

        final labelX = (x - tp.width / 2).clamp(
          horizontalPadding,
          size.width - horizontalPadding - tp.width,
        );
        final labelY = size.height - bottomPadding + 6;
        tp.paint(canvas, Offset(labelX, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.maxValue != maxValue;
  }
}
