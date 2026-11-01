import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ts_button.dart';

/// 06 · HỘP THOẠI — Bo góc 16 px · Nội dung giải thích hệ quả
/// · Luôn có lựa chọn Hủy.
///
/// Xác nhận thay đổi · Cảnh báo trước thao tác nguy hiểm.
class TsDialog extends StatelessWidget {
  const TsDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Xác nhận',
    this.cancelLabel = 'Hủy',
    this.isDanger = false,
    this.icon,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  /// Cảnh báo trước thao tác nguy hiểm.
  final bool isDanger;

  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Hiển thị hộp thoại xác nhận.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    bool isDanger = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TsDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accent = isDanger ? AppColors.error : AppColors.primary;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.largeRadius,
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space8,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        0,
        AppSpacing.space24,
        AppSpacing.space24,
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isDanger ? AppColors.errorLight : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.space12),
          ],
          Expanded(child: Text(title, style: AppTypography.h3)),
        ],
      ),
      content: Text(
        message,
        style: AppTypography.body.copyWith(color: AppColors.secondaryText),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TsButton(
                label: cancelLabel,
                variant: TsButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: TsButton(
                label: confirmLabel,
                variant: isDanger
                    ? TsButtonVariant.danger
                    : TsButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        0,
        AppSpacing.space24,
        AppSpacing.space24,
      ),
    );
  }
}
