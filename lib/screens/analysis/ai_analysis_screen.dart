import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'widgets/analysis_charts.dart';

/// Màn hình "Phân tích sử dụng AI".
///
/// Bố cục: Thanh ứng dụng → Tiêu đề trực tiếp → Bộ lọc khoảng thời gian →
/// Biểu đồ xu hướng tuần → Tỷ lệ theo nhà cung cấp → Cấu trúc đầu vào/đầu ra
/// → Danh sách mô hình AI sử dụng nhiều nhất → Nút hành động nổi.
class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  String _range = '7 ngày';

  static const _ranges = ['Hôm nay', '7 ngày', 'Tháng này'];

  // ── Dữ liệu mẫu theo đặc tả ──────────────────────────────────────────
  static const _weekValues = <double>[
    180000,
    240000,
    205000,
    450000,
    320000,
    285000,
    290000,
  ];

  static const _weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  static const _providers = <TsDonutSlice>[
    TsDonutSlice(label: 'OpenAI', value: 19.20, color: Color(0xFF4F46E5)),
    TsDonutSlice(label: 'Anthropic', value: 8.20, color: Color(0xFF8B5CF6)),
    TsDonutSlice(label: 'Google Gemini', value: 7.40, color: Color(0xFF38BDF8)),
  ];

  static const _models = <_ModelUsage>[
    _ModelUsage(
      name: 'gpt-4o',
      cost: '\$12.60',
      provider: 'OpenAI',
      tokens: '1.300.000 tokens',
      ratio: 1.0,
      color: Color(0xFF4F46E5),
    ),
    _ModelUsage(
      name: 'gemini-1.5-pro',
      cost: '\$6.10',
      provider: 'Google',
      tokens: '850.000 tokens',
      ratio: 0.65,
      color: Color(0xFF0EA5E9),
    ),
    _ModelUsage(
      name: 'claude-3-5-sonnet',
      cost: '\$8.20',
      provider: 'Anthropic',
      tokens: '450.000 tokens',
      ratio: 0.35,
      color: Color(0xFF8B5CF6),
    ),
    _ModelUsage(
      name: 'gemini-1.5-flash',
      cost: '\$1.90',
      provider: 'Google',
      tokens: '150.000 tokens',
      ratio: 0.12,
      color: Color(0xFF38BDF8),
    ),
    _ModelUsage(
      name: 'gpt-4o-mini',
      cost: '\$1.60',
      provider: 'OpenAI',
      tokens: '100.000 tokens',
      ratio: 0.08,
      color: Color(0xFF818CF8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space8,
                  AppSpacing.screenPadding,
                  96,
                ),
                children: [
                  _buildLiveHeader(),
                  const SizedBox(height: AppSpacing.space16),
                  _buildRangeFilter(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildWeeklyTrend(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildProviderSection(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildInputOutputSection(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildModelsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Thanh ứng dụng ────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space8,
        AppSpacing.space8,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            color: AppColors.navy,
            tooltip: 'Quay lại',
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
          const SizedBox(width: AppSpacing.space4),
          const Expanded(
            child: Text(
              'Phân tích sử dụng',
              style: AppTypography.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _toast('Đã làm mới dữ liệu phân tích.'),
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: AppColors.navy,
            tooltip: 'Làm mới',
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
          IconButton(
            onPressed: () => _toast('Đang xuất báo cáo phân tích...'),
            icon: const Icon(Icons.ios_share_rounded, size: 21),
            color: AppColors.navy,
            tooltip: 'Xuất báo cáo',
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
        ],
      ),
    );
  }

  // ── Tiêu đề trực tiếp ─────────────────────────────────────────────────
  Widget _buildLiveHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Phân tích sử dụng AI',
                style: AppTypography.h1.copyWith(fontSize: 26),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            _LiveBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Giám sát tải lượng & hạn mức thời gian thực',
          style: AppTypography.bodySmall.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  // ── Bộ lọc khoảng thời gian ──────────────────────────────────────────
  Widget _buildRangeFilter() {
    return Row(
      children: [
        for (final range in _ranges) ...[
          Expanded(
            child: _RangeChip(
              label: range,
              isSelected: range == _range,
              onTap: () => setState(() => _range = range),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
        ],
        Expanded(
          child: _CustomRangeChip(
            onTap: () => _toast('Chọn khoảng thời gian tùy chỉnh.'),
          ),
        ),
      ],
    );
  }

  // ── 1 · Xu hướng tuần này ────────────────────────────────────────────
  Widget _buildWeeklyTrend() {
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(label: 'XU HƯỚNG TUẦN NÀY'),
          const SizedBox(height: AppSpacing.space16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '1.970.000',
                    style: AppTypography.h1.copyWith(fontSize: 30),
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Trung bình / ngày: 281.429',
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: AppColors.softPurple,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: Text(
                    'Đỉnh điểm: Thứ Năm · 450.000 tokens - \$6.40',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          TsAnalysisWeekChart(
            values: _weekValues,
            labels: _weekLabels,
            highlightIndex: 3,
          ),
        ],
      ),
    );
  }

  // ── 2 · Tỷ lệ theo nhà cung cấp ──────────────────────────────────────
  Widget _buildProviderSection() {
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(label: 'TỶ LỆ THEO NHÀ CUNG CẤP'),
          const SizedBox(height: AppSpacing.space16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TsDonutChart(
                slices: _providers,
                totalLabel: '\$34.80',
                size: 118,
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < _providers.length; i++) ...[
                      _ProviderLegend(
                        slice: _providers[i],
                        total: 34.80,
                      ),
                      if (i != _providers.length - 1)
                        const SizedBox(height: AppSpacing.space12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3 · Cấu trúc đầu vào / đầu ra ─────────────────────────────────────
  Widget _buildInputOutputSection() {
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTag(label: 'CẤU TRÚC ĐẦU VÀO / ĐẦU RA'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Tỷ lệ 2.77:1',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          _InputOutputBar(inputPercent: 0.735, outputPercent: 0.265),
          const SizedBox(height: AppSpacing.space16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'ĐẦU VÀO (INPUT)',
                  value: '1.800.000',
                  caption: 'Tokens hệ thống',
                  color: AppColors.navy,
                  dotColor: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: _MetricColumn(
                  label: 'ĐẦU RA (OUTPUT)',
                  value: '650.000',
                  caption: 'Tokens câu trả lời',
                  color: const Color(0xFF38BDF8),
                  dotColor: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4 · Mô hình AI sử dụng nhiều nhất ─────────────────────────────────
  Widget _buildModelsSection() {
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTag(label: 'MÔ HÌNH AI SỬ DỤNG NHIỀU NHẤT'),
          const SizedBox(height: 4),
          Text(
            'Sắp xếp theo khối lượng tiêu thụ token',
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.space16),
          for (var i = 0; i < _models.length; i++) ...[
            _ModelRow(model: _models[i], rank: i + 1),
            if (i != _models.length - 1)
              const SizedBox(height: AppSpacing.space16),
          ],
        ],
      ),
    );
  }

  // ── Nút hành động nổi ─────────────────────────────────────────────────
  Widget _buildFab() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _toast('Trợ lý phân tích AI đang mở...'),
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
        tooltip: 'Trợ lý phân tích',
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Thẻ bao nội dung — nền trắng, viền nhạt, bo góc 16 px.
class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

/// Nhãn nhóm nhỏ — nền tím nhạt, chữ tím đậm, bo góc 6 px.
class _SectionTag extends StatelessWidget {
  const _SectionTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softPurple,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

/// Huy hiệu "TRỰC TIẾP" — nền xanh nhạt kèm chấm sáng.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.liveLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.live.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.live,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'TRỰC TIẾP',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.live,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip khoảng thời gian — bo tròn, viền khi chưa chọn, nền tím khi đang chọn.
class _RangeChip extends StatelessWidget {
  const _RangeChip({
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
                  vertical: 8,
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

/// Chip "Tùy chỉnh" — mở hộp thoại chọn ngày.
class _CustomRangeChip extends StatelessWidget {
  const _CustomRangeChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Tùy chỉnh',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
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

/// Một dòng chú giải nhà cung cấp.
class _ProviderLegend extends StatelessWidget {
  const _ProviderLegend({required this.slice, required this.total});

  final TsDonutSlice slice;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0.0 : slice.value / total * 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slice.label,
                style: AppTypography.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                '\$${slice.value.toStringAsFixed(2)} '
                '(${percent.toStringAsFixed(1)}%)',
                style: AppTypography.bodySmall.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Thanh phân rã đầu vào / đầu ra.
class _InputOutputBar extends StatelessWidget {
  const _InputOutputBar({
    required this.inputPercent,
    required this.outputPercent,
  });

  final double inputPercent;
  final double outputPercent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
              flex: (inputPercent * 100).round().clamp(1, 100),
              child: Container(color: const Color(0xFF1E1B4B)),
            ),
            const SizedBox(width: 3),
            Expanded(
              flex: (outputPercent * 100).round().clamp(1, 100),
              child: Container(color: const Color(0xFF38BDF8)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cột chỉ số đầu vào hoặc đầu ra.
class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.dotColor,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.h3.copyWith(fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Mô hình AI và mức tiêu thụ token.
class _ModelUsage {
  const _ModelUsage({
    required this.name,
    required this.cost,
    required this.provider,
    required this.tokens,
    required this.ratio,
    required this.color,
  });

  final String name;
  final String cost;
  final String provider;
  final String tokens;
  final double ratio;
  final Color color;
}

/// Một dòng mô hình trong danh sách xếp hạng.
class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.model, required this.rank});

  final _ModelUsage model;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '$rank',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Text(
                model.name,
                style: AppTypography.label.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Text(
              model.cost,
              style: AppTypography.label.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                '${model.provider} · ${model.tokens}',
                style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            SizedBox(
              width: 110,
              child: TsAnalysisProgressBar(
                value: model.ratio,
                color: model.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
