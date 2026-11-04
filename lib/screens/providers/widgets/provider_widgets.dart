import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ts_logo.dart';

/// Một nhà cung cấp AI đang kết nối.
///
/// Mỗi nhà cung cấp có: tên, danh sách mô hình, tổng token, chi phí, tỷ lệ
/// chiếm hạn mức và trạng thái kết nối.
class AiProvider {
  const AiProvider({
    required this.name,
    required this.models,
    required this.tokens,
    required this.cost,
    required this.percent,
    required this.letter,
    required this.color,
    required this.status,
    this.statusLabel = 'Đang hoạt động',
  });

  /// Tên nhà cung cấp — `OpenAI`.
  final String name;

  /// Các mô hình đang dùng — `GPT-4o, GPT-3.5 Turbo`.
  final String models;

  /// Tổng token đã tiêu thụ — `1.200.000`.
  final String tokens;

  /// Chi phí đã phát sinh — `\$19.20`.
  final String cost;

  /// Tỷ lệ chiếm hạn mức — `49`.
  final int percent;

  /// Chữ cái hiển thị trong ô logo.
  final String letter;

  /// Màu nhận diện của nhà cung cấp.
  final Color color;

  /// Trạng thái kết nối.
  final ProviderStatus status;

  /// Nhãn trạng thái hiển thị cạnh chấm màu.
  final String statusLabel;
}

/// Trạng thái kết nối của nhà cung cấp.
enum ProviderStatus {
  /// Đang kết nối và nhận dữ liệu bình thường.
  connected('Hoạt động', AppColors.success, AppColors.successLight),

  /// Đang chờ xác thực khóa API.
  pending('Chờ xác thực', AppColors.warning, AppColors.warningLight),

  /// Kết nối lỗi, cần kiểm tra lại khóa API.
  error('Lỗi kết nối', AppColors.error, AppColors.errorLight);

  const ProviderStatus(this.label, this.color, this.background);

  /// Nhãn trạng thái.
  final String label;

  /// Màu chấm trạng thái.
  final Color color;

  /// Màu nền huy hiệu trạng thái.
  final Color background;
}

// ── Đầu trang ─────────────────────────────────────────────────────────────

/// Đầu trang trang nhà cung cấp — nút quay lại, tiêu đề và tóm tắt.
class ProvidersHeader extends StatelessWidget {
  const ProvidersHeader({
    super.key,
    required this.providerCount,
    required this.totalTokens,
    this.onBack,
  });

  /// Số nhà cung cấp đang kết nối — `3`.
  final int providerCount;

  /// Tổng token của tất cả nhà cung cấp — `2.450.000`.
  final String totalTokens;

