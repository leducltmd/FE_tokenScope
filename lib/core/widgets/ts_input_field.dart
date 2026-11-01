import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 02 · TRƯỜNG NHẬP — Vùng nhập cao 52 px · Viền tiêu điểm 2 px
/// · Không chỉ dùng màu để báo lỗi.
///
/// Nhãn cố định · Gợi ý rõ ràng · Phản hồi tại chỗ.
class TsInputField extends StatefulWidget {
  const TsInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.suffix,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? helperText;
  final String? errorText;

  /// Tiền tố cố định trong vùng nhập (ví dụ "₫").
  final String? prefixText;

  final Widget? suffix;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<TsInputField> createState() => _TsInputFieldState();
}

class _TsInputFieldState extends State<TsInputField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late bool _obscured = widget.obscureText;
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nhãn cố định.
        Text(
          widget.label,
          style: AppTypography.label.copyWith(color: AppColors.navy),
        ),
        const SizedBox(height: AppSpacing.space8),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          obscureText: _obscured,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: AppTypography.body.copyWith(color: AppColors.navy),
          cursorColor: AppColors.primary,
          cursorWidth: 1.5,
          decoration: InputDecoration(
            hintText: widget.hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space16,
            ),
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20, color: AppColors.secondaryText),
            prefixText: widget.prefixText,
            prefixStyle: AppTypography.body.copyWith(
              color: AppColors.secondaryText,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  )
                : widget.suffix,
            helperText: widget.helperText,
            helperStyle: AppTypography.bodySmall,
            helperMaxLines: 2,
            border: _border(
              hasError ? AppColors.error : AppColors.border,
              width: 1,
            ),
            enabledBorder: _border(
              hasError ? AppColors.error : AppColors.border,
              width: 1,
            ),
            focusedBorder: _border(
              hasError ? AppColors.error : AppColors.primary,
              width: 2,
            ),
            focusedErrorBorder: _border(AppColors.error, width: 2),
          ),
        ),
        // Phản hồi tại chỗ — có biểu tượng để không chỉ dùng màu báo lỗi.
        if (hasError) ...[
          const SizedBox(height: AppSpacing.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color, {required double width}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.small),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
