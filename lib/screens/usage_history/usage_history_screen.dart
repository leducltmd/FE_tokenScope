import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/ts_motion.dart';
import '../../core/widgets/ts_loading.dart';
import '../../core/widgets/ts_logo.dart';
import '../../core/widgets/ts_states.dart';
import '../../models/usage_record.dart';
import '../../providers/usage_history_controller.dart';
import '../usage_details/usage_details_screen.dart';
import 'widgets/usage_filter_bar.dart';
import 'widgets/usage_record_card.dart';

/// Màn hình Lịch sử sử dụng AI API (Usage History Screen).
/// Tuân thủ quy chuẩn thiết kế TokenScope và hình Figma.
class UsageHistoryScreen extends StatefulWidget {
  const UsageHistoryScreen({
    super.key,
    this.controller,
    this.onNotifications,
    this.onAvatar,
    this.userName = 'Minh Anh',
    this.embedded = false,
  });

  final UsageHistoryController? controller;
  final VoidCallback? onNotifications;
  final VoidCallback? onAvatar;
  final String userName;
  final bool embedded;

  @override
  State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
  late final UsageHistoryController _controller =
      widget.controller ?? UsageHistoryController();

  @override
  void initState() {
    super.initState();
    _controller.loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final content = RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _controller.loadRecords(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space16,
              AppSpacing.screenPadding,
              AppSpacing.space32,
            ),
            children: [
              // 1. Đầu trang: Logo + "TokenScope" + nhãn "Live" + phụ đề "Lịch Sử" + chuông + avatar
              _buildHeader(),

              const SizedBox(height: AppSpacing.space16),

              // 2. Ô tìm kiếm + Bộ lọc Provider + Thống kê LIVE STREAM
              UsageFilterBar(
                searchQuery: _controller.searchQuery,
                selectedProvider: _controller.selectedProvider,
                totalCount: _controller.totalCount,
                onSearchChanged: _controller.setSearchQuery,
                onProviderSelected: _controller.setProvider,
              ),

              const SizedBox(height: AppSpacing.space16),

              // 3. Nội dung danh sách theo trạng thái (Loading, Error, Empty, List)
              _buildContentList(),
            ],
          ),
        );

        if (widget.embedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: content,
          ),
        );
      },
    );
  }

  // ── 1. Đầu trang chuẩn Figma ────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TsLogo(size: 36),
            const SizedBox(width: AppSpacing.space12),
            const Flexible(
              child: Text(
                'TokenScope',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 19,
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
            _buildBellButton(),
            const SizedBox(width: AppSpacing.space8),
            _AvatarButton(
              name: widget.userName,
              onPressed: widget.onAvatar,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            'Lịch Sử',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBellButton() {
    return Tooltip(
      message: 'Thông báo',
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: widget.onNotifications ??
              () => _showToast('Không có thông báo mới.'),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: AppColors.navy,
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 3. Danh sách nội dung ───────────────────────────────────────────
  Widget _buildContentList() {
    // Trạng thái Loading ban đầu
    if (_controller.isLoading) {
      return const Column(
        children: [
          TsSkeletonCard(height: 170),
          SizedBox(height: AppSpacing.space12),
          TsSkeletonCard(height: 170),
          SizedBox(height: AppSpacing.space12),
          TsSkeletonCard(height: 170),
        ],
      );
    }

    // Trạng thái Lỗi kết nối
    if (_controller.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space24),
        child: TsErrorState(
          title: 'Không thể tải lịch sử sử dụng',
          message: _controller.errorMessage ??
              'Đã xảy ra lỗi khi kết nối dữ liệu. Vui lòng thử lại.',
          actionLabel: 'Thử lại ngay',
          onRetry: () => _controller.retry(),
        ),
      );
    }

    // Trạng thái Trống (Empty State)
    if (_controller.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space24),
        child: TsEmptyState(
          title: 'Không tìm thấy lượt gọi nào',
          message:
              'Không tìm thấy dữ liệu phù hợp với tìm kiếm hoặc bộ lọc hiện tại. '
              'Xóa bộ lọc để xem toàn bộ lịch sử sử dụng.',
          actionLabel: 'Xóa bộ lọc',
          onAction: () => _controller.clearFilters(),
        ),
      );
    }

    // Trạng thái Danh sách thành công
    return Column(
      children: [
        for (final record in _controller.records) ...[
          UsageRecordCard(
            record: record,
            onTap: () => _navigateToDetails(record),
            onErrorDetailTap: () => _navigateToDetails(record),
          ),
          const SizedBox(height: AppSpacing.space12),
        ],

        const SizedBox(height: AppSpacing.space8),

        // Nút "Tải thêm 20 bản ghi"
        _buildLoadMoreButton(),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    final visible = _controller.visibleCount;
    final total = UsageRecord.formatNumber(_controller.totalCount);

    return Column(
      children: [
        if (_controller.hasMore)
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.large),
                onTap: _controller.isLoadingMore
                    ? null
                    : () => _controller.loadMore(),
                child: Center(
                  child: _controller.isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tải thêm 20 bản ghi',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Đã hiển thị toàn bộ $total bản ghi ghi nhận',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Hiển thị $visible / $total bản ghi ghi nhận',
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  void _navigateToDetails(UsageRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UsageDetailsScreen(record: record),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Huy hiệu "Live" chấm xanh nhấp nháy
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (TsMotion.enabled) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _animController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.liveLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _animation != null
              ? FadeTransition(
                  opacity: _animation!,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.live,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.live,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.name, this.onPressed});

  final String name;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFC7D2FE),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14111827),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
