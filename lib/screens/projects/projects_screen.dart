import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_bottom_navigation.dart';
import 'widgets/project_widgets.dart';

/// Màn hình "Quản lý dự án".
///
/// Bố cục: Đầu trang → Tìm kiếm → Bộ lọc → Thẻ tóm tắt → Danh sách dự án →
/// Thanh điều hướng dưới.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, this.onBack});

  /// Quay lại màn hình trước.
  final VoidCallback? onBack;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _query = '';
  int _filterIndex = 0;

  static const _filters = ['Tất cả', 'Gần chạm trần (85%+)'];
  static const _navItems = [
    TsNavItem(label: 'Tổng quan', icon: Icons.dashboard_rounded),
    TsNavItem(label: 'Lịch sử', icon: Icons.history_rounded),
    TsNavItem(label: 'Ngân sách', icon: Icons.account_balance_wallet_rounded),
    TsNavItem(label: 'Cài đặt', icon: Icons.settings_rounded),
  ];

  // ── Dữ liệu mẫu theo đặc tả ──────────────────────────────────────────
  static const _breakdown = [
    ProjectBreakdown(name: 'Chatbot', percent: 55, color: AppColors.indigo),
    ProjectBreakdown(name: 'Content', percent: 20, color: AppColors.aqua),
    ProjectBreakdown(name: 'Dev Assistant', percent: 16, color: AppColors.grape),
  ];

  static const _projects = [
    Project(
      name: 'Chatbot Support',
      description: 'Hỗ trợ khách hàng tự động 24/7',
      status: ProjectStatus.running,
      environment: 'Production',
      period: 'Tháng 10/2025',
      tokens: 1350000,
      spent: 21.50,
      limit: 25.00,
      spendPercent: 86,
      budgetPercent: 86,
      systemSharePercent: 55,
      color: AppColors.indigo,
      models: [
        ProjectModel(provider: 'OpenAI', model: 'gpt-4o', color: AppColors.emerald),
        ProjectModel(
          provider: 'Anthropic',
          model: 'Claude 3.5 Sonnet',
          color: AppColors.violet,
        ),
      ],
    ),
    Project(
      name: 'Content Generator',
      description: 'Tạo bài viết SEO & mạng xã hội',
      status: ProjectStatus.testing,
      environment: 'Staging',
      period: 'Tháng 10/2025',
      tokens: 720000,
      spent: 8.90,
      limit: 10.00,
      spendPercent: 89,
      budgetPercent: 89,
      systemSharePercent: 28,
      color: AppColors.aqua,
      models: [
        ProjectModel(
          provider: 'Google',
          model: 'Gemini 1.5 Pro',
          color: AppColors.azure,
        ),
        ProjectModel(
          provider: 'OpenAI',
          model: 'gpt-4o-mini',
          color: AppColors.emerald,
        ),
      ],
    ),
    Project(
      name: 'Developer Assistant',
      description: 'Giải thích code & phân tích lỗi',
      status: ProjectStatus.running,
      environment: 'Internal',
      period: 'Tháng 10/2025',
      tokens: 380000,
      spent: 4.40,
      limit: 12.00,
      spendPercent: 37,
      budgetPercent: 37,
      systemSharePercent: 16,
      color: AppColors.grape,
      models: [
        ProjectModel(
          provider: 'Anthropic',
          model: 'Claude 3.5 Sonnet',
          color: AppColors.violet,
        ),
        ProjectModel(
          provider: 'Google',
          model: 'Gemini 1.5 Flash',
          color: AppColors.azure,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _visibleProjects();

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
                  AppSpacing.space16,
                  AppSpacing.screenPadding,
                  AppSpacing.space32,
                ),
                children: [
                  ProjectsHeader(
                    onNotifications: widget.onBack,
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  _buildTitleRow(),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'Giám sát mức tiêu thụ token & chi phí LLM',
                    style: AppTypography.bodySmall.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  ProjectSearchField(
                    hint: 'Tìm kiếm dự án...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _buildFilters(),
                  const SizedBox(height: AppSpacing.space16),
                  _buildSummary(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildListHeader(),
                  const SizedBox(height: AppSpacing.space12),
                  if (visible.isEmpty)
                    _buildEmptyState()
                  else
                    for (final project in visible) ...[
                      ProjectCard(project: project),
                      const SizedBox(height: AppSpacing.space12),
                    ],
                ],
              ),
            ),
            TsBottomNavigation(
              items: _navItems,
              currentIndex: 1,
              onChanged: _onNavChanged,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tiêu đề + nút tạo mới ────────────────────────────────────────────
  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Quản lý dự án',
            style: AppTypography.h2.copyWith(fontSize: 23),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Material(
          color: AppColors.indigo,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: InkWell(
            onTap: _noop,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tạo mới',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bộ lọc ───────────────────────────────────────────────────────────
  Widget _buildFilters() {
    return Row(
      children: [
        for (var i = 0; i < _filters.length; i++) ...[
          ProjectFilterChip(
            label: _filters[i],
            isSelected: i == _filterIndex,
            onTap: () => setState(() => _filterIndex = i),
          ),
          if (i != _filters.length - 1)
            const SizedBox(width: AppSpacing.space12),
        ],
        const Spacer(),
        const ProjectProviderChip(label: 'OpenAI', onTap: _noop),
      ],
    );
  }

  // ── Thẻ tóm tắt ───────────────────────────────────────────────────────
  Widget _buildSummary() {
    return ProjectSummaryCard(
      cost: '\$34.80',
      costLimit: '\$40.00',
      remaining: '\$5.20 USD',
      tokens: '2.450.000',
      weekChange: '▲ 14% tuần nay',
      budgetBadge: '87%\nngân sách',
      period: 'Tháng 10/2025',
      projectCount: '3 dự án đang chạy',
      breakdown: _breakdown,
    );
  }

  // ── Tiêu đề danh sách ─────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Row(
      children: [
        Text(
          'Danh sách dự án',
          style: AppTypography.label.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.indigoSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${_projects.length}',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  // ── Trạng thái rỗng ───────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space32,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_off_outlined,
            size: 32,
            color: AppColors.disabled,
          ),
          const SizedBox(height: AppSpacing.space12),
          Text('Không tìm thấy dự án', style: AppTypography.label),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Thử đổi từ khoá tìm kiếm hoặc chọn bộ lọc khác.',
            style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Lọc danh sách ─────────────────────────────────────────────────────
  List<Project> _visibleProjects() {
    final query = _query.trim().toLowerCase();

    return _projects.where((project) {
      // Lọc theo từ khoá.
      if (query.isNotEmpty) {
        final haystack =
            '${project.name} ${project.description}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      // Lọc theo chip.
      switch (_filterIndex) {
        case 1:
          return project.budgetPercent >= 85;
        default:
          return true;
      }
    }).toList();
  }

  /// Điều hướng dưới — chọn mục khác sẽ quay lại bảng điều khiển tổng quan.
  void _onNavChanged(int index) {
    if (index == 1) return;
    Navigator.of(context).maybePop();
  }

  /// Chip nhà cung cấp chưa có hành động.
  static void _noop() {}
}
