import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Trường nhập liệu theo chuẩn TokenScope: nền bề mặt, viền 1px,
/// bo góc vừa, nhãn ở trên, hỗ trợ ẩn/hiện mật khẩu và trạng thái lỗi.
class TsTextField extends StatefulWidget {
  const TsTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<TsTextField> createState() => _TsTextFieldState();
}

class _TsTextFieldState extends State<TsTextField> {
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
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20),
            errorText: widget.errorText,
            helperText: widget.helperText,
            helperStyle: AppTypography.bodySmall,
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
                : null,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
