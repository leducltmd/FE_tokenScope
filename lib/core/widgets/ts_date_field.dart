import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Trường chọn ngày sinh — nút mở hộp thoại lịch.
///
/// Giá trị lưu ở định dạng `YYYY-MM-DD` để khớp với API backend.
class TsDateField extends StatelessWidget {
  const TsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Chọn ngày sinh',
    this.firstDate,
    this.lastDate,
    this.helperText,
    this.errorText,
  });

  final String label;

  /// Ngày đang chọn, định dạng `YYYY-MM-DD`.
  final String? value;
  final ValueChanged<String> onChanged;
  final String hint;

  /// Ngày sớm nhất được chọn (mặc định 120 năm trước).
  final DateTime? firstDate;

  /// Ngày muộn nhất được chọn (mặc định hôm nay).
  final DateTime? lastDate;
  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final selected = value == null ? null : DateTime.tryParse(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.navy),
        ),
        const SizedBox(height: AppSpacing.space8),
        Material(
          color: AppColors.surface,
          borderRadius: AppRadius.mediumRadius,
          child: InkWell(
            onTap: () => _pickDate(context, selected),
            borderRadius: AppRadius.mediumRadius,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mediumRadius,
                border: Border.all(
                  color: hasError ? AppColors.error : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cake_outlined,
                    size: 20,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Text(
                      selected == null ? hint : _formatDisplay(selected),
                      style: selected == null
                          ? AppTypography.body.copyWith(
                              color: AppColors.secondaryText.withValues(
                                alpha: 0.75,
                              ),
                            )
                          : AppTypography.body.copyWith(color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null || hasError) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            errorText ?? helperText!,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: hasError ? AppColors.error : AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime? selected) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 120);
    final last = lastDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: selected ?? DateTime(now.year - 25, 1, 1),
      firstDate: first,
      lastDate: last,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      fieldLabelText: 'Ngày sinh',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    onChanged(
      '${picked.year.toString().padLeft(4, '0')}-'
      '${picked.month.toString().padLeft(2, '0')}-'
      '${picked.day.toString().padLeft(2, '0')}',
    );
  }

  /// Định dạng ngày theo kiểu Việt Nam — "01/02/1995".
  static String _formatDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
