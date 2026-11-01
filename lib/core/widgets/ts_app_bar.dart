import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 05 · THANH ỨNG DỤNG — Cao 64 px · Biểu tượng trong vùng chạm 48 × 48 px
/// · Tối đa hai hành động.
///
/// Tiêu đề nhất quán · Hành động theo ngữ cảnh.
class TsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TsAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Hiển thị nút quay lại (tự động bật khi có [onBack]).
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final hasBack = showBack || onBack != null;

    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      titleSpacing: hasBack ? 0 : AppSpacing.screenPadding,
      leading: hasBack
          ? IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.navy,
              tooltip: 'Quay lại',
              constraints: const BoxConstraints.tightFor(
                width: 48,
                height: 48,
              ),
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        // Tối đa hai hành động.
        for (var i = 0; i < actions.length && i < 2; i++) actions[i],
        if (actions.isNotEmpty) const SizedBox(width: AppSpacing.space8),
      ],
    );
  }
}

/// Nút biểu tượng chuẩn của thanh ứng dụng — vùng chạm 48 × 48 px.
class TsAppBarAction extends StatelessWidget {
  const TsAppBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      color: AppColors.navy,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
    );
  }
}
