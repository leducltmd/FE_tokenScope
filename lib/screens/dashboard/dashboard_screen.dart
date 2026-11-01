import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_bottom_navigation.dart';
import '../../core/widgets/ts_button.dart';
import '../../core/widgets/ts_card.dart';
import '../../core/widgets/ts_dialog.dart';
import '../../core/widgets/ts_states.dart';
import '../../providers/auth_controller.dart';
import 'widgets/activity_feed.dart';
import 'widgets/budget_alert_banner.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/provider_usage_card.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/weekly_usage_chart.dart';

/// Màn hình tổng quan của TokenScope.
///
/// Bố cục: Đầu trang → Cảnh báo ngân sách → Thẻ chỉ số nổi bật → Lưới
/// hành động nhanh → Biểu đồ 7 ngày → Phân bổ nhà cung cấp → Truy vấn gần
/// nhất → Thanh điều hướng dưới 4 mục.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    this.onLogout,
  });

  final AuthController controller;
  final VoidCallback? onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;
  String _range = '7 ngày qua';

  static const _navItems = [
    TsNavItem(label: 'Tổng quan', icon: Icons.dashboard_rounded),
    TsNavItem(label: 'Lịch sử', icon: Icons.history_rounded),
    TsNavItem(label: 'Ngân sách', icon: Icons.account_balance_wallet_rounded),
    TsNavItem(label: 'Cài đặt', icon: Icons.settings_rounded),
  ];

  static const _ranges = ['7 ngày qua', '30 ngày qua', '3 tháng qua'];

  // ── Dữ liệu mẫu theo đặc tả ──────────────────────────────────────────
  static const _providers = [
    TsProviderUsage(
      name: 'OpenAI',
      percent: 49,
      models: 'GPT-4o, GPT-3.5 Turbo',
      tokens: '1.200.000',
      cost: '\$19.20 USD',
      letter: 'O',
      color: AppColors.emerald,
    ),
    TsProviderUsage(
      name: 'Google Gemini',
      percent: 33,
      models: 'Gemini 1.5 Pro, Flash',
      tokens: '800.000',
      cost: '\$7.40 USD',
      letter: 'G',
      color: AppColors.azure,
    ),
    TsProviderUsage(
      name: 'Anthropic Claude',
      percent: 18,
      models: 'Claude 3.5 Sonnet, Haiku',
      tokens: '450.000',
      cost: '\$8.20 USD',
      letter: 'A',
      color: AppColors.tangerine,
    ),
  ];

  static const _weeklyPoints = [
    TsWeeklyPoint(label: 'T2', value: 180000, display: '180k'),
    TsWeeklyPoint(label: 'T3', value: 240000, display: '240k'),
    TsWeeklyPoint(label: 'T4', value: 205000, display: '205k'),
    TsWeeklyPoint(label: 'T5', value: 450000, display: '450k', isHighlighted: true),
    TsWeeklyPoint(label: 'T6', value: 320000, display: '320k'),
    TsWeeklyPoint(label: 'T7', value: 285000, display: '285k'),
    TsWeeklyPoint(label: 'CN', value: 290000, display: '290k'),
  ];

  static const _activities = [
    TsActivityEntry(
      model: 'claude-3-5-sonnet',
      project: 'Copilot Backend',
      tokens: '1.420 tkn',
      cost: '\$0.0042',
      time: '14:28:05',
      letter: 'C',
      color: AppColors.tangerine,
    ),
    TsActivityEntry(
      model: 'gpt-4o',
      project: 'Marketing Agent',
      tokens: '3.860 tkn',
      cost: '\$0.0098',
      time: '14:25:41',
      letter: 'O',
      color: AppColors.emerald,
    ),
    TsActivityEntry(
      model: 'gemini-1.5-pro',
      project: 'RAG Search',
      tokens: '2.130 tkn',
      cost: '\$0.0031',
      time: '14:19:12',
      letter: 'G',
      color: AppColors.azure,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        // Lắng nghe controller để lời chào cập nhật theo tên vừa đăng ký.
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Column(
              children: [
                Expanded(
                  child: switch (_tabIndex) {
                    0 => _buildOverview(),
                    1 => _buildHistory(),
                    2 => _buildBudget(),
                    _ => _buildSettings(),
                  },
                ),
                TsBottomNavigation(
                  items: _navItems,
                  currentIndex: _tabIndex,
                  onChanged: (index) => setState(() => _tabIndex = index),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Tổng quan ─────────────────────────────────────────────────────────
  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.space32),
      children: [
        TsDashboardHeader(
          greeting: 'Xin chào, ${widget.controller.shortName}',
          subtitle: 'Theo dõi token & chi phí AI đa nền tảng',
          userName: widget.controller.displayName,
          lastSynced: 'Đồng bộ 1m trước',
          onNotifications: () => _showInfo('Thông báo', 'Bạn không có thông báo mới.'),
          onAvatar: () => setState(() => _tabIndex = 3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TsBudgetAlertBanner(
                title: 'Cảnh báo ngân sách',
                percentLabel: '87% mức trần',
                message:
                    'Đã sử dụng 87% ngân sách tháng (\$34.80 / \$40.00). '
                    'Chạm để điều chỉnh.',
                onTap: () => setState(() => _tabIndex = 2),
              ),
              const SizedBox(height: AppSpacing.space16),
              TsHeroMetricCard(
                totalTokens: '2.450.000',
                totalTokensLabel: 'tokens',
                costLabel: '\$34.80 USD',
                inputTokens: '1.800.000',
                inputPercent: 0.735,
                outputTokens: '650.000',
                outputPercent: 0.265,
                budgetLabel: 'Tiến trình chi tiêu tháng',
                remainingLabel: 'Còn lại \$5.20 / \$40.00',
                spentPercent: 0.87,
              ),
              const SizedBox(height: AppSpacing.space16),
              TsQuickActionGrid(
                actions: [
                  TsQuickAction(
                    label: 'Phân tích',
                    icon: Icons.insights_rounded,
                    color: AppColors.violet,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                  TsQuickAction(
                    label: 'Đối tác',
                    icon: Icons.hub_rounded,
                    color: AppColors.emerald,
                    onTap: () => _showInfo(
                      'Đối tác',
                      '3 nhà cung cấp đang kết nối: OpenAI, Google Gemini, Anthropic Claude.',
                    ),
                  ),
                  TsQuickAction(
                    label: 'Dự án',
                    icon: Icons.folder_special_rounded,
                    color: AppColors.azure,
                    onTap: () => _showInfo(
                      'Dự án',
                      '4 dự án đang dùng token: Copilot Backend, Marketing Agent, RAG Search và Website Bot.',
                    ),
                  ),
                  TsQuickAction(
                    label: 'Cảnh báo',
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.tangerine,
                    onTap: () => setState(() => _tabIndex = 2),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space24),
              _buildWeeklySection(),
              const SizedBox(height: AppSpacing.space24),
              _buildSectionTitle(
                'Phân bổ theo nhà cung cấp',
                'Chi tiết >',
                onTrailingTap: () => _showInfo(
                  'Phân bổ chi tiết',
                  'Tổng 2.450.000 token trên 3 nhà cung cấp trong tháng này.',
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              for (final provider in _providers) ...[
                TsProviderUsageCard(provider: provider),
                const SizedBox(height: AppSpacing.space12),
              ],
              const SizedBox(height: AppSpacing.space12),
              _buildSectionTitle('Truy vấn gần nhất', '14:28:05'),
              const SizedBox(height: AppSpacing.space12),
              TsActivityFeed(entries: _activities),
            ],
          ),
        ),
      ],
    );
  }

  // ── Biểu đồ 7 ngày ────────────────────────────────────────────────────
  Widget _buildWeeklySection() {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Xu hướng sử dụng 7 ngày',
                  style: AppTypography.h3.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              _RangeDropdown(
                value: _range,
                options: _ranges,
                onChanged: (value) => setState(() => _range = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Tổng 7 ngày: 1.970.000 • TB: ~281k/ngày (Đỉnh: T5)',
            style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: AppSpacing.space16),
          TsWeeklyChart(points: _weeklyPoints),
        ],
      ),
    );
  }

  // ── Lịch sử ───────────────────────────────────────────────────────────
  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space16,
        AppSpacing.screenPadding,
        AppSpacing.space32,
      ),
      children: [
        _buildSectionTitle('Lịch sử sử dụng', 'Hôm nay'),
        const SizedBox(height: AppSpacing.space12),
        TsEmptyState(
          title: 'Chưa có bản ghi sử dụng',
          message:
              'Không tìm thấy dữ liệu phù hợp với bộ lọc hiện tại. '
              'Xóa bộ lọc để xem toàn bộ lịch sử sử dụng.',
          actionLabel: 'Xóa bộ lọc',
          onAction: () => setState(() {}),
        ),
      ],
    );
  }

  // ── Ngân sách ─────────────────────────────────────────────────────────
  Widget _buildBudget() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space16,
        AppSpacing.screenPadding,
        AppSpacing.space32,
      ),
      children: [
        _buildSectionTitle('Ngân sách tháng này', 'Tháng 11'),
        const SizedBox(height: AppSpacing.space12),
        TsCard(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ngân sách tháng 11', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.space8),
              Row(
                children: [
                  Text(
                    '\$34.80 USD',
                    style: AppTypography.label.copyWith(color: AppColors.navy),
                  ),
                  Text(' / \$40.00 USD', style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.87,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Đã dùng 87% · Còn lại \$5.20 USD',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        TsButton(
          label: 'Lưu ngân sách',
          icon: Icons.save_rounded,
          onPressed: _confirmSaveBudget,
        ),
      ],
    );
  }

  // ── Cài đặt ───────────────────────────────────────────────────────────
  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space16,
        AppSpacing.screenPadding,
        AppSpacing.space32,
      ),
      children: [
        _buildSectionTitle('Cài đặt', 'Tài khoản'),
        const SizedBox(height: AppSpacing.space12),
        TsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSettingsRow(
                icon: Icons.person_outline_rounded,
                label: 'Hồ sơ',
                value: 'demo@tokenscope.io',
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildSettingsRow(
                icon: Icons.notifications_outlined,
                label: 'Cảnh báo ngân sách',
                value: 'Ở mức 80%',
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildSettingsRow(
                icon: Icons.link_rounded,
                label: 'Khóa API',
                value: '•••• •••• 8f2a',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        TsButton(
          label: 'Đăng xuất',
          variant: TsButtonVariant.danger,
          icon: Icons.logout_rounded,
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.label.copyWith(color: AppColors.navy),
            ),
          ),
          Text(value, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  // ── Tiêu đề nhóm ──────────────────────────────────────────────────────
  Widget _buildSectionTitle(
    String title,
    String trailing, {
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.h3.copyWith(fontSize: 17),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        if (onTrailingTap != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: 2,
              ),
              child: Text(
                trailing,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else
          Text(
            trailing,
            style: AppTypography.bodySmall.copyWith(fontSize: 13),
          ),
      ],
    );
  }

  // ── Hành động ─────────────────────────────────────────────────────────
  void _showInfo(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title — $message')),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await TsDialog.show(
      context,
      title: 'Đăng xuất',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục theo dõi chi phí API.',
      confirmLabel: 'Đăng xuất',
    );
    if (!confirmed || !mounted) return;

    await widget.controller.logout();
    widget.onLogout?.call();
  }

  Future<void> _confirmSaveBudget() async {
    final confirmed = await TsDialog.show(
      context,
      title: 'Lưu ngân sách mới?',
      message:
          'Ngân sách tháng này sẽ được đặt thành \$40.00 USD. '
          'Bạn sẽ nhận cảnh báo khi sử dụng đến 80%.',
      confirmLabel: 'Lưu ngân sách',
    );
    if (!confirmed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật ngân sách tháng 11.')),
    );
  }
}

/// Nút chọn khoảng thời gian — dạng dropdown nhỏ gọn.
class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Chọn khoảng thời gian',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            height: 40,
            child: Text(option, style: AppTypography.label),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.softPurple,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}
