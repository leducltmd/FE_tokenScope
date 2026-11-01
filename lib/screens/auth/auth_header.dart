import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_logo.dart';

/// Phần đầu trang của màn hình xác thực: nền gradient, logo, tiêu đề và
/// mô tả ngắn. Giữ đúng thang khoảng cách và kiểu chữ của hệ thống.
///
/// Header tự thu gọn khi không gian bị hạn chế (viewport thấp hoặc hẹp) để
/// không bao giờ tràn ra ngoài vùng chứa.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;

  /// Ngưỡng chiều rộng dưới đó bỏ logo và thu gọn khoảng đệm.
  static const double _narrowBreakpoint = 260;

  /// Ngưỡng chiều cao dưới đó dùng bố cục gọn.
  static const double _shortBreakpoint = 320;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBreakpoint;
        final short =
            constraints.maxHeight.isFinite &&
            constraints.maxHeight < _shortBreakpoint;
        final compact = narrow || short;

        final logoSize = compact ? 36.0 : 52.0;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.extraLarge),
            ),
          ),
          padding: EdgeInsets.only(
            left: narrow ? AppSpacing.space16 : AppSpacing.screenPadding,
            right: narrow ? AppSpacing.space16 : AppSpacing.screenPadding,
            top: showBackButton
                ? AppSpacing.space16
                : (compact ? AppSpacing.space16 : AppSpacing.space32),
            bottom: compact ? AppSpacing.space16 : AppSpacing.space32,
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBackButton) ...[
                  _BackChip(onTap: onBack),
                  SizedBox(height: compact ? AppSpacing.space16 : AppSpacing.space24),
                ] else if (!narrow) ...[
                  TsLogo(size: logoSize),
                  SizedBox(height: compact ? AppSpacing.space16 : AppSpacing.space24),
                ],
                // Tiêu đề và mô tả co giãn theo chiều cao còn trống nên
                // không bao giờ làm tràn khối header.
                Flexible(
                  child: Text(
                    title,
                    style: (compact ? AppTypography.h2 : AppTypography.h1)
                        .copyWith(color: AppColors.onPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Flexible(
                  child: Text(
                    subtitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                      fontSize: compact ? 14 : 16,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onPrimary.withValues(alpha: 0.16),
      borderRadius: AppRadius.mediumRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumRadius,
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.onPrimary,
              ),
              SizedBox(width: AppSpacing.space8),
              Text(
                'Quay lại',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
