import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ts_logo.dart';
import '../../../core/utils/ts_motion.dart';
import 'wave_indicator.dart';

/// Đầu trang bảng điều khiển — logo, nhãn trực tiếp, thông báo và hồ sơ.
///
/// Bên dưới là lời chào, mô tả ngắn và huy hiệu thời điểm đồng bộ.
class TsDashboardHeader extends StatelessWidget {
  const TsDashboardHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.userName,
    required this.lastSynced,
    this.onNotifications,
    this.onAvatar,
  });

  final String greeting;
  final String subtitle;
  final String userName;
  final String lastSynced;
  final VoidCallback? onNotifications;
  final VoidCallback? onAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space16,
        AppSpacing.screenPadding,
        AppSpacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TsLogo(size: 36),
              const SizedBox(width: AppSpacing.space12),
              const Flexible(
                child: Text(
                  'TokenScope',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              const _LiveBadge(),
              const Spacer(),
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Thông báo',
                onPressed: onNotifications,
                badge: true,
              ),
              const SizedBox(width: AppSpacing.space8),
              _AvatarButton(name: userName, onPressed: onAvatar),
            ],
          ),
          const SizedBox(height: AppSpacing.space24),
          Text(
            greeting,
            style: AppTypography.h2.copyWith(fontSize: 24),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(fontSize: 14.5),
          ),
          const SizedBox(height: AppSpacing.space12),
          _SyncedBadge(label: lastSynced),
        ],
      ),
    );
  }
}

/// Huy hiệu "Live" — chấm xanh nhấp nháy kèm nhãn trạng thái.
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (TsMotion.enabled) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.liveLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.live.withValues(
                    alpha: 0.45 + _controller.value * 0.55,
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            'Live',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.live,
            ),
          ),
        ],
      ),
    );
  }
}

/// Huy hiệu thời điểm đồng bộ — kèm hiệu ứng sóng.
class _SyncedBadge extends StatelessWidget {
  const _SyncedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.softPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TsWaveIndicator(),
          const SizedBox(width: AppSpacing.space8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút biểu tượng tròn trong đầu trang.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: AppColors.navy),
                if (badge)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút hồ sơ — chữ cái đầu trong vòng tròn gradient.
class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.name, this.onPressed});

  final String name;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first;

    return Tooltip(
      message: name,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.violet, AppColors.primary],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              letter.toUpperCase(),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
