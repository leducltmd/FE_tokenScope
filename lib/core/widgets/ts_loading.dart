import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 07 · ĐANG TẢI — Vòng tải cho tác vụ ngắn · Khung xương giữ cấu trúc thẻ
/// khi tải lần đầu.
class TsLoadingSpinner extends StatelessWidget {
  const TsLoadingSpinner({super.key, this.label, this.size = 28});

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.space12),
            Text(label!, style: AppTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Khung xương thẻ — giữ nguyên cấu trúc thẻ khi tải lần đầu.
class TsSkeletonCard extends StatelessWidget {
  const TsSkeletonCard({super.key, this.height = 96, this.lines = 3});

  final double height;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBar(width: 140, height: 16),
          const SizedBox(height: AppSpacing.space8),
          _SkeletonBar(width: 96, height: 12),
          const SizedBox(height: AppSpacing.space12),
          for (var i = 0; i < lines; i++) ...[
            _SkeletonBar(width: double.infinity, height: 10),
            if (i < lines - 1) const SizedBox(height: AppSpacing.space8),
          ],
        ],
      ),
    );
  }
}

/// Danh sách khung xương — dùng khi tải lần đầu một nhóm thẻ.
class TsSkeletonList extends StatelessWidget {
  const TsSkeletonList({super.key, this.count = 3, this.height = 96});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          TsSkeletonCard(height: height),
          if (i < count - 1) const SizedBox(height: AppSpacing.space12),
        ],
      ],
    );
  }
}

class _SkeletonBar extends StatefulWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<_SkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.border,
              AppColors.primaryLight,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        );
      },
    );
  }
}
