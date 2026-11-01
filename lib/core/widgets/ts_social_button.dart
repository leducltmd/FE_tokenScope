import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Nút đăng nhập bằng nhà cung cấp bên thứ ba.
class TsSocialButton extends StatelessWidget {
  const TsSocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
          side: const BorderSide(color: AppColors.border),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.mediumRadius,
          ),
          textStyle: AppTypography.label.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.navy),
            const SizedBox(width: AppSpacing.space8),
            // Nhãn co giãn được để không tràn khi màn hình hẹp.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đường phân cách chữ "HOẶC".
class TsOrDivider extends StatelessWidget {
  const TsOrDivider({super.key, this.label = 'HOẶC'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.secondaryText,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
