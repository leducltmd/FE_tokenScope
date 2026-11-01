import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// 03 · THẺ DỮ LIỆU — Toàn bộ thẻ là vùng chạm · Viền và nền nhấn
/// giúp xác nhận tương tác.
///
/// Thẻ nền bề mặt, bo góc 16 px, viền 1 px.
class TsCard extends StatelessWidget {
  const TsCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.background = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.large,
    this.isPressed = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color borderColor;
  final double radius;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final hasBorder = borderColor != Colors.transparent;

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: isPressed ? const Color(0xFFF3F4F6) : background,
            borderRadius: BorderRadius.circular(radius),
            border: hasBorder ? Border.all(color: borderColor) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
