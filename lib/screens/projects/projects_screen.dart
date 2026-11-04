import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_bottom_navigation.dart';
import '../../core/widgets/ts_loading.dart';
import '../../core/widgets/ts_states.dart';
import '../../models/project_connection.dart';
import '../../providers/projects_controller.dart';
import 'widgets/project_widgets.dart';

/// Màn hình "Quản lý dự án".
///
/// Bố cục: Đầu trang → Tìm kiếm → Bộ lọc → Thẻ tóm tắt → Danh sách dự án →
/// Thanh điều hướng dưới.
///
/// Toàn bộ số liệu đến từ backend thật (`GET /api/projects`).
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, this.onBack, this.controller});

  /// Quay lại màn hình trước.
  final VoidCallback? onBack;

  /// Controller dùng chung — nếu null thì tự tạo.
  final ProjectsController? controller;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late final ProjectsController _controller =
      widget.controller ?? ProjectsController();

  String _query = '';
  int _filterIndex = 0;

  static const _filters = ['Tất cả', 'Gần chạm trần (85%+)'];
  static const _navItems = [
    TsNavItem(label: 'Tổng quan', icon: Icons.dashboard_rounded),
    TsNavItem(label: 'Lịch sử', icon: Icons.history_rounded),
    TsNavItem(label: 'Ngân sách', icon: Icons.account_balance_wallet_rounded),
    TsNavItem(label: 'Cài đặt', icon: Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller.loadProjects();
  }

  // ── Chuyển dữ liệu thật sang model hiển thị ───────────────────────────
  /// Tỷ lệ chiếm hạn mức — dùng `budgetPercent` từ backend.
  double _budgetPercentOf(ProjectConnection project) {
    final limit = project.monthlyLimit;
    if (limit != null && limit > 0) {
      return ((project.totalCost / limit) * 100).clamp(0, 100).toDouble();
    }
    return project.budgetPercent.clamp(0, 100).toDouble();
  }

  Project _toCard(ProjectConnection project) {
    final spent = project.totalCost;
    final limit = project.monthlyLimit ?? 0;

    return Project(
      name: project.name,
      description: project.description ?? 'Chưa có mô tả.',
      status: _statusOf(project),
      environment: project.environment,
      period: 'Tháng ${DateTime.now().month}/${DateTime.now().year}',
      tokens: project.totalTokens,
      spent: spent,
      limit: limit,
      spendPercent: _budgetPercentOf(project),
      budgetPercent: _budgetPercentOf(project),
      systemSharePercent: project.systemSharePercent,
      color: _colorFromHex(project.color),
      projectCount: _controller.projects.length,
      models: project.models
          .take(3)
          .map(
            (m) => ProjectModel(
              provider: m.provider,
              model: m.model,
              color: _colorFromHex(project.color),
            ),
          )
          .toList(),
    );
  }

  /// Suy ra trạng thái dự án từ môi trường triển khai và mức sử dụng.
  static ProjectStatus _statusOf(ProjectConnection project) {
    switch (project.environment.toLowerCase()) {
      case 'staging':
      case 'testing':
        return ProjectStatus.testing;
      case 'internal':
      case 'development':
        return ProjectStatus.paused;
      default:
        return project.requestCount > 0
            ? ProjectStatus.running
            : ProjectStatus.paused;
    }
  }

  /// Đổi mã màu hex của backend sang [Color].
  static Color _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return AppColors.indigo;
    return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
  }

  /// Phân bổ token theo dự án cho thẻ tóm tắt.
  List<ProjectBreakdown> _buildBreakdown(List<Project> projects) {
    const palette = [
      AppColors.indigo,
      AppColors.aqua,
      AppColors.grape,
      AppColors.emerald,
      AppColors.tangerine,
    ];
    return [
      for (var i = 0; i < projects.length && i < palette.length; i++)
        ProjectBreakdown(
          name: projects[i].name,
          percent: projects[i].systemSharePercent,
          color: palette[i],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  // Tính danh sách đã lọc bên trong builder để cập nhật theo dữ liệu
                  // mới nhất từ controller.
                  final visible = _visibleProjects();
                  if (_controller.isLoading && _controller.projects.isEmpty) {
                    return const SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.screenPadding),
                        child: Column(
                          children: [
                            TsSkeletonCard(height: 140),
                            SizedBox(height: AppSpacing.space12),
                            TsSkeletonCard(height: 170),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_controller.hasError && _controller.projects.isEmpty) {
                    return TsErrorState(
                      title: 'Không thể tải dự án',
                      message: _controller.errorMessage ??
                          'Đã xảy ra lỗi khi kết nối máy chủ. Vui lòng thử lại.',
                      actionLabel: 'Thử lại ngay',
                      onRetry: () => _controller.loadProjects(),
                    );
                  }

                  return ListView(
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
                      _buildSummary(visible),
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
                  );
                },
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
  Widget _buildSummary(List<Project> projects) {
    final totalCost = _controller.totalCost;
    final totalLimit = projects.fold<double>(
      0,
      (sum, project) => sum + project.limit,
    );
    final remaining = totalLimit - totalCost;
    final percent = totalLimit > 0 ? (totalCost / totalLimit) * 100 : 0;
    final now = DateTime.now();

    return ProjectSummaryCard(
      cost: '\$${totalCost.toStringAsFixed(2)}',
      costLimit: '\$${totalLimit.toStringAsFixed(2)}',
      remaining: '\$${remaining.toStringAsFixed(2)} USD',
      tokens: Project.formatNumber(_controller.totalTokens),
      weekChange: '${_controller.requestCount} lượt gọi đã ghi nhận',
      budgetBadge: '${percent.toStringAsFixed(0)}%\nngân sách',
      period: 'Tháng ${now.month}/${now.year}',
      projectCount: '${projects.length} dự án đang chạy',
      breakdown: _buildBreakdown(projects),
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
            '${_controller.projects.length}',
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
    final cards = _controller.projects.map(_toCard).toList();

    return cards.where((project) {
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
