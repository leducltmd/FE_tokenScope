import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_bottom_navigation.dart';
import '../../core/widgets/ts_button.dart';
import '../../core/widgets/ts_card.dart';
import '../../core/widgets/ts_dialog.dart';
import '../../models/usage_summary.dart';
import '../../providers/auth_controller.dart';
import '../../providers/budget_controller.dart';
import '../../providers/dashboard_controller.dart';
import '../../providers/usage_history_controller.dart';
import '../usage_history/usage_history_screen.dart';
import '../analysis/ai_analysis_screen.dart';
import '../budget/budget_screen.dart';
import '../projects/projects_screen.dart';
import '../providers/providers_screen.dart';
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
    this.dashboardController,
    this.historyController,
    this.budgetController,
  });

  final AuthController controller;
  final VoidCallback? onLogout;

  /// Controller tổng quan — nếu null thì tự tạo (gọi backend thật).
  final DashboardController? dashboardController;

  /// Controller lịch sử — nếu null thì tự tạo (gọi backend thật).
  final UsageHistoryController? historyController;

  /// Controller ngân sách — nếu null thì tự tạo (gọi backend thật).
  final BudgetController? budgetController;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;
  late final UsageHistoryController _historyController =
      widget.historyController ?? UsageHistoryController();

  /// Số liệu tổng quan lấy từ backend thật.
  late final DashboardController _dashboardController =
      widget.dashboardController ?? DashboardController();

  @override
  void initState() {
    super.initState();
    _dashboardController.load();
    // Nạp sẵn vài bản ghi gần nhất cho mục "Truy vấn gần nhất".
    _historyController.loadRecords();
  }

  @override
  void dispose() {
    // Chỉ dispose những controller do màn hình tự tạo.
    if (widget.historyController == null) _historyController.dispose();
    if (widget.dashboardController == null) _dashboardController.dispose();
    super.dispose();
  }
  String _range = '7 ngày qua';

  static const _navItems = [
    TsNavItem(label: 'Tổng quan', icon: Icons.dashboard_rounded),
    TsNavItem(label: 'Lịch sử', icon: Icons.history_rounded),
    TsNavItem(label: 'Ngân sách', icon: Icons.account_balance_wallet_rounded),
    TsNavItem(label: 'Cài đặt', icon: Icons.settings_rounded),
  ];

  static const _ranges = ['7 ngày qua', '30 ngày qua', '3 tháng qua'];

  /// Màu nhận diện theo loại nhà cung cấp.
  static const _providerColors = <String, Color>{
    'openai': AppColors.emerald,
    'anthropic': AppColors.tangerine,
    'google': AppColors.azure,
    'mistral': AppColors.tangerine,
    'groq': AppColors.grape,
  };

  /// Định dạng số theo chuẩn Việt Nam — `2.450.000`.
  static String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // ── Dữ liệu thật từ backend ───────────────────────────────────────────
  UsageSummary? get _summary => _dashboardController.summary;

  /// Danh sách nhà cung cấp dựng từ dữ liệu thật.
  List<TsProviderUsage> get _providerUsages {
    final summary = _summary;
    if (summary == null) return const <TsProviderUsage>[];

    final totalCost = summary.totalCost;

    return summary.byProvider.map((item) {
      final percent = totalCost <= 0
          ? 0
          : ((item.totalCost / totalCost) * 100).round().clamp(0, 100);
      return TsProviderUsage(
        name: item.provider,
        percent: percent,
        models: '${item.requestCount} lượt gọi · ${_formatNumber(item.totalTokens)} token',
        tokens: _formatNumber(item.totalTokens),
        cost: '\$${item.totalCost.toStringAsFixed(2)} USD',
        letter: item.provider.isEmpty
            ? '?'
            : item.provider.substring(0, 1).toUpperCase(),
        color: _providerColors[item.providerType] ?? AppColors.primary,
      );
    }).toList();
  }

  /// Điểm biểu đồ 7 ngày lấy từ dữ liệu thật.
  List<TsWeeklyPoint> get _weeklyPoints {
    final summary = _summary;
    if (summary == null || summary.daily.isEmpty) {
      return const <TsWeeklyPoint>[];
    }

    const labels = <String>['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final days = summary.daily.length > 7
        ? summary.daily.sublist(summary.daily.length - 7)
        : summary.daily;

    final maxValue = days.fold<int>(
      0,
      (max, d) => d.totalTokens > max ? d.totalTokens : max,
    );

    return days.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      final value = day.totalTokens;
      final label = index < labels.length
          ? labels[labels.length - days.length + index]
          : day.date.substring(5);
      return TsWeeklyPoint(
        label: label,
        value: value.toDouble(),
        display: value >= 1000
            ? '${(value / 1000).toStringAsFixed(0)}k'
            : '$value',
        isHighlighted: maxValue > 0 && value == maxValue,
      );
    }).toList();
  }

  /// Tổng token 7 ngày gần nhất.
  double get _weeklyTotal => _weeklyPoints.fold<double>(
    0,
    (sum, point) => sum + point.value,
  );

  /// Lượt gọi gần nhất từ controller lịch sử.
  List<TsActivityEntry> get _recentActivities {
    return _historyController.records.take(3).map((record) {
      final letter = record.provider.isEmpty
          ? '?'
          : record.provider.substring(0, 1).toUpperCase();
      return TsActivityEntry(
        model: record.model,
        project: record.project,
        tokens: '${_formatNumber(record.totalTokens)} tkn',
        cost: '\$${record.cost.toStringAsFixed(4)}',
        time: record.timeDisplay,
        letter: letter,
        color: _providerColors[_providerTypeOf(record.provider)] ??
            AppColors.primary,
      );
    }).toList();
  }

  /// Suy ra mã providerType từ tên nhà cung cấp.
  static String _providerTypeOf(String provider) {
    final value = provider.toLowerCase();
    if (value.contains('openai')) return 'openai';
    if (value.contains('gemini') || value.contains('google')) return 'google';
    if (value.contains('anthropic') || value.contains('claude')) {
      return 'anthropic';
    }
    if (value.contains('mistral')) return 'mistral';
    if (value.contains('groq')) return 'groq';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        // Lắng nghe controller để lời chào cập nhật theo tên vừa đăng ký.
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.controller, _dashboardController]),
          builder: (context, _) {
            return Column(
              children: [
                Expanded(
                  child: switch (_tabIndex) {
                    0 => _buildOverview(),
                    1 => _buildHistory(),
                    _ => _buildSettings(),
                  },
                ),
                TsBottomNavigation(
                  items: _navItems,
                  currentIndex: _tabIndex,
                  onChanged: (index) {
                    // "Ngân sách" mở trang quản lý ngân sách AI riêng.
                    if (index == 2) {
                      _openBudgetScreen();
                      return;
                    }
                    setState(() => _tabIndex = index);
                  },
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
                percentLabel:
                    '${(_summary?.totalCost ?? 0).toStringAsFixed(2)} USD đã dùng',
                message:
                    'Tổng chi phí AI trong kỳ hiện tại là '
                    '\$${(_summary?.totalCost ?? 0).toStringAsFixed(2)} '
                    '(${_summary?.requestCount ?? 0} lượt gọi). '
                    'Chạm để điều chỉnh.',
                onTap: _openBudgetScreen,
              ),
              const SizedBox(height: AppSpacing.space16),
              TsHeroMetricCard(
                totalTokens: _formatNumber(_summary?.totalTokens ?? 0),
                totalTokensLabel: 'tokens',
                costLabel: '\$${(_summary?.totalCost ?? 0).toStringAsFixed(2)} USD',
                inputTokens: _formatNumber(_summary?.totalTokens ?? 0),
                inputPercent: 0.735,
                outputTokens: '0',
                outputPercent: 0.265,
                budgetLabel: 'Tiến trình chi tiêu tháng',
                remainingLabel:
                    'Tổng chi phí \$${(_summary?.totalCost ?? 0).toStringAsFixed(2)}',
                spentPercent: 0.87,
              ),
              const SizedBox(height: AppSpacing.space16),
              TsQuickActionGrid(
                actions: [
                  TsQuickAction(
                    label: 'Phân tích',
                    icon: Icons.insights_rounded,
                    color: AppColors.violet,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AiAnalysisScreen(),
                      ),
                    ),
                  ),
                  TsQuickAction(
                    label: 'Đối tác',
                    icon: Icons.hub_rounded,
                    color: AppColors.emerald,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProvidersScreen(),
                      ),
                    ),
                  ),
                  TsQuickAction(
                    label: 'Dự án',
                    icon: Icons.folder_special_rounded,
                    color: AppColors.azure,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProjectsScreen(),
                      ),
                    ),
                  ),
                  TsQuickAction(
                    label: 'Cảnh báo',
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.tangerine,
                    onTap: _openBudgetScreen,
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
                  'Tổng ${_formatNumber(_summary?.totalTokens ?? 0)} token '
                      'trên ${_summary?.byProvider.length ?? 0} nhà cung cấp.',
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              for (final provider in _providerUsages) ...[
                TsProviderUsageCard(provider: provider),
                const SizedBox(height: AppSpacing.space12),
              ],
              const SizedBox(height: AppSpacing.space12),
              _buildSectionTitle('Truy vấn gần nhất', 'Hôm nay'),
              const SizedBox(height: AppSpacing.space12),
              TsActivityFeed(entries: _recentActivities),
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
            'Tổng 7 ngày: ${_formatNumber(_weeklyTotal.round())} token',
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
    return UsageHistoryScreen(
      controller: _historyController,
      userName: widget.controller.displayName,
      embedded: true,
      onAvatar: () => setState(() => _tabIndex = 3),
      onNotifications: () => _showInfo('Thông báo', 'Bạn không có thông báo mới.'),
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
  /// Mở trang quản lý ngân sách AI.
  void _openBudgetScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BudgetScreen(controller: widget.budgetController),
      ),
    );
  }

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
