import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/usage_record.dart';

/// Thẻ hiển thị một lượt gọi AI API trong danh sách Lịch sử (Usage Record Card).
/// Thiết kế chuẩn pixel theo hình Figma của TokenScope.
class UsageRecordCard extends StatelessWidget {
  const UsageRecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onErrorDetailTap,
  });

  final UsageRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onErrorDetailTap;

  @override
  Widget build(BuildContext context) {
    final isSuccess = record.isSuccess;

    return Semantics(
      button: true,
      label: '${record.provider} ${record.model} ${record.formattedCost}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(
                color: isSuccess ? AppColors.border : const Color(0xFFFECACA),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A111827),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Vạch chỉ báo đỏ bên trái cho thẻ bị lỗi (Rate Limit 429 / Server Error)
                if (!isSuccess)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(color: AppColors.error),
                  ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    !isSuccess ? AppSpacing.space16 + 4 : AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hàng đầu: Icon Provider + Tên Provider • Model + Chi phí USD
                      _buildHeaderRow(),

                      const SizedBox(height: AppSpacing.space12),

                      // 2. Hàng thứ hai: Badges số lượng token (Vào / Ra / Tổng)
                      _buildTokenPillsRow(),

                      const SizedBox(height: AppSpacing.space12),

                      // 3. Hàng thứ ba: Huy hiệu trạng thái HTTP
                      _buildStatusRow(),

                      const SizedBox(height: AppSpacing.space12),

                      // 4. Hàng chân thẻ: Độ trễ + Thời gian thực hiện / Xem chi tiết lỗi
                      _buildFooterRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Hàng Header ──────────────────────────────────────────────────
  Widget _buildHeaderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProviderIcon(),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${record.provider} • ',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    TextSpan(
                      text: record.model,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: record.isSuccess ? AppColors.primary : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  Icon(
                    _resolveProjectIcon(record.projectIconType),
                    size: 13,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  Expanded(
                    child: Text(
                      '${record.project} • ${record.timeDisplay}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              record.formattedCost,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: record.isSuccess ? AppColors.navy : AppColors.error,
              ),
            ),
            const Text(
              'USD',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Icon Provider ───────────────────────────────────────────────────
  Widget _buildProviderIcon() {
    if (!record.isSuccess) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          size: 22,
          color: AppColors.error,
        ),
      );
    }

    final pLower = record.provider.toLowerCase();
    Color bg;
    Color iconColor;
    IconData iconData;

    if (pLower.contains('openai')) {
      bg = const Color(0xFFE6F7F0);
      iconColor = AppColors.emerald;
      iconData = Icons.smart_toy_outlined;
    } else if (pLower.contains('gemini')) {
      bg = const Color(0xFFE0F2FE);
      iconColor = AppColors.azure;
      iconData = record.model.contains('flash') ? Icons.bolt_rounded : Icons.auto_awesome_rounded;
    } else if (pLower.contains('anthropic')) {
      bg = const Color(0xFFF3E8FF);
      iconColor = AppColors.violet;
      iconData = Icons.psychology_outlined;
    } else {
      bg = AppColors.primaryLight;
      iconColor = AppColors.primary;
      iconData = Icons.memory_rounded;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, size: 22, color: iconColor),
    );
  }

  // ── 2. Hàng Badges Token ────────────────────────────────────────────
  Widget _buildTokenPillsRow() {
    final arrowColor = record.isSuccess ? AppColors.primary : AppColors.error;
    final pillBg = record.isSuccess ? const Color(0xFFEEF2FF) : const Color(0xFFFEF2F2);

    return Wrap(
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: [
        // Pill Vào (Input Tokens)
        _buildTokenPill(
          icon: Icons.arrow_downward_rounded,
          iconColor: arrowColor,
          backgroundColor: pillBg,
          label: 'Vào: ',
          value: record.formattedInputTokens,
          suffix: ' tkn',
        ),

        // Pill Ra (Output Tokens)
        _buildTokenPill(
          icon: Icons.arrow_upward_rounded,
          iconColor: arrowColor,
          backgroundColor: pillBg,
          label: 'Ra: ',
          value: record.formattedOutputTokens,
          suffix: ' tkn',
        ),

        // Pill Tổng Token (hoặc 0 tokens phản hồi khi lỗi)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.all_inclusive_rounded,
                size: 13,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              if (record.isSuccess)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Tổng: ',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      TextSpan(
                        text: record.formattedTotalTokens,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const TextSpan(
                        text: ' tkn',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text(
                  '(0 tokens phản hồi)',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokenPill({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required String value,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Hàng Trạng thái HTTP ─────────────────────────────────────────
  Widget _buildStatusRow() {
    if (record.isSuccess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF12B76A),
            ),
            const SizedBox(width: 6),
            Text(
              record.statusMessage,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF047857),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 6),
          Text(
            record.statusMessage,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Hàng Footer ──────────────────────────────────────────────────
  Widget _buildFooterRow() {
    if (record.isSuccess) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                'Độ trễ: ${record.latencyMs}ms',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              record.fullTimeDisplay,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            record.fullTimeDisplay,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onErrorDetailTap ?? onTap,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
                SizedBox(width: 4),
                Text(
                  'Xem chi tiết lỗi',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _resolveProjectIcon(String type) {
    return switch (type) {
      'folder' => Icons.folder_outlined,
      'code' => Icons.code_rounded,
      'edit' => Icons.edit_note_rounded,
      'robot' => Icons.smart_toy_outlined,
      'search' => Icons.manage_search_rounded,
      _ => Icons.folder_outlined,
    };
  }
}
