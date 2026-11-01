import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Nút chính của TokenScope — nền chủ đạo, bo góc vừa, độ cao 52.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final child = widget.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: AppSpacing.space8),
              ],
              Text(widget.label),
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.expand ? double.infinity : null,
          height: 52,
          padding: widget.expand
              ? null
              : const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: !_enabled
                ? AppColors.disabled
                : (_pressed ? AppColors.primaryDark : AppColors.primary),
            borderRadius: AppRadius.mediumRadius,
            boxShadow: _pressed ? AppElevation.level0 : AppElevation.level1,
          ),
          child: DefaultTextStyle(
            style: AppTypography.label.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            child: IconTheme(
              data: const IconThemeData(color: AppColors.onPrimary),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
