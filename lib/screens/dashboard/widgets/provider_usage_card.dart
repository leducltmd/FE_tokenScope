import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Một dòng phân bổ nhà cung cấp.
class TsProviderUsage {
  const TsProviderUsage({
    required this.name,
    required this.percent,
    required this.models,
    required this.tokens,
    required this.cost,
    required this.letter,
    required this.color,
    this.icon,
  });

  final String name;
  final int percent;
  final String models;
  final String tokens;
  final String cost;
  final String letter;
  final Color color;
  final IconData? icon;
}

/// Thẻ phân bổ theo nhà cung cấp — biểu tượng, tên, tỷ lệ, mô hình, token, chi phí.
class TsProviderUsageCard extends StatelessWidget {
  const TsProviderUsageCard({super.key, required this.provider, this.onTap});

  final TsProviderUsage provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _ProviderBadge(provider: provider),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          provider.models,
                          style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: provider.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${provider.percent}%',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: provider.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: provider.percent / 100,
                  minHeight: 6,
                  backgroundColor: provider.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(provider.color),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.data_usage_rounded,
                          size: 15,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${provider.tokens} token',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    provider.cost,
                    style: AppTypography.label.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Biểu tượng nhà cung cấp trong ô bo góc.
class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.provider});

  final TsProviderUsage provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: provider.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: provider.icon != null
          ? Icon(provider.icon, size: 20, color: provider.color)
          : Text(
              provider.letter,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: provider.color,
              ),
            ),
    );
  }
}
