import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Một khoản ngân sách được gán cho một nhà cung cấp.
class BudgetProvider {
  const BudgetProvider({
    required this.name,
    required this.models,
    required this.spent,
    required this.limit,
    required this.color,
  });

  final String name;
  final String models;
  final double spent;
  final double limit;
  final Color color;

  /// Phần trăm hạn mức đã dùng.
  double get percent => limit <= 0 ? 0 : (spent / limit) * 100;

  /// Số tiền còn lại.
  double get remaining => limit - spent;

  /// Trạng thái theo mức sử dụng.
  BudgetLevel get level {
    if (percent >= 90) return BudgetLevel.critical;
    if (percent >= 80) return BudgetLevel.warning;
    return BudgetLevel.safe;
  }
}

/// Mức cảnh báo của một khoản ngân sách.
enum BudgetLevel {
  safe('Đang ổn định', AppColors.success, Color(0xFFE7F8F0)),
  warning('Gần chạm hạn mức', AppColors.warning, AppColors.warningLight),
  critical('Cần mở rộng ngay', AppColors.error, AppColors.errorLight);

  const BudgetLevel(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;
}

/// Một khoản ngân sách được gán cho một dự án.
class BudgetProject {
  const BudgetProject({
    required this.name,
    required this.models,
    required this.spent,
    required this.limit,
    required this.color,
  });

  final String name;
  final String models;
  final double spent;
  final double limit;
  final Color color;

  double get percent => limit <= 0 ? 0 : (spent / limit) * 100;

  double get remaining => limit - spent;

  BudgetLevel get level {
    if (percent >= 90) return BudgetLevel.critical;
    if (percent >= 80) return BudgetLevel.warning;
    return BudgetLevel.safe;
  }
}

/// Chip chọn chu kỳ tính toán — nền tím nhạt, chữ tím đậm.
class BudgetPeriodChip extends StatelessWidget {
  const BudgetPeriodChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.softPurple,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dải cảnh báo đỏ — vượt ngưỡng an toàn.
class BudgetAlertBanner extends StatelessWidget {
  const BudgetAlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9E6),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: const Color(0xFFF7C6C3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: Color(0xFFA01E27),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA01E27),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: const Color(0xFFAE3B42),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh tiến trình ngân sách — có vạch đánh dấu ngưỡng cảnh báo và mức trần.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.percent,
    this.thresholdPercent,
    this.height = 10,
    this.color = AppColors.primary,
  });

  /// Phần trăm đã dùng (0 → 100).
  final double percent;

  /// Vị trí vạch ngưỡng cảnh báo (%).
  final double? thresholdPercent;

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;

        return SizedBox(
          height: height + 12,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: height,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(color: AppColors.border),
                          ),
                          FractionallySizedBox(
                            widthFactor: value,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.55),
                                    color,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (thresholdPercent != null)
                Positioned(
                  left: (thresholdPercent! / 100).clamp(0.0, 1.0) * trackWidth -
                      1,
                  top: 0,
                  bottom: 12,
                  child: Container(width: 2, color: AppColors.warning),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Huy hiệu trạng thái hạn mức — nền màu theo mức cảnh báo.
class BudgetStatusBadge extends StatelessWidget {
  const BudgetStatusBadge({
    super.key,
    required this.label,
    required this.level,
  });

  final String label;
  final BudgetLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: level.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: level.color,
        ),
      ),
    );
  }
}

/// Thẻ chi tiết một nhà cung cấp trong danh sách phân bổ ngân sách.
class BudgetProviderCard extends StatelessWidget {
  const BudgetProviderCard({
    super.key,
    required this.provider,
    this.onTap,
  });

  final BudgetProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = provider.percent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: provider.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  provider.name.characters.first,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: provider.color,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: AppTypography.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      provider.models,
                      style: AppTypography.bodySmall.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                '\$${provider.spent.toStringAsFixed(2)} / '
                '\$${provider.limit.toStringAsFixed(2)}',
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          _BudgetBar(percent: percent, color: provider.color),
          const SizedBox(height: AppSpacing.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${percent.toStringAsFixed(1)}% hạn mức đã dùng',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Còn \$${provider.remaining.toStringAsFixed(2)}',
                style: AppTypography.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          if (provider.level != BudgetLevel.safe) ...[
            const SizedBox(height: AppSpacing.space8),
            BudgetStatusBadge(
              label: provider.level.label,
              level: provider.level,
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ chi tiết một dự án trong danh sách phân bổ ngân sách.
class BudgetProjectCard extends StatelessWidget {
  const BudgetProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  final BudgetProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = project.percent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: project.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  size: 17,
                  color: AppColors.azure,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: AppTypography.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      project.models,
                      style: AppTypography.bodySmall.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                '\$${project.spent.toStringAsFixed(2)} / '
                '\$${project.limit.toStringAsFixed(2)}',
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          _BudgetBar(percent: percent, color: project.color),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${percent.toStringAsFixed(1)}% hạn mức đã dùng',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Còn \$${project.remaining.toStringAsFixed(2)}',
                style: AppTypography.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          if (project.level != BudgetLevel.safe) ...[
            const SizedBox(height: AppSpacing.space8),
            BudgetStatusBadge(
              label: project.level.label,
              level: project.level,
            ),
          ],
        ],
      ),
    );
  }
}

/// Thanh tiêu thụ bên trong thẻ nhà cung cấp / dự án.
class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: AppColors.border)),
            FractionallySizedBox(
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
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

/// Hàng công tắc — bật/tắt giới hạn rate-limit tự động.
class BudgetSwitchRow extends StatelessWidget {
  const BudgetSwitchRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
