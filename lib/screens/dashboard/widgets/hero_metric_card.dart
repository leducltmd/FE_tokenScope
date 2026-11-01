import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Thẻ chỉ số nổi bật — nền gradient tím–xanh dương, có quầng sáng.
///
/// Bên trong: tổng token, chi phí ước tính, thanh phân rã input/output
/// và thanh tiến trình chi tiêu tháng.
class TsHeroMetricCard extends StatelessWidget {
  const TsHeroMetricCard({
    super.key,
    required this.totalTokens,
    required this.totalTokensLabel,
    required this.costLabel,
    required this.inputTokens,
    required this.inputPercent,
    required this.outputTokens,
    required this.outputPercent,
    required this.budgetLabel,
    required this.remainingLabel,
    required this.spentPercent,
    this.onTap,
  });

  final String totalTokensLabel;
  final String totalTokens;
  final String costLabel;

  final String inputTokens;
  final double inputPercent;
  final String outputTokens;
  final double outputPercent;

  final String budgetLabel;
  final String remainingLabel;
  final double spentPercent;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3), Color(0xFF1E1B4B)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            offset: const Offset(0, 10),
            blurRadius: 28,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        child: Stack(
          children: [
            // Quầng sáng mềm ở góc trên bên phải.
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violet.withValues(alpha: 0.55),
                      AppColors.violet.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng token tháng này',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.75),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalTokens,
                              style: AppTypography.h2.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 27,
                                letterSpacing: -0.6,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalTokensLabel,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.65),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(
                            color: AppColors.onPrimary.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Chi phí ước tính',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              costLabel,
                              style: AppTypography.label.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  _BreakdownBar(
                    inputPercent: inputPercent,
                    outputPercent: outputPercent,
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  Row(
                    children: [
                      Expanded(
                        child: _LegendItem(
                          color: const Color(0xFFA5B4FC),
                          label: 'Input',
                          value: inputTokens,
                          percent: inputPercent,
                        ),
                      ),
                      Expanded(
                        child: _LegendItem(
                          color: const Color(0xFF38BDF8),
                          label: 'Output',
                          value: outputTokens,
                          percent: outputPercent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.large),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                budgetLabel,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onPrimary.withValues(alpha: 0.8),
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space8),
                            Flexible(
                              child: Text(
                                remainingLabel,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: spentPercent.clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: AppColors.onPrimary.withValues(
                              alpha: 0.18,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh phân rã input/output.
class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({required this.inputPercent, required this.outputPercent});

  final double inputPercent;
  final double outputPercent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
              flex: (inputPercent * 100).round().clamp(1, 100),
              child: Container(color: const Color(0xFFA5B4FC)),
            ),
            const SizedBox(width: 3),
            Expanded(
              flex: (outputPercent * 100).round().clamp(1, 100),
              child: Container(color: const Color(0xFF38BDF8)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chú giải một màu trong thanh phân rã.
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String label;
  final String value;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$value (${(percent * 100).toStringAsFixed(1)}%)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
