import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ts_button.dart';

/// 08 · TRẠNG THÁI TRỐNG — Chưa có bản ghi phù hợp · Hướng dẫn bước tiếp theo.
class TsEmptyState extends StatelessWidget {
  const TsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.space8),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.space24),
              TsButton(
                label: actionLabel!,
                variant: TsButtonVariant.secondary,
                expand: false,
                icon: Icons.filter_alt_off_rounded,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 09 · TRẠNG THÁI LỖI — Lỗi kết nối API · Cho phép chủ động khôi phục.
///
/// Giữ lại dữ liệu đã có · Chỉ thử lại khi người dùng yêu cầu.
class TsErrorState extends StatelessWidget {
  const TsErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'Thử lại',
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.space8),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.space24),
              TsButton(
                label: actionLabel,
                variant: TsButtonVariant.secondary,
                expand: false,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
