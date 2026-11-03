import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_bottom_navigation.dart';
import '../../core/widgets/ts_button.dart';
import '../../core/widgets/ts_card.dart';
import '../../core/widgets/ts_dialog.dart';
import '../../core/widgets/ts_logo.dart';
import 'widgets/budget_widgets.dart';

/// Màn hình "Quản lý ngân sách AI".
///
/// Bố cục: Đầu trang → Chu kỳ tính toán → Thẻ hạn mức tổng → Dải cảnh báo →
/// Thanh tiêu trình có vạch ngưỡng → Dự báo chi tiêu → Giới hạn rate-limit →
/// Phân bổ theo nhà cung cấp / dự án → Điều chỉnh ngân sách & ngưỡng →
/// Lịch sử chu kỳ thanh toán.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, this.onBack});

  /// Quay lại màn hình trước (dùng khi mở dạng trang riêng).
  final VoidCallback? onBack;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _autoRateLimit = true;
  int _allocationTab = 0;

  static const _periods = [
    'CHU KỲ: 01/10 - 31/10',
    'CHU KỲ: 01/11 - 30/11',
    'CHU KỲ: 01/12 - 31/12',
  ];

  static const _allocationTabs = ['Theo nhà cung cấp', 'Theo dự án (3)'];

  static const _navItems = [
    TsNavItem(label: 'Tổng quan', icon: Icons.dashboard_rounded),
    TsNavItem(label: 'Lịch sử', icon: Icons.history_rounded),
    TsNavItem(label: 'Ngân sách', icon: Icons.account_balance_wallet_rounded),
    TsNavItem(label: 'Cài đặt', icon: Icons.settings_rounded),
  ];

  // ── Ngân sách tổng ───────────────────────────────────────────────────
  static const _totalLimit = 40.0;
  static const _threshold = 32.0;
  static const _spent = 34.80;
  static const _alertThreshold = 80.0;

  static const _providers = [
    BudgetProvider(
      name: 'OpenAI API',
      models: 'GPT-4o, o1-mini',
      spent: 19.20,
      limit: 22.00,
      color: AppColors.emerald,
    ),
    BudgetProvider(
      name: 'Anthropic Claude',
      models: 'Claude 3.5 Sonnet',
      spent: 8.20,
      limit: 10.00,
      color: Color(0xFF8B5CF6),
    ),
    BudgetProvider(
      name: 'Google Gemini',
      models: 'Gemini 1.5 Pro',
      spent: 7.40,
      limit: 8.00,
      color: AppColors.azure,
    ),
  ];

  static const _projects = [
    BudgetProject(
      name: 'Copilot Backend',
      models: 'gpt-4o, claude-3-5-sonnet',
      spent: 14.20,
      limit: 16.00,
      color: AppColors.primary,
    ),
    BudgetProject(
      name: 'Marketing Agent',
      models: 'gpt-4o-mini',
      spent: 9.60,
      limit: 12.00,
      color: AppColors.tangerine,
    ),
    BudgetProject(
      name: 'RAG Search',
      models: 'gemini-1.5-pro',
      spent: 11.00,
      limit: 12.00,
      color: AppColors.azure,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final percent = _spent / _totalLimit * 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space8,
                  AppSpacing.screenPadding,
                  AppSpacing.space32,
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.space16),
                  _buildTotalBudgetCard(percent),
                  const SizedBox(height: AppSpacing.space12),
                  _buildAlertBanner(),
                  const SizedBox(height: AppSpacing.space16),
                  _buildProgressSection(percent),
                  const SizedBox(height: AppSpacing.space16),
                  _buildForecastCard(),
                  const SizedBox(height: AppSpacing.space12),
                  _buildRateLimitCard(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildAllocationSection(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildAdjustCard(),
                  const SizedBox(height: AppSpacing.space12),
                  _buildBillingHistory(),
                ],
              ),
            ),
            TsBottomNavigation(
              items: _navItems,
              currentIndex: 2,
              onChanged: _onNavChanged,
            ),
          ],
        ),
      ),
    );
  }

  /// Điều hướng dưới — "Ngân sách" đang chọn, các mục khác quay lại dashboard.
  void _onNavChanged(int index) {
    if (index == 2) return;
    Navigator.of(context).maybePop();
  }

  // ── Đầu trang ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TsLogo(size: 30),
            const SizedBox(width: AppSpacing.space8),
            const Flexible(
              child: Text(
                'TokenScope',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 18,
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
            IconButton(
              onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              color: AppColors.navy,
              tooltip: 'Quay lại',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),
        BudgetPeriodChip(
          label: _periods.first,
          onTap: _showPeriodPicker,
        ),
        const SizedBox(height: AppSpacing.space12),
        Text(
          'Quản lý ngân sách AI',
          style: AppTypography.h2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Thẻ hạn mức tổng ──────────────────────────────────────────────────
  Widget _buildTotalBudgetCard(double percent) {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi phí đã dùng',
                      style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${_spent.toStringAsFixed(2)}',
                          style: AppTypography.h1.copyWith(fontSize: 26),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '/ \$${_totalLimit.toStringAsFixed(2)}',
                            style: AppTypography.bodySmall.copyWith(fontSize: 13),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Column(
                  children: [
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: AppTypography.h3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'HẠN MỨC',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                'Còn lại \$${(_totalLimit - _spent).toStringAsFixed(2)}',
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dải cảnh báo ──────────────────────────────────────────────────────
  Widget _buildAlertBanner() {
    return BudgetAlertBanner(
      title: 'CẢNH BÁO: Đã vượt ngưỡng an toàn '
          '${_alertThreshold.toStringAsFixed(0)}%',
      message:
          '(\$${_threshold.toStringAsFixed(2)}). Tốc độ sử dụng cao!',
      onTap: () => _scrollToAdjust(),
    );
  }

  // ── Thanh tiêu trình ──────────────────────────────────────────────────
  Widget _buildProgressSection(double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BudgetProgressBar(
          percent: percent,
          thresholdPercent: _threshold / _totalLimit * 100,
          height: 12,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.space4),
        Row(
          children: [
            Expanded(
              child: Text(
                '\$0.00',
                style: AppTypography.bodySmall.copyWith(fontSize: 12),
              ),
            ),
            Text(
              'Ngưỡng: \$${_threshold.toStringAsFixed(2)}',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Text(
              'Trần: \$${_totalLimit.toStringAsFixed(2)}',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Dự báo chi tiêu ───────────────────────────────────────────────────
  Widget _buildForecastCard() {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      background: AppColors.softPurple,
      borderColor: AppColors.primaryBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 18,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  'Dự báo chi tiêu AI cuối tháng',
                  style: AppTypography.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.primaryDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Dự báo chạm mức \$41.20 vào ngày 31/10 với tốc độ gọi API '
            'hiện nay (Nguy cơ thâm hụt \$1.20)',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Giới hạn rate-limit ───────────────────────────────────────────────
  Widget _buildRateLimitCard() {
    return BudgetSwitchRow(
      title: 'Bật tự động giới hạn Rate-limit',
      description:
          'Tự động dừng gọi API khi đạt ngưỡng để tránh vượt hạn mức.',
      value: _autoRateLimit,
      onChanged: (value) => setState(() => _autoRateLimit = value),
    );
  }

  // ── Phân bổ ngân sách ────────────────────────────────────────────────
  Widget _buildAllocationSection() {
    final isProvider = _allocationTab == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _allocationTabs.length; i++) ...[
              Expanded(
                child: _AllocationTab(
                  label: _allocationTabs[i],
                  isSelected: i == _allocationTab,
                  onTap: () => setState(() => _allocationTab = i),
                ),
              ),
              if (i != _allocationTabs.length - 1)
                const SizedBox(width: AppSpacing.space8),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space12),
        if (isProvider)
          for (final provider in _providers) ...[
            BudgetProviderCard(provider: provider),
            const SizedBox(height: AppSpacing.space12),
          ]
        else
          for (final project in _projects) ...[
            BudgetProjectCard(project: project),
            const SizedBox(height: AppSpacing.space12),
          ],
      ],
    );
  }

  // ── Điều chỉnh ngân sách & ngưỡng cảnh báo ────────────────────────────
  Widget _buildAdjustCard() {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.navy,
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  'Điều chỉnh ngân sách & Ngưỡng cảnh báo',
                  style: AppTypography.label.copyWith(
                    fontSize: 14,
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
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Hạn mức',
                  value: '\$${_totalLimit.toStringAsFixed(2)}',
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: _MiniStat(
                  label: 'Ngưỡng cảnh báo',
                  value: '${_alertThreshold.toStringAsFixed(0)}%',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          TsButton(
            label: 'Lưu ngân sách',
            icon: Icons.save_rounded,
            onPressed: _confirmSaveBudget,
          ),
        ],
      ),
    );
  }

  // ── Lịch sử chu kỳ thanh toán ────────────────────────────────────────
  Widget _buildBillingHistory() {
    return TsCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      onTap: () => _showInfo(
        'Lịch sử chu kỳ thanh toán',
        'Bạn chưa có chu kỳ thanh toán nào trước đó.',
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 18,
            color: AppColors.navy,
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              'Xem lịch sử chu kỳ thanh toán trước',
              style: AppTypography.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }

  // ── Hành động ─────────────────────────────────────────────────────────
  void _showInfo(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title — $message')),
    );
  }

  void _showPeriodPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chọn chu kỳ tính toán', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.space12),
              for (final period in _periods)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  title: Text(period, style: AppTypography.label),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showInfo('Chu kỳ', period);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToAdjust() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Điều chỉnh hạn mức ở mục "Điều chỉnh ngân sách".')),
    );
  }

  Future<void> _confirmSaveBudget() async {
    final confirmed = await TsDialog.show(
      context,
      title: 'Lưu ngân sách mới?',
      message:
          'Hạn mức tháng này sẽ được đặt thành \$${_totalLimit.toStringAsFixed(2)} '
          'USD. Bạn sẽ nhận cảnh báo khi sử dụng đến '
          '${_alertThreshold.toStringAsFixed(0)}%.',
      confirmLabel: 'Lưu ngân sách',
    );
    if (!confirmed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật ngân sách tháng 11.')),
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

/// Chip chuyển đổi giữa "Theo nhà cung cấp" và "Theo dự án".
class _AllocationTab extends StatelessWidget {
  const _AllocationTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Chỉ số nhỏ trong thẻ điều chỉnh.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h3.copyWith(fontSize: 17, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
