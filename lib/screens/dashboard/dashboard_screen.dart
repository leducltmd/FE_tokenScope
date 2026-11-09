import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../providers/firebase_lab3_controller.dart';
import '../../providers/providers_controller.dart';
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
import 'package:flutter/services.dart';
import '../alerts/alerts_screen.dart';
import 'widgets/promo_banner.dart';

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
  bool _showPromoBanner = true;
  final _firebase = FirebaseLab3Controller.instance;

  late final UsageHistoryController _historyController =
      widget.historyController ?? UsageHistoryController();

  /// Số liệu tổng quan lấy từ backend thật.
  late final DashboardController _dashboardController =
      widget.dashboardController ?? DashboardController();
  late final BudgetController _budgetController =
      widget.budgetController ?? BudgetController();
  late final StreamSubscription<void> _usageChanges;
  Future<void>? _usageRefresh;

  @override
  void initState() {
    super.initState();
    _historyController.setMaxVisibleRecords(_firebase.maxHistoryItems);
    _refreshUsage();
    _usageChanges = ProvidersController.usageChanges.listen(
      (_) => _refreshUsage(),
    );
  }

  void _refreshUsage() {
    // Giữ lần tải lại sau đồng bộ nếu lần tải trước vẫn đang chạy.
    final pending = _usageRefresh;
    _usageRefresh = pending == null
        ? _loadUsage()
        : pending.then((_) => _loadUsage());
  }

  Future<void> _loadUsage() async {
    if (!mounted) return;
    await Future.wait([
      _dashboardController.load(),
      _historyController.loadRecords(refresh: true),
      _budgetController.load(),
    ]);
  }

  @override
  void dispose() {
    _usageChanges.cancel();
    // Chỉ dispose những controller do màn hình tự tạo.
    if (widget.historyController == null) _historyController.dispose();
    if (widget.dashboardController == null) _dashboardController.dispose();
    if (widget.budgetController == null) _budgetController.dispose();
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
        models:
            '${item.requestCount} lượt gọi · ${_formatNumber(item.totalTokens)} token',
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
  double get _weeklyTotal =>
      _weeklyPoints.fold<double>(0, (sum, point) => sum + point.value);

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
        color:
            _providerColors[_providerTypeOf(record.provider)] ??
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
          listenable: Listenable.merge([
            widget.controller,
            _dashboardController,
          ]),
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
          onNotifications: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AlertsScreen())),
          onAvatar: () => setState(() => _tabIndex = 3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showPromoBanner && _firebase.isPromoBannerEnabled)
                TsPromoBanner(
                  message: _firebase.promoBannerText,
                  onDismiss: () => setState(() => _showPromoBanner = false),
                ),
              TsBudgetAlertBanner(
                title: 'Cảnh báo ngân sách',
                percentLabel:
                    '${(_summary?.totalCost ?? 0).toStringAsFixed(2)} USD đã dùng',
                message:
                    'Tổng chi phí AI đã ghi nhận là '
                    '\$${(_summary?.totalCost ?? 0).toStringAsFixed(2)} '
                    '(${_summary?.requestCount ?? 0} lượt gọi). '
                    'Chạm để điều chỉnh.',
                onTap: _openBudgetScreen,
              ),
              const SizedBox(height: AppSpacing.space16),
              ListenableBuilder(
                listenable: _budgetController,
                builder: (context, _) => _buildHeroMetricCard(),
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
              ListenableBuilder(
                listenable: _historyController,
                builder: (context, _) =>
                    TsActivityFeed(entries: _recentActivities),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Biểu đồ 7 ngày ────────────────────────────────────────────────────
  Widget _buildHeroMetricCard() {
    final summary = _summary;
    final inputTokens = summary?.inputTokens;
    final outputTokens = summary?.outputTokens;
    final hasBreakdown = inputTokens != null && outputTokens != null;
    final splitTotal = (inputTokens ?? 0) + (outputTokens ?? 0);
    final denominator = splitTotal > 0 ? splitTotal : 1;

    final budget = _budgetController.overview;
    var budgetDetails = _budgetController.hasError
        ? 'Không tải được hạn mức'
        : 'Đang tải hạn mức…';
    double? spentPercent;
    if (budget != null) {
      budgetDetails = 'Chưa đặt hạn mức';
      if (budget.totalLimit > 0) {
        budgetDetails =
            '\$${budget.spent.toStringAsFixed(2)} / '
            '\$${budget.totalLimit.toStringAsFixed(2)}';
        spentPercent = budget.spent / budget.totalLimit;
      }
    }

    return TsHeroMetricCard(
      totalTokens: _formatNumber(summary?.totalTokens ?? 0),
      totalTokensLabel: 'tokens',
      costLabel: '\$${(summary?.totalCost ?? 0).toStringAsFixed(2)} USD',
      inputTokens: inputTokens == null ? '—' : _formatNumber(inputTokens),
      inputPercent: hasBreakdown ? (inputTokens ?? 0) / denominator : null,
      outputTokens: outputTokens == null ? '—' : _formatNumber(outputTokens),
      outputPercent: hasBreakdown ? (outputTokens ?? 0) / denominator : null,
      budgetLabel: 'Tiến trình chi tiêu tháng',
      remainingLabel: budgetDetails,
      spentPercent: spentPercent,
    );
  }

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
      onNotifications: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AlertsScreen())),
    );
  }

  // ── Cài đặt ─────────────────────────────────────────────────────────────
  Widget _buildSettings() {
    final user = widget.controller.user;
    final email = user?.email ?? 'Chưa đăng nhập';
    final uid = user?.id ?? 'Chưa xác thực UID';
    final authMethod = user?.authProvider == 'google'
        ? 'Google Sign-In'
        : 'Email/Mật khẩu';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space16,
        AppSpacing.screenPadding,
        AppSpacing.space32,
      ),
      children: [
        // 1. Tài khoản
        _buildSectionTitle('Tài khoản', 'Đang hoạt động'),
        const SizedBox(height: AppSpacing.space12),
        TsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSettingsRow(
                icon: Icons.person_outline_rounded,
                label: 'Hồ sơ',
                value: widget.controller.displayName,
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildSettingsRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildSettingsRow(
                icon: Icons.security_rounded,
                label: 'Phương thức',
                value: authMethod,
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fingerprint_rounded,
                      size: 20,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    const Expanded(
                      child: Text(
                        'Mã tài khoản',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    Text(
                      uid.length > 12 ? '\${uid.substring(0, 12)}...' : uid,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép mã tài khoản'),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space24),

        // 2. Báo cáo chi phí
        _buildSectionTitle('Báo cáo chi phí', 'PDF'),
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Xuất báo cáo PDF chi phí và theo dõi tiến độ tải lên.',
          style: AppTypography.bodySmall.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.space12),
        TsButton(
          label: 'Xuất báo cáo PDF',
          icon: Icons.picture_as_pdf_rounded,
          onPressed: _handleExportReport,
        ),

        const SizedBox(height: AppSpacing.space24),

        // 3. Tùy chỉnh trải nghiệm
        _buildSectionTitle('Tùy chỉnh trải nghiệm', 'Thiết lập'),
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Một số thiết lập có thể được cập nhật mà không cần phát hành lại ứng dụng:',
          style: AppTypography.bodySmall.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.space8),
        TsCard(
          padding: const EdgeInsets.all(AppSpacing.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfigParamRow(
                'promo_banner_enabled',
                '\${_firebase.isPromoBannerEnabled}',
              ),
              const Divider(height: 12, color: AppColors.border),
              _buildConfigParamRow(
                'promo_banner_text',
                _firebase.promoBannerText,
              ),
              const Divider(height: 12, color: AppColors.border),
              _buildConfigParamRow(
                'max_history_items',
                '\${_firebase.maxHistoryItems}',
              ),
              const Divider(height: 12, color: AppColors.border),
              _buildConfigParamRow(
                'enable_pdf_export',
                '\${_firebase.isPdfExportEnabled}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        TsButton(
          label: 'Cập nhật thiết lập',
          icon: Icons.sync_rounded,
          variant: TsButtonVariant.secondary,
          onPressed: _handleRefreshRemoteConfig,
        ),

        const SizedBox(height: AppSpacing.space24),

        // 4. Thông báo
        _buildSectionTitle('Thông báo', 'Đẩy'),
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Nhận thông báo trên thiết bị và xem lại trong trung tâm thông báo.',
          style: AppTypography.bodySmall.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.space12),
        TsButton(
          label: 'Mở trung tâm thông báo',
          icon: Icons.notifications_active_rounded,
          variant: TsButtonVariant.secondary,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
            );
          },
        ),

        if (kDebugMode && !kIsWeb) ...[
          const SizedBox(height: AppSpacing.space24),

          _buildSectionTitle('Chẩn đoán ứng dụng', 'Chỉ bản debug'),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Dùng để kiểm tra báo cáo lỗi trên thiết bị thử nghiệm.',
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.space12),
          Row(
            children: [
              Expanded(
                child: TsButton(
                  label: 'Gửi lỗi non-fatal',
                  icon: Icons.bug_report_rounded,
                  variant: TsButtonVariant.secondary,
                  onPressed: _handleCrashlyticsNonFatal,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: TsButton(
                  label: 'Kiểm tra crash',
                  icon: Icons.error_outline_rounded,
                  variant: TsButtonVariant.danger,
                  onPressed: _handleCrashlyticsFatal,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.space32),

        // 5. Đăng xuất
        TsButton(
          label: 'Đăng xuất tài khoản',
          variant: TsButtonVariant.danger,
          icon: Icons.logout_rounded,
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildConfigParamRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$key: ',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.navy,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Các xử lý dịch vụ ────────────────────────────────────────────────────
  Future<void> _handleRefreshRemoteConfig() async {
    final updated = await _firebase.refreshRemoteConfig();
    if (!mounted) return;
    _historyController.setMaxVisibleRecords(_firebase.maxHistoryItems);
    await _historyController.loadRecords(refresh: true);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated ? 'Đã cập nhật thiết lập.' : 'Thiết lập hiện đã mới nhất.',
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  Future<void> _handleCrashlyticsNonFatal() async {
    await _firebase.setCrashlyticsCustomKey('screen', 'settings_diagnostics');
    await _firebase.recordError(
      Exception('Manual Crashlytics non-fatal test'),
      StackTrace.current,
      reason: 'Manual debug test',
      fatal: false,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi báo cáo lỗi non-fatal.'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  Future<void> _handleCrashlyticsFatal() async {
    final confirmed = await TsDialog.show(
      context,
      title: 'Kiểm tra crash ứng dụng?',
      message:
          'Ứng dụng sẽ dừng ngay lập tức. Hãy mở lại ứng dụng sau đó để gửi báo cáo lên Crashlytics.',
      confirmLabel: 'Kiểm tra ngay',
    );
    if (!confirmed) return;
    _firebase.triggerTestCrash();
  }

  Future<void> _handleExportReport() async {
    if (!_firebase.isPdfExportEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tính năng xuất báo cáo đang tạm tắt.')),
      );
      return;
    }

    final user = widget.controller.user;
    final email = user?.email ?? 'user@tokenscope.io';
    final name = widget.controller.displayName;

    double uploadProgress = 0.0;
    String uploadStatus = 'Đang khởi tạo tệp PDF báo cáo...';
    String? finalUrl;
    String? uploadError;
    bool isCompleted = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (uploadProgress == 0.0 && !isCompleted && uploadError == null) {
              Future.microtask(() async {
                try {
                  final summary = _summary;
                  final totalTokens = summary?.totalTokens ?? 0;
                  final totalCost = summary?.totalCost ?? 0.0;
                  final requestCount = summary?.requestCount ?? 0;

                  final providerList = (summary?.byProvider ?? []).map((p) {
                    return {
                      'name': p.provider,
                      'model': p.providerType,
                      'tokens': p.totalTokens,
                      'cost': p.totalCost,
                    };
                  }).toList();

                  final pdfBytes = await _firebase.generatePdfReport(
                    userName: name,
                    userEmail: email,
                    totalTokens: totalTokens,
                    totalCost: totalCost,
                    requestCount: requestCount,
                    providers: providerList,
                  );

                  setDialogState(() {
                    uploadStatus = 'Đang tải báo cáo lên máy chủ...';
                  });

                  final result = await _firebase.uploadReportPdf(
                    pdfBytes: pdfBytes,
                    onProgress: (progress) {
                      setDialogState(() {
                        uploadProgress = progress;
                        uploadStatus =
                            'Tiến độ tải lên: ${(progress * 100).toStringAsFixed(0)}%';
                      });
                    },
                  );

                  if (result.isSuccess) {
                    await _firebase.logExportReport(
                      format: 'pdf',
                      fileSizeBytes: result.fileSizeBytes,
                    );
                    setDialogState(() {
                      isCompleted = true;
                      finalUrl = result.downloadUrl;
                      uploadStatus = 'Tải lên hoàn tất thành công!';
                    });
                  } else {
                    await _firebase.recordError(
                      Exception(result.errorMessage),
                      StackTrace.current,
                      reason: 'Lỗi tải tệp lên Firebase Cloud Storage',
                    );
                    setDialogState(() {
                      uploadError = result.errorMessage;
                      uploadStatus = 'Tải lên thất bại';
                    });
                  }
                } catch (e, stack) {
                  await _firebase.recordError(
                    e,
                    stack,
                    reason: 'Lỗi ngoại lệ sinh/tải báo cáo PDF',
                  );
                  setDialogState(() {
                    uploadError = e.toString();
                    uploadStatus = 'Đã xảy ra lỗi';
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Xuất báo cáo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(uploadStatus, style: AppTypography.bodySmall),
                  const SizedBox(height: 12),
                  if (uploadError == null && !isCompleted)
                    LinearProgressIndicator(
                      value: uploadProgress > 0 ? uploadProgress : null,
                      color: AppColors.primary,
                      backgroundColor: AppColors.softPurple,
                    ),
                  if (isCompleted && finalUrl != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.emerald.withAlpha(60),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đã lưu báo cáo thành công:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emerald,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            finalUrl!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (uploadError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.error.withAlpha(60),
                        ),
                      ),
                      child: Text(
                        uploadError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (isCompleted && finalUrl != null)
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: finalUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép link tải tệp PDF.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Sao chép link'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    isCompleted || uploadError != null ? 'Đóng' : 'Ẩn',
                  ),
                ),
              ],
            );
          },
        );
      },
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
          Text(trailing, style: AppTypography.bodySmall.copyWith(fontSize: 13)),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title — $message')));
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
