import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ts_logo.dart';

/// Một mục phân bổ trong thẻ tóm tắt — dự án chiếm tỷ trọng token.
class ProjectBreakdown {
  const ProjectBreakdown({
    required this.name,
    required this.percent,
    required this.color,
  });

  final String name;
  final double percent;
  final Color color;
}

/// Mô hình AI được dùng trong một dự án.
class ProjectModel {
  const ProjectModel({
    required this.provider,
    required this.model,
    required this.color,
  });

  final String provider;
  final String model;
  final Color color;
}

/// Trạng thái hoạt động của dự án.
enum ProjectStatus {
  running('Đang chạy', AppColors.success, AppColors.successLight),
  testing('Thử nghiệm', AppColors.warning, AppColors.warningLight),
  paused('Tạm dừng', AppColors.secondaryText, AppColors.background);

  const ProjectStatus(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;
}

/// Một dự án sử dụng token.
class Project {
  const Project({
    required this.name,
    required this.description,
    required this.status,
    required this.environment,
    required this.period,
    required this.tokens,
    required this.spent,
    required this.limit,
    required this.spendPercent,
    required this.budgetPercent,
    required this.systemSharePercent,
    required this.models,
    required this.color,
    this.projectCount = 0,
  });

  final String name;
  final String description;
  final ProjectStatus status;

  /// Môi trường triển khai — Production / Staging / Internal.
  final String environment;

  /// Kỳ tính toán — `Tháng 10/2025`.
  final String period;

  final int tokens;
  final double spent;
  final double limit;

  /// Phần trăm mức tiêu đã dùng.
  final double spendPercent;

  /// Phần trăm bao ngân sách đã dùng.
  final double budgetPercent;

  /// Phần trăm chiếm trong tổng hệ thống.
  final double systemSharePercent;

  /// Danh sách mô hình AI dùng trong dự án.
  final List<ProjectModel> models;

  final Color color;

  /// Tổng số dự án đang chạy trong hệ thống.
  final int projectCount;

  double get remaining => limit - spent;

  String get spentLabel => '\$${spent.toStringAsFixed(2)}';

  String get limitLabel => '\$${limit.toStringAsFixed(2)}';

  /// Số tiền còn lại trong hạn mức — `$3.50`.
  String get remainingLabel => '\$${remaining.toStringAsFixed(2)}';

  /// Định dạng số token theo kiểu Việt Nam — `1.350.000`.
  static String formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

// ── Đầu trang ─────────────────────────────────────────────────────────────

/// Đầu trang trang quản lý dự án — logo, tên ứng dụng, huy hiệu Live và
/// nút thông báo.
class ProjectsHeader extends StatelessWidget {
  const ProjectsHeader({
    super.key,
    this.onNotifications,
  });

  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const TsLogo(size: 32),
        const SizedBox(width: AppSpacing.space12),
        const Flexible(
          child: Text(
            'TokenScope',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 17,
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
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Thông báo',
          onPressed: onNotifications,
        ),
      ],
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
            child: Icon(icon, size: 22, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

// ── Ô tìm kiếm & bộ lọc ───────────────────────────────────────────────────

/// Ô tìm kiếm dự án.
class ProjectSearchField extends StatelessWidget {
  const ProjectSearchField({
    super.key,
    required this.hint,
    this.onChanged,
  });

  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.navy),
      cursorColor: AppColors.indigo,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodySmall.copyWith(fontSize: 13.5),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 19,
          color: AppColors.secondaryText,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: 13,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
        ),
      ),
    );
  }
}

