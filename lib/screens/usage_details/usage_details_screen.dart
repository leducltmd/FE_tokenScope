import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_app_bar.dart';
import '../../core/widgets/ts_button.dart';
import '../../core/widgets/ts_card.dart';
import '../../models/usage_record.dart';

/// Màn hình Chi tiết lượt gọi AI API (Usage Details Screen).
/// Hiển thị toàn bộ thông số kỹ thuật, prompt, phản hồi và cURL của bản ghi được chọn.
class UsageDetailsScreen extends StatelessWidget {
  const UsageDetailsScreen({
    super.key,
    required this.record,
  });

  final UsageRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TsAppBar(
        title: 'Chi tiết lượt gọi API',
        subtitle: record.promptId,
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            color: AppColors.navy,
            tooltip: 'Chia sẻ',
            onPressed: () => _copyToClipboard(
              context,
              'Prompt ID: ${record.promptId}\nModel: ${record.model}\nCost: ${record.formattedCost}\nTokens: ${record.formattedTotalTokens}',
              'Đã sao chép thông tin tóm tắt lượt gọi.',
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space8,
            AppSpacing.screenPadding,
            AppSpacing.space32,
          ),
          children: [
            // 1. Banner trạng thái
            _buildStatusHero(context),

            const SizedBox(height: AppSpacing.space16),

            // 2. Lưới 4 chỉ số chính (Model, Tokens, Cost, Latency)
            _buildMetricGrid(),

            const SizedBox(height: AppSpacing.space16),

            // 3. Thông tin ngữ cảnh dự án & Metadata
            _buildProjectMetaCard(context),

            const SizedBox(height: AppSpacing.space16),

            // 4. Nội dung Prompt yêu cầu
            _buildPromptCard(context),

            const SizedBox(height: AppSpacing.space16),

            // 5. Nội dung phản hồi / Chi tiết lỗi
            _buildResponseCard(context),

            const SizedBox(height: AppSpacing.space16),

            // 6. Mã gọi cURL mẫu
            _buildCurlCard(context),

            const SizedBox(height: AppSpacing.space24),

            // 7. Nút quay lại
            TsButton(
              label: 'Quay lại lịch sử',
              variant: TsButtonVariant.secondary,
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Banner Trạng thái Hero ───────────────────────────────────────
  Widget _buildStatusHero(BuildContext context) {
    final isSuccess = record.isSuccess;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFE7F8F0) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: isSuccess ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 26,
            color: isSuccess ? const Color(0xFF12B76A) : AppColors.error,
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.statusMessage,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      'Mã HTTP ${record.statusCode}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  isSuccess
                      ? 'Yêu cầu API đã hoàn thành bình thường, nội dung trả về đầy đủ.'
                      : (record.errorMessage ??
                          'Yêu cầu bị từ chối hoặc gặp sự cố từ nhà cung cấp.'),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Lưới 4 chỉ số chính ──────────────────────────────────────────
  Widget _buildMetricGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                label: 'Mô hình AI',
                value: record.model,
                subvalue: record.provider,
                icon: Icons.auto_awesome_rounded,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: _buildMetricItem(
                label: 'Tổng số Token',
                value: '${record.formattedTotalTokens} tkn',
                subvalue: 'Vào: ${record.formattedInputTokens} • Ra: ${record.formattedOutputTokens}',
                icon: Icons.all_inclusive_rounded,
                iconColor: AppColors.azure,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                label: 'Chi phí tính toán',
                value: record.formattedCost,
                subvalue: 'Đơn vị tính: USD',
                icon: Icons.attach_money_rounded,
                iconColor: record.isSuccess ? AppColors.emerald : AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: _buildMetricItem(
                label: 'Độ trễ mạng',
                value: '${record.latencyMs} ms',
                subvalue: 'Thời gian khứ hồi (RTT)',
                icon: Icons.timer_outlined,
                iconColor: AppColors.tangerine,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required String subvalue,
    required IconData icon,
    required Color iconColor,
  }) {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
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
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            subvalue,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 3. Dự án & Metadata ─────────────────────────────────────────────
  Widget _buildProjectMetaCard(BuildContext context) {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin ngữ cảnh & Metadata', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.space12),
          _buildInfoRow('Dự án phụ trách', record.project),
          const Divider(height: 16, color: AppColors.border),
          _buildInfoRowWithCopy(
            context,
            label: 'Prompt ID',
            value: record.promptId,
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildInfoRow('Thời điểm thực hiện', record.fullTimeDisplay),
          const Divider(height: 16, color: AppColors.border),
          _buildInfoRow(
            'API Endpoint',
            record.apiEndpoint ?? 'https://api.openai.com/v1/chat/completions',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithCopy(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        InkWell(
          onTap: () => _copyToClipboard(context, value, 'Đã sao chép $label'),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  // ── 4. Prompt Card ──────────────────────────────────────────────────
  Widget _buildPromptCard(BuildContext context) {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.input_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space8),
              Expanded(child: Text('Nội dung Prompt (Yêu cầu)', style: AppTypography.h3)),
              InkWell(
                onTap: () => _copyToClipboard(
                  context,
                  record.promptPreview,
                  'Đã sao chép nội dung Prompt',
                ),
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Sao chép',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              record.promptPreview,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Response Card ────────────────────────────────────────────────
  Widget _buildResponseCard(BuildContext context) {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                record.isSuccess ? Icons.output_rounded : Icons.error_outline_rounded,
                size: 18,
                color: record.isSuccess ? AppColors.emerald : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  record.isSuccess ? 'Nội dung phản hồi từ AI' : 'Chi tiết phản hồi lỗi',
                  style: AppTypography.h3,
                ),
              ),
              InkWell(
                onTap: () => _copyToClipboard(
                  context,
                  record.responsePreview,
                  'Đã sao chép phản hồi',
                ),
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Sao chép',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              color: record.isSuccess ? AppColors.background : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: record.isSuccess ? AppColors.border : const Color(0xFFFECACA),
              ),
            ),
            child: SelectableText(
              record.responsePreview,
              style: TextStyle(
                fontFamily: record.isSuccess ? AppTypography.fontFamily : 'monospace',
                fontSize: 13.5,
                height: 1.5,
                color: record.isSuccess ? AppColors.navy : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Mã gọi cURL ──────────────────────────────────────────────────
  Widget _buildCurlCard(BuildContext context) {
    final curl = '''curl ${record.apiEndpoint ?? 'https://api.openai.com/v1/chat/completions'} \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer \$API_KEY" \\
  -d '{
    "model": "${record.model}",
    "messages": [{"role": "user", "content": "${record.promptPreview.replaceAll('"', '\\"')}"}],
    "metadata": {"prompt_id": "${record.promptId}", "project": "${record.project}"}
  }\'''';

    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 18, color: AppColors.navy),
              const SizedBox(width: AppSpacing.space8),
              Expanded(child: Text('Lệnh gọi cURL tái hiện', style: AppTypography.h3)),
              InkWell(
                onTap: () => _copyToClipboard(context, curl, 'Đã sao chép cURL'),
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Sao chép cURL',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: SelectableText(
              curl,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.45,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
