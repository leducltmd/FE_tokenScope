import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ts_card.dart';

/// 03 · THẺ DỮ LIỆU — Ba loại thẻ: nhà cung cấp · lượng token · ngân sách.
///
/// Mỗi thẻ là một vùng chạm hoàn chỉnh.

/// Thẻ nhà cung cấp — ví dụ "OpenAI · Đã kết nối · 3 mô hình · 128.450 ₫ hôm nay".
class TsProviderCard extends StatelessWidget {
  const TsProviderCard({
    super.key,
    required this.name,
    required this.status,
    required this.modelCount,
    required this.costToday,
    this.logo,
    this.onDelete,
    this.onTap,
  });

  final String name;
  final String status;
  final int modelCount;
  final String costToday;
  final Widget? logo;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            logo!,
            const SizedBox(width: AppSpacing.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    Flexible(
                      child: Text(
                        '$status · $modelCount mô hình',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  '$costToday hôm nay',
                  style: AppTypography.label.copyWith(color: AppColors.navy),
                ),
              ],
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: AppSpacing.space8),
            _IconAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Xóa',
              color: AppColors.error,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ lượng token — ví dụ "Token hôm nay 245.800 token · 180.200 vào · 65.600 ra".
class TsTokenSummaryCard extends StatelessWidget {
  const TsTokenSummaryCard({
    super.key,
    required this.totalTokens,
    required this.inputTokens,
    required this.outputTokens,
    this.label = 'Token hôm nay',
    this.onTap,
  });

  final int totalTokens;
  final int inputTokens;
  final int outputTokens;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(totalTokens),
                style: AppTypography.h1.copyWith(fontSize: 26),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text('token', style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            '${_formatNumber(inputTokens)} vào · ${_formatNumber(outputTokens)} ra',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Thẻ ngân sách — ví dụ "Ngân sách tháng 10 · 650.000 ₫ / 1.000.000 ₫ · Đã dùng 65%".
class TsBudgetCard extends StatelessWidget {
  const TsBudgetCard({
    super.key,
    required this.title,
    required this.spent,
    required this.limit,
    required this.percentUsed,
    this.remaining,
    this.onTap,
  });

  final String title;
  final String spent;
  final String limit;
  final int percentUsed;
  final String? remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = (percentUsed / 100).clamp(0.0, 1.0);
    final barColor = percentUsed >= 90
        ? AppColors.error
        : percentUsed >= 80
        ? AppColors.warning
        : AppColors.primary;

    return TsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              Text(
                spent,
                style: AppTypography.label.copyWith(color: AppColors.navy),
              ),
              Text(' / $limit', style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            remaining == null
                ? 'Đã dùng $percentUsed%'
                : 'Đã dùng $percentUsed% · Còn $remaining',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Nút biểu tượng tròn 48 × 48 px cho thẻ dữ liệu.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.secondaryText,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: SizedBox(
          height: 48,
          width: 48,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// Định dạng số có dấu chấm phân tách nghìn.
String _formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