/// Chip bộ lọc — nền chàm khi đang chọn, viền khi chưa chọn.
class ProjectFilterChip extends StatelessWidget {
  const ProjectFilterChip({
    super.key,
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
      color: isSelected ? AppColors.indigo : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.indigo : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.onPrimary : AppColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Chip lọc theo nhà cung cấp — tên nhà cung cấp kèm mũi tên xuống.
class ProjectProviderChip extends StatelessWidget {
  const ProjectProviderChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 15,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Thẻ tóm tắt ───────────────────────────────────────────────────────────

/// Thẻ tóm tắt — tổng quan tiêu thụ, chi phí, token và phân bổ dự án.
class ProjectSummaryCard extends StatelessWidget {
  const ProjectSummaryCard({
    super.key,
    required this.cost,
    required this.costLimit,
    required this.remaining,
    required this.tokens,
    required this.weekChange,
    required this.budgetBadge,
    required this.period,
    required this.projectCount,
    required this.breakdown,
  });

  /// Tổng chi phí trong kỳ — `$34.80`.
  final String cost;

  /// Hạn mức tương ứng — `$40.00`.
  final String costLimit;

  /// Số tiền còn lại — `$5.20 USD`.
  final String remaining;

  /// Tổng token đã dùng — `2.450.000`.
  final String tokens;

  /// Thay đổi so với tuần trước — `▲ 14% tuần nay`.
  final String weekChange;

  /// Huy hiệu ngưỡng ngân sách — `87% ngân sách`.
  final String budgetBadge;

  /// Kỳ tính toán — `Tháng 10/2025`.
  final String period;

  /// Số dự án đang chạy — `3 dự án đang chạy`.
  final String projectCount;

  /// Danh sách dự án chiếm tỷ trọng lớn nhất.
  final List<ProjectBreakdown> breakdown;

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
          _buildHeader(),
          const SizedBox(height: AppSpacing.space16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatPanel(
                    label: 'TỔNG CHI PHÍ',
                    value: cost,
                    suffix: '/ $costLimit',
                    note: 'Còn lại $remaining',
                    noteColor: AppColors.navy,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: _StatPanel(
                    label: 'LƯỢNG TOKEN ĐÃ DÙNG',
                    value: tokens,
                    suffix: 'token',
                    note: weekChange,
                    noteColor: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          _BreakdownBar(breakdown: breakdown),
          const SizedBox(height: AppSpacing.space8),
          _BreakdownLegend(breakdown: breakdown),
        ],
      ),
    );
  }

  // ── Đầu thẻ ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            Icons.folder_rounded,
            size: 20,
            color: AppColors.indigo,
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng quan tiêu thụ',
                style: AppTypography.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$period · $projectCount',
                style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Text(
            budgetBadge,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ô số liệu trong thẻ tóm tắt — nền xanh lam rất nhạt.
class _StatPanel extends StatelessWidget {
  const _StatPanel({
    required this.label,
    required this.value,
    required this.suffix,
    required this.note,
    required this.noteColor,
  });

  final String label;
  final String value;
  final String suffix;
  final String note;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.indigoSoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    style: AppTypography.h2.copyWith(fontSize: 21),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    suffix,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: noteColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Dải phân bổ — mỗi dự án một mảng, chiều rộng theo tỷ trọng.
class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({required this.breakdown});

  final List<ProjectBreakdown> breakdown;

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

/// Chú thích dải phân bổ.
class _BreakdownLegend extends StatelessWidget {
  const _BreakdownLegend({required this.breakdown});

  final List<ProjectBreakdown> breakdown;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space12,
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
                '${item.name} (${item.percent.toStringAsFixed(0)}%)',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ── Thẻ dự án ─────────────────────────────────────────────────────────────

/// Thẻ chi tiết một dự án.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  final Project project;
  final VoidCallback? onTap;

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
          _buildHeader(),
          const SizedBox(height: AppSpacing.space12),
          _buildModelChips(),
          const SizedBox(height: AppSpacing.space16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.space12),
          _buildMeta(),
          const SizedBox(height: AppSpacing.space8),
          _buildMetrics(),
          const SizedBox(height: AppSpacing.space16),
          _buildProgress(),
          const SizedBox(height: AppSpacing.space16),
          _buildAction(),
        ],
      ),
    );
  }

  // ── Đầu thẻ ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: project.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(
            Icons.folder_special_rounded,
            size: 17,
            color: project.color,
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: AppTypography.label.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                project.description,
                style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        _StatusBadge(status: project.status),
        const SizedBox(width: 6),
        _EnvTag(label: project.environment),
      ],
    );
  }

  // ── Chip mô hình AI ───────────────────────────────────────────────────
  Widget _buildModelChips() {
    return Wrap(
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: [
        for (final model in project.models)
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
                    color: model.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${model.provider} · ${model.model}',
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

  // ── Dòng kỳ tính toán ────────────────────────────────────────────────
  Widget _buildMeta() {
    return Text(
      '${project.period} · ${project.projectCount} dự án đang chạy',
      style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Số liệu tổng quan ────────────────────────────────────────────────
  Widget _buildMetrics() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TỔNG TOKEN',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Project.formatNumber(project.tokens),
                style: AppTypography.h3.copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${project.systemSharePercent.toStringAsFixed(0)}% tổng hệ thống',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
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
              ),
              const SizedBox(height: 2),
              Text(
                '${project.spentLabel} / ${project.limitLabel}',
                style: AppTypography.h3.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${project.budgetPercent.toStringAsFixed(0)}% mức hạn',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: project.budgetPercent >= 85
                      ? AppColors.danger
                      : AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Thanh tiêu trình: "Mức tiêu" · "Bao ngân sách" ──────────────────
  Widget _buildProgress() {
    final over = project.spendPercent >= 85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mức tiêu',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Text(
              'Bao ngân sách',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const Spacer(),
            Text(
              '${project.spendPercent.toStringAsFixed(0)}%',
              style: AppTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        _ThinProgressBar(
          percent: project.spendPercent,
          color: over ? AppColors.danger : AppColors.warning,
        ),
      ],
    );
  }

  // ── Nút xem chi tiết ─────────────────────────────────────────────────
  Widget _buildAction() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.indigo,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Xem chi tiết',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Huy hiệu trạng thái dự án.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ProjectStatus status;

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
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
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

/// Thẻ môi trường triển khai — `Production`, `Staging`, `Internal`.
class _EnvTag extends StatelessWidget {
  const _EnvTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

/// Thanh tiến trình mảnh.
class _ThinProgressBar extends StatelessWidget {
  const _ThinProgressBar({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);
    // Dùng flex thay vì FractionallySizedBox để thanh luôn lấp đầy chiều cao.
    final filled = (value * 1000).round();
    const total = 1000;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 7,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (filled > 0)
              Expanded(flex: filled, child: ColoredBox(color: color)),
            Expanded(
              flex: total - filled,
              child: const ColoredBox(color: AppColors.indigoTrack),
            ),
          ],
        ),
      ),
    );
  }
}
