import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 01 · NÚT — Ba cấp hành động · Bốn trạng thái tương tác.
///
/// Cao 48 px · Bo góc 8 px · Giữ nguyên nhãn khi tải; khóa thao tác lặp.
enum TsButtonVariant {
  /// Chính · Hành động ưu tiên.
  primary,

  /// Phụ · Hành động thay thế.
  secondary,

  /// Nguy hiểm · Hành động không thể hoàn tác.
  danger,
}

/// Nút chuẩn của TokenScope.
///
/// - Cao 48 px, bo góc 8 px, vùng chạm ≥ 48 px.
/// - Trạng thái: mặc định / đang nhấn / vô hiệu / đang tải.
/// - Khi đang tải vẫn giữ nhãn và khoá thao tác lặp.
class TsButton extends StatefulWidget {
  const TsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = TsButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final TsButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final double height;

  /// Vô hiệu khi không có callback hoặc đang tải.
  bool get isDisabled => onPressed == null || isLoading;

  @override
  State<TsButton> createState() => _TsButtonState();
}

class _TsButtonState extends State<TsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = _TsButtonScheme.resolve(
      widget.variant,
      pressed: _pressed,
      loading: widget.isLoading,
      disabled: widget.onPressed == null,
    );

    final textStyle = AppTypography.label.copyWith(
      color: scheme.foreground,
      fontWeight: FontWeight.w600,
    );

    final content = widget.isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.foreground),
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              // Giữ nguyên nhãn khi tải.
              Text(widget.label, style: textStyle),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: scheme.foreground),
                const SizedBox(width: AppSpacing.space8),
              ],
              Text(widget.label, style: textStyle),
            ],
          );

    return Semantics(
      button: true,
      enabled: !widget.isDisabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.isDisabled
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.expand ? double.infinity : null,
          height: widget.height,
          padding: widget.expand
              ? null
              : const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.background,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: scheme.border == null ? null : Border.all(color: scheme.border!),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Bảng màu theo cấp hành động và trạng thái tương tác.
class _TsButtonScheme {
  const _TsButtonScheme({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;

  static _TsButtonScheme resolve(
    TsButtonVariant variant, {
    required bool pressed,
    required bool loading,
    required bool disabled,
  }) {
    if (disabled) {
      return const _TsButtonScheme(
        background: AppColors.disabled,
        foreground: AppColors.onPrimary,
      );
    }

    switch (variant) {
      case TsButtonVariant.primary:
        return _TsButtonScheme(
          background: pressed ? AppColors.primaryDark : AppColors.primary,
          foreground: AppColors.onPrimary,
        );
      case TsButtonVariant.secondary:
        return _TsButtonScheme(
          background: pressed ? AppColors.primaryLight : AppColors.surface,
          foreground: AppColors.primary,
          border: pressed ? AppColors.primaryBorder : AppColors.border,
        );
      case TsButtonVariant.danger:
        return _TsButtonScheme(
          background: pressed
              ? const Color(0xFFB91C1C)
              : (loading ? AppColors.error : AppColors.error),
          foreground: AppColors.onPrimary,
        );
    }
  }
}
