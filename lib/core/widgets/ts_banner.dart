import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ts_button.dart';

/// Cảnh báo ngân sách — dải thông báo nền hổ phách trên đầu màn hình.
///
/// Dùng cho ngưỡng cảnh báo 80% hoặc sự kiện cần chú ý.
class TsBanner extends StatelessWidget {
  const TsBanner({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.warning_amber_rounded,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.warning),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(message, style: AppTypography.bodySmall),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.space8),
                  TsButton(
                    label: actionLabel!,
                    variant: TsButtonVariant.secondary,
                    expand: false,
                    height: 40,
                    icon: Icons.open_in_new_rounded,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
