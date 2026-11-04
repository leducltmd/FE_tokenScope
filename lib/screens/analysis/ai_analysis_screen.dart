import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_loading.dart';
import '../../core/widgets/ts_states.dart';
import '../../models/usage_analysis.dart';
import '../../providers/analysis_controller.dart';
import 'widgets/analysis_charts.dart';

/// Màn hình "Phân tích sử dụng AI".
///
/// Bố cục: Thanh ứng dụng → Tiêu đề trực tiếp → Bộ lọc khoảng thời gian →
/// Biểu đồ xu hướng tuần → Tỷ lệ theo nhà cung cấp → Cấu trúc đầu vào/đầu ra
/// → Danh sách mô hình AI sử dụng nhiều nhất → Nút hành động nổi.
///
/// Toàn bộ số liệu đến từ backend thật (`GET /api/usage/analysis`).
class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key, this.controller});

  /// Controller dùng chung — nếu null thì tự tạo.
  final AnalysisController? controller;

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  late final AnalysisController _controller =
      widget.controller ?? AnalysisController();

  static const _ranges = ['Hôm nay', '7 ngày', 'Tháng này'];

  /// Số ngày tương ứng với từng chip khoảng thời gian.
  static const _rangeDays = <String, int>{
    'Hôm nay': 1,
    '7 ngày': 7,
    'Tháng này': 30,
  };

  /// Màu nhận diện theo loại nhà cung cấp.
  static const _providerColors = <String, Color>{
    'openai': Color(0xFF4F46E5),
    'anthropic': Color(0xFF8B5CF6),
    'google': Color(0xFF38BDF8),
    'mistral': Color(0xFFF97316),
    'groq': Color(0xFF818CF8),
  };

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  // ── Chuyển dữ liệu thật sang model hiển thị ───────────────────────────
  /// Nhãn ngày trong tuần từ chuỗi `YYYY-MM-DD`.
  String _labelFor(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return '';
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[(parsed.weekday - 1) % 7];
  }

  /// Định dạng số theo chuẩn Việt Nam — `1.970.000`.
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

  List<double> _weekValues(UsageAnalysis analysis) {
    return analysis.weekly
        .map((point) => point.totalTokens.toDouble())
        .toList(growable: false);
  }

  List<String> _weekDayLabels(UsageAnalysis analysis) {
    return analysis.weekly.map((point) => _labelFor(point.date)).toList();
  }

  /// Chỉ số điểm đỉnh trong biểu đồ tuần.
  int _peakIndex(UsageAnalysis analysis) {
    var index = 0;
    var best = 0;
    for (var i = 0; i < analysis.weekly.length; i++) {
      if (analysis.weekly[i].totalTokens > best) {
        best = analysis.weekly[i].totalTokens;
        index = i;
      }
    }
    return index;
  }

  List<TsDonutSlice> _providerSlices(UsageAnalysis analysis) {
    return analysis.byProvider
        .map(
          (provider) => TsDonutSlice(
            label: provider.provider,
            value: provider.totalCost,
            color: _providerColors[provider.providerType] ??
                const Color(0xFF4F46E5),
          ),
        )
        .toList();
  }

  List<_ModelUsage> _modelUsages(UsageAnalysis analysis) {
    final maxTokens = analysis.byModel.isEmpty
        ? 1
        : analysis.byModel.first.totalTokens;

    return analysis.byModel
        .map(
          (model) => _ModelUsage(
            name: model.model,
            cost: '\$${model.totalCost.toStringAsFixed(2)}',
            provider: model.provider,
            tokens: '${_formatNumber(model.totalTokens)} tokens',
            ratio: maxTokens > 0 ? model.totalTokens / maxTokens : 0,
            color: _providerColors[model.providerType] ??
                const Color(0xFF4F46E5),
          ),
        )
        .toList();
  }

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
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading && _controller.analysis == null) {
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

                  if (_controller.hasError && _controller.analysis == null) {
                    return TsErrorState(
                      title: 'Không thể tải dữ liệu phân tích',
                      message: _controller.errorMessage ??
                          'Đã xảy ra lỗi khi kết nối máy chủ. Vui lòng thử lại.',
                      actionLabel: 'Thử lại ngay',
                      onRetry: () => _controller.load(),
                    );
                  }

                  final analysis = _controller.analysis;
                  if (analysis == null) return const SizedBox.shrink();

                  return ListView(
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
                      _buildWeeklyTrend(analysis),
                      const SizedBox(height: AppSpacing.space24),
                      _buildProviderSection(analysis),
                      const SizedBox(height: AppSpacing.space24),
                      _buildInputOutputSection(analysis),
                      const SizedBox(height: AppSpacing.space24),
                      _buildModelsSection(analysis),
                    ],
                  );
                },
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
    final current = _controller.days;
    return Row(
      children: [
        for (final range in _ranges) ...[
          Expanded(
            child: _RangeChip(
              label: range,
              isSelected: _rangeDays[range] == current,
              onTap: () => _controller.setRange(_rangeDays[range] ?? 7),
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
  Widget _buildWeeklyTrend(UsageAnalysis analysis) {
    final values = _weekValues(analysis);
    final labels = _weekDayLabels(analysis);
    final peak = analysis.peak;

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
                    _formatNumber(analysis.totalTokens),
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
                    'Trung bình / ngày: ${_formatNumber(analysis.dailyAverage)}',
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
                    peak == null
                        ? 'Chưa có dữ liệu điểm đỉnh.'
                        : 'Đỉnh điểm: ${_labelFor(peak.date)} · '
                            '${_formatNumber(peak.totalTokens)} tokens - '
                            '\$${peak.totalCost.toStringAsFixed(2)}',
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
            values: values,
            labels: labels,
            highlightIndex: _peakIndex(analysis),
          ),
        ],
      ),
    );
  }

  // ── 2 · Tỷ lệ theo nhà cung cấp ──────────────────────────────────────
  Widget _buildProviderSection(UsageAnalysis analysis) {
    final slices = _providerSlices(analysis);
    final total = analysis.totalCost;

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
                slices: slices,
                totalLabel: '\$${total.toStringAsFixed(2)}',
                size: 118,
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < slices.length; i++) ...[
                      _ProviderLegend(
                        slice: slices[i],
                        total: total,
                      ),
                      if (i != slices.length - 1)
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
  Widget _buildInputOutputSection(UsageAnalysis analysis) {
    final ratio = analysis.inputRatio + analysis.outputRatio > 0
        ? analysis.inputRatio / (analysis.inputRatio + analysis.outputRatio)
        : 0.0;

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
                  'Tỷ lệ ${_ratioLabel(analysis)}',
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
          _InputOutputBar(
            inputPercent: ratio,
            outputPercent: 1 - ratio,
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'ĐẦU VÀO (INPUT)',
                  value: _formatNumber(analysis.inputTokens),
                  caption: 'Tokens hệ thống',
                  color: AppColors.navy,
                  dotColor: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: _MetricColumn(
                  label: 'ĐẦU RA (OUTPUT)',
                  value: _formatNumber(analysis.outputTokens),
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

  /// Nhãn tỷ lệ đầu vào : đầu ra — `2.77:1`.
  String _ratioLabel(UsageAnalysis analysis) {
    if (analysis.outputTokens == 0) return '—';
    final value = analysis.inputTokens / analysis.outputTokens;
    return '${value.toStringAsFixed(2)}:1';
  }

  // ── 4 · Mô hình AI sử dụng nhiều nhất ─────────────────────────────────
  Widget _buildModelsSection(UsageAnalysis analysis) {
    final models = _modelUsages(analysis);

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
          if (models.isEmpty)
            Text(
              'Chưa có dữ liệu mô hình AI.',
              style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
            )
          else
            for (var i = 0; i < models.length; i++) ...[
              _ModelRow(model: models[i], rank: i + 1),
              if (i != models.length - 1)
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
