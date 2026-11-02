import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/usage_record.dart';

/// Thanh công cụ tìm kiếm và lọc nhà cung cấp theo chuẩn giao diện Figma của TokenScope.
class UsageFilterBar extends StatefulWidget {
  const UsageFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedProvider,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onProviderSelected,
  });

  final String searchQuery;
  final String selectedProvider;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProviderSelected;

  @override
  State<UsageFilterBar> createState() => _UsageFilterBarState();
}

class _UsageFilterBarState extends State<UsageFilterBar> {
  late final TextEditingController _searchController =
      TextEditingController(text: widget.searchQuery);

  @override
  void didUpdateWidget(covariant UsageFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ô tìm kiếm
        _buildSearchBar(),

        const SizedBox(height: AppSpacing.space12),

        // 2. Hàng bộ lọc theo nhà cung cấp (Horizontal Chips)
        _buildProviderChips(),

        const SizedBox(height: AppSpacing.space16),

        // 3. Thanh thống kê số lượt gọi tìm thấy + nhãn LIVE STREAM
        _buildStatsBar(),
      ],
    );
  }

  // ── 1. Ô Tìm kiếm ───────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              style: AppTypography.bodySmall.copyWith(color: AppColors.navy),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo prompt ID, model, dự án...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                widget.onSearchChanged('');
              },
              child: const Icon(
                Icons.cancel_rounded,
                size: 18,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }

  // ── 2. Các chip lọc nhà cung cấp ────────────────────────────────────
  Widget _buildProviderChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Chip "Tất cả nhà cung cấp"
          _buildChip(
            id: 'all',
            label: 'Tất cả nhà cung cấp',
            leading: Icon(
              widget.selectedProvider == 'all'
                  ? Icons.check_circle_rounded
                  : Icons.grid_view_rounded,
              size: 15,
              color: widget.selectedProvider == 'all'
                  ? Colors.white
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.space8),

          // Chip "OpenAI"
          _buildChip(
            id: 'OpenAI',
            label: 'OpenAI',
            dotColor: AppColors.emerald,
          ),
          const SizedBox(width: AppSpacing.space8),

          // Chip "Gemini"
          _buildChip(
            id: 'Gemini',
            label: 'Gemini',
            dotColor: AppColors.azure,
          ),
          const SizedBox(width: AppSpacing.space8),

          // Chip "Anthropic"
          _buildChip(
            id: 'Anthropic',
            label: 'Anthropic',
            dotColor: AppColors.tangerine,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String id,
    required String label,
    Widget? leading,
    Color? dotColor,
  }) {
    final isSelected = widget.selectedProvider == id;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => widget.onProviderSelected(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x336366F1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 6),
              ] else if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3. Thanh Thống kê & LIVE STREAM ─────────────────────────────────
  Widget _buildStatsBar() {
    final formattedTotal = UsageRecord.formatNumber(widget.totalCount);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Tìm thấy ',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
                TextSpan(
                  text: formattedTotal,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const TextSpan(
                  text: ' lượt gọi API hôm nay',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'LIVE STREAM',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF0284C7),
            ),
          ),
        ),
      ],
    );
  }
}
