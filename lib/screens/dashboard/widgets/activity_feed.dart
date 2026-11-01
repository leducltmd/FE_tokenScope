import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Một bản ghi truy vấn gần nhất.
class TsActivityEntry {
  const TsActivityEntry({
    required this.model,
    required this.project,
    required this.tokens,
    required this.cost,
    required this.time,
    required this.letter,
    required this.color,
  });

  final String model;
  final String project;
  final String tokens;
  final String cost;
  final String time;
  final String letter;
  final Color color;
}

/// Danh sách truy vấn gần nhất — dòng thời gian gọn gàng.
class TsActivityFeed extends StatelessWidget {
  const TsActivityFeed({super.key, required this.entries});

  final List<TsActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Chưa có truy vấn nào.',
          style: AppTypography.bodySmall,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _ActivityRow(entry: entries[i]),
            if (i < entries.length - 1)
              const Divider(height: 1, color: AppColors.border, indent: 68),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final TsActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(
              entry.letter,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: entry.color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.model,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.project,
                  style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.cost,
                style: AppTypography.label.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.tokens,
                style: AppTypography.bodySmall.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
