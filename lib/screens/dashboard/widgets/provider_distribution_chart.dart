import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/usage_summary.dart';

/// Màu sắc thương hiệu đặc trưng của từng nhà cung cấp AI.
const _kProviderPalette = <String, Color>{
  'openai': AppColors.emerald,
  'anthropic': AppColors.tangerine,
  'google': AppColors.azure,
  'mistral': Color(0xFFF59E0B),
  'groq': AppColors.grape,
};

/// Biểu đồ tròn (Donut) và thống kê tỷ lệ phân bổ tần suất sử dụng các AI
/// đã đăng ký trong 3 tháng qua.
class TsProviderDistributionChart extends StatefulWidget {
  const TsProviderDistributionChart({
    super.key,
    required this.providers,
    required this.totalTokens,
  });

  final List<ProviderUsageBreakdown> providers;
  final int totalTokens;

  @override
  State<TsProviderDistributionChart> createState() =>
      _TsProviderDistributionChartState();
}

class _TsProviderDistributionChartState
    extends State<TsProviderDistributionChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void didUpdateWidget(covariant TsProviderDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providers != widget.providers ||
        oldWidget.totalTokens != widget.totalTokens) {
      _anim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  static String _formatTokens(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    }
    return number.toString();
  }

  static String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Color _resolveColor(String providerType, int index) {
    final key = providerType.toLowerCase();
    if (_kProviderPalette.containsKey(key)) {
      return _kProviderPalette[key]!;
    }
    const fallbackColors = [
      AppColors.primary,
      AppColors.azure,
      AppColors.emerald,
      AppColors.tangerine,
      AppColors.grape,
    ];
    return fallbackColors[index % fallbackColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.providers.isEmpty || widget.totalTokens <= 0) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 32,
                color: AppColors.secondaryText,
              ),
              SizedBox(height: AppSpacing.space8),
              Text(
                'Chưa có dữ liệu nhà cung cấp trong 3 tháng qua',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = widget.totalTokens.toDouble();

    // Chuẩn bị danh sách lát cung
    final slices = <_PieSliceData>[];
    for (var i = 0; i < widget.providers.length; i++) {
      final p = widget.providers[i];
      final color = _resolveColor(p.providerType, i);
      final percent = total > 0 ? (p.totalTokens / total) * 100 : 0.0;
      slices.add(
        _PieSliceData(
          label: p.provider.isNotEmpty ? p.provider : p.providerType,
          providerType: p.providerType,
          tokens: p.totalTokens,
          requestCount: p.requestCount,
          percent: percent,
          color: color,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;

        return Column(
          children: [
            // Phần trên: Biểu đồ tròn và tóm tắt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Biểu đồ tròn Donut
                SizedBox(
                  width: 136,
                  height: 136,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size.square(136),
                            painter: _DonutChartPainter(
                              slices: slices,
                              progress: Curves.easeOutCubic.transform(_anim.value),
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '3 THÁNG',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTokens(widget.totalTokens),
                            style: AppTypography.h3.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          Text(
                            'token',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9.5,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isNarrow) ...[
                  const SizedBox(width: AppSpacing.space20),
                  // Thống kê nhanh bên cạnh
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tần suất sử dụng AI',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.providers.length} nhà cung cấp đã ghi nhận hoạt động.',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.space16),

            // Phần dưới: Chi tiết từng AI với thanh tỷ lệ phần trăm
            for (final slice in slices) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        // Chấm màu nhận diện
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: Text(
                            slice.label,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${slice.percent.toStringAsFixed(1)}%',
                          style: AppTypography.label.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: slice.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Thanh phân bổ tiến trình
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 5,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(
                                color: AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _anim,
                              builder: (context, _) {
                                final factor = (slice.percent / 100 *
                                        _anim.value)
                                    .clamp(0.0, 1.0);
                                return FractionallySizedBox(
                                  widthFactor: factor,
                                  child: ColoredBox(color: slice.color),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${slice.requestCount} lượt gọi',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          '${_formatNumber(slice.tokens)} token',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        );
      },
    );
  }
}

class _PieSliceData {
  const _PieSliceData({
    required this.label,
    required this.providerType,
    required this.tokens,
    required this.requestCount,
    required this.percent,
    required this.color,
  });

  final String label;
  final String providerType;
  final int tokens;
  final int requestCount;
  final double percent;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.slices, required this.progress});

  final List<_PieSliceData> slices;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.tokens);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final strokeWidth = outerRadius * 0.32;
    final rect = Rect.fromCircle(
      center: center,
      radius: outerRadius - strokeWidth / 2,
    );

    const gap = 0.045; // Khoảng cách khe giữa các lát
    var startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.tokens / total) * (math.pi * 2) * progress;
      if (sweepAngle <= gap) continue;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweepAngle - gap,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices || oldDelegate.progress != progress;
  }
}