  /// Quay lại màn hình trước.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space12,
        AppSpacing.space8,
        AppSpacing.screenPadding,
        AppSpacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Quay lại',
                onPressed: onBack,
              ),
              const SizedBox(width: AppSpacing.space12),
              const TsLogo(size: 30),
              const Spacer(),
              const _LiveBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            'Nhà cung cấp',
            style: AppTypography.h2.copyWith(fontSize: 24),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$providerCount nhà cung cấp đang kết nối • $totalTokens token',
            style: AppTypography.bodySmall.copyWith(fontSize: 13.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Nút biểu tượng tròn trong đầu trang.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

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
            child: Icon(icon, size: 21, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

/// Huy hiệu "Live" — chấm xanh kèm nhãn trạng thái.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

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
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.live,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Live',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.live,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thẻ tóm tắt ───────────────────────────────────────────────────────────

/// Thẻ tóm tắt — tổng token, tổng chi phí và thanh phân bổ.
class ProviderSummaryCard extends StatelessWidget {
  const ProviderSummaryCard({
    super.key,
    required this.totalTokens,
    required this.totalCost,
    required this.limit,
    required this.breakdown,
  });

  /// Tổng token — `2.450.000`.
  final String totalTokens;

  /// Tổng chi phí — `\$34.80`.
  final String totalCost;

  /// Hạn mức chi phí — `\$40.00`.
  final String limit;

  /// Phân bổ theo từng nhà cung cấp.
  final List<AiProvider> breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.indigoSoft,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatPanel(
                  label: 'TỔNG TOKEN',
                  value: totalTokens,
                  suffix: 'token',
                  note: 'Tháng này',
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: _StatPanel(
                  label: 'TỔNG CHI PHÍ',
                  value: totalCost,
                  suffix: limit,
                  note: 'Hạn mức tháng',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          _BreakdownBar(breakdown: breakdown),
          const SizedBox(height: AppSpacing.space12),
          Wrap(
            spacing: AppSpacing.space16,
            runSpacing: AppSpacing.space8,
            children: [
              for (final item in breakdown)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${item.name} (${item.percent}%)',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ô số liệu trong thẻ tóm tắt.
class _StatPanel extends StatelessWidget {
  const _StatPanel({
    required this.label,
    required this.value,
    required this.suffix,
    required this.note,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final String suffix;
  final String note;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.primaryDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: alignEnd
                    ? Alignment.bottomRight
                    : Alignment.bottomLeft,
                child: Text(
                  value,
                  style: AppTypography.h2.copyWith(fontSize: 21),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              suffix,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
              maxLines: 1,
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          note,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Dải phân bổ — mỗi nhà cung cấp một mảng, chiều rộng theo tỷ trọng.
class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({required this.breakdown});

  final List<AiProvider> breakdown;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in breakdown)
              Expanded(
                flex: (item.percent * 10).round(),
                child: ColoredBox(color: item.color),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Thẻ nhà cung cấp ──────────────────────────────────────────────────────

/// Thẻ chi tiết một nhà cung cấp — logo, mô hình, token, chi phí, hạn mức.
class AiProviderCard extends StatelessWidget {
  const AiProviderCard({super.key, required this.provider, this.onTap});

  final AiProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.space16),
              _buildMetrics(),
              const SizedBox(height: AppSpacing.space12),
              _buildProgress(),
              const SizedBox(height: AppSpacing.space12),
              _buildModels(),
              const SizedBox(height: AppSpacing.space12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.space4),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Đầu thẻ: logo · tên · mô hình · trạng thái ──────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: provider.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Text(
            provider.letter,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: provider.color,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: AppTypography.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                provider.models,
                style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        ProviderStatusBadge(status: provider.status, label: provider.statusLabel),
      ],
    );
  }

  // ── Số liệu: token · chi phí ─────────────────────────────────────────
  Widget _buildMetrics() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOKEN ĐÃ DÙNG',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                provider.tokens,
                style: AppTypography.h2.copyWith(fontSize: 21),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Tổng lượt truy cập',
                style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'CHI PHÍ',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                provider.cost,
                style: AppTypography.h2.copyWith(fontSize: 21),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'USD',
                style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Thanh hạn mức ─────────────────────────────────────────────────────
  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hạn mức đã dùng',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const Spacer(),
            Text(
              '${provider.percent}%',
              style: AppTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: provider.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: provider.percent / 100,
            minHeight: 6,
            backgroundColor: provider.color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(provider.color),
          ),
        ),
      ],
    );
  }

  // ── Chip mô hình AI ───────────────────────────────────────────────────
  Widget _buildModels() {
    final models = provider.models.split(',').map((m) => m.trim()).toList();

    return Wrap(
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: [
        for (final model in models)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: provider.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  model,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Chân thẻ: khóa API · quản lý ─────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      children: [
        const Icon(
          Icons.key_rounded,
          size: 15,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: 6),
        Text(
          'Khóa API: •••• •••• 8f2a',
          style: AppTypography.bodySmall.copyWith(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Text(
          'Quản lý',
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 16,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

/// Huy hiệu trạng thái kết nối — chấm màu kèm nhãn.
class ProviderStatusBadge extends StatelessWidget {
  const ProviderStatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  final ProviderStatus status;

  /// Nhãn hiển thị — mặc định lấy từ [ProviderStatus].
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label ?? status.label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kết nối nhà cung cấp mới ──────────────────────────────────────────────

/// Thẻ kết nối nhà cung cấp mới — mô tả ngắn và nút hành động chính.
class ConnectProviderCard extends StatelessWidget {
  const ConnectProviderCard({
    super.key,
    required this.onConnect,
    this.description =
        'Kết nối thêm nhà cung cấp AI để theo dõi token và chi phí '
            'trên toàn bộ mô hình bạn đang dùng.',
  });

  /// Mở luồng kết nối nhà cung cấp mới.
  final VoidCallback? onConnect;

  /// Mô tả ngắn bên dưới tiêu đề.
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.indigoSoft,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.add_link_rounded,
                  size: 20,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  'Kết nối nhà cung cấp mới',
                  style: AppTypography.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.space16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.indigo,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: InkWell(
                onTap: onConnect,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.onPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kết nối nhà cung cấp',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghi chú nhỏ cuối trang — giải thích cách TokenScope thu thập dữ liệu.
class ProviderNote extends StatelessWidget {
  const ProviderNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              'Dữ liệu được đồng bộ tự động mỗi 5 phút. '
              'Bạn có thể chủ động làm mới bất cứ lúc nào trong phần Cài đặt.',
              style: AppTypography.bodySmall.copyWith(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
