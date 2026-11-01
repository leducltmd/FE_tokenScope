import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Ô chọn tùy chỉnh theo chuẩn TokenScope (checkbox bo góc 6px,
/// dùng màu chủ đạo khi được chọn).
class TsCheckbox extends StatelessWidget {
  const TsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelBuilder,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Nhãn dạng chữ đơn giản.
  final String? label;

  /// Nhãn dạng phong phú (ví dụ RichText có liên kết điều khoản).
  final InlineSpan? labelBuilder;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.primary : AppColors.border,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.onPrimary,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.space8),
          // Nhãn phải co giãn được để không tràn ra ngoài khi màn hình hẹp.
          Flexible(
            child: labelBuilder != null
                ? Text.rich(labelBuilder!, overflow: TextOverflow.ellipsis)
                : Text(
                    label ?? '',
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
