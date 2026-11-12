import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_bottom_navigation.dart';
import '../../core/widgets/ts_loading.dart';
import '../../core/widgets/ts_states.dart';
import '../../models/provider_connection.dart';
import '../../providers/providers_controller.dart';
import 'connect_provider_screen.dart';
import 'widgets/gemini_usage_dialog.dart';
import 'widgets/provider_keys_sheet.dart';
import 'widgets/provider_widgets.dart';

/// Màn hình "Nhà cung cấp AI".
///
/// Bố cục: Đầu trang → Thẻ tóm tắt → Danh sách nhà cung cấp → Kết nối nhà
/// cung cấp mới → Ghi chú → Thanh điều hướng dưới.
///
/// Toàn bộ số liệu đến từ backend thật (`GET /api/providers`).
class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key, this.onBack, this.controller});

  /// Quay lại màn hình trước.
  final VoidCallback? onBack;

  /// Controller dùng chung — nếu null thì tự tạo.
  final ProvidersController? controller;

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  late final ProvidersController _controller =
      widget.controller ?? ProvidersController();

  static const _navItems = [
    TsNavItem(label: 'Tổng quan', icon: Icons.dashboard_rounded),
    TsNavItem(label: 'Lịch sử', icon: Icons.history_rounded),
    TsNavItem(label: 'Ngân sách', icon: Icons.account_balance_wallet_rounded),
    TsNavItem(label: 'Cài đặt', icon: Icons.settings_rounded),
  ];

  /// Màu nhận diện theo loại nhà cung cấp.
  static const _providerColors = <String, Color>{
    'openai': AppColors.emerald,
    'anthropic': AppColors.violet,
    'google': AppColors.azure,
    'mistral': AppColors.tangerine,
    'groq': AppColors.grape,
  };

  @override
  void initState() {
    super.initState();
    _controller.loadProviders();
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
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _controller.loadProviders(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: AppSpacing.space32),
                      children: _buildContent(),
                    ),
                  );
                },
              ),
            ),
            TsBottomNavigation(
              items: _navItems,
              currentIndex: 0,
              onChanged: _onNavChanged,
            ),
          ],
        ),
      ),
    );
  }

  // ── Nội dung theo trạng thái ─────────────────────────────────────────
  List<Widget> _buildContent() {
    if (_controller.isLoading && _controller.providers.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.space24),
        const TsSkeletonCard(height: 140),
        const SizedBox(height: AppSpacing.space12),
        const TsSkeletonCard(height: 170),
      ];
    }

    if (_controller.hasError && _controller.providers.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.space24),
        TsErrorState(
          title: 'Không thể tải nhà cung cấp',
          message: _controller.errorMessage ??
              'Đã xảy ra lỗi khi kết nối máy chủ. Vui lòng thử lại.',
          actionLabel: 'Thử lại ngay',
          onRetry: () => _controller.loadProviders(),
        ),
      ];
    }

    final providers = _controller.providers;
    final cards = _toCards(providers);
    final totalTokens = _formatNumber(_controller.totalTokens);
    final totalCost = '\$${_controller.totalCost.toStringAsFixed(2)}';

    return [
      ProvidersHeader(
        providerCount: providers.length,
        totalTokens: totalTokens,
        onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProviderSummaryCard(
              totalTokens: totalTokens,
              totalCost: totalCost,
              limit: '/ \$${_controller.totalLimit.toStringAsFixed(2)}',
              breakdown: cards,
            ),
            const SizedBox(height: AppSpacing.space24),
            _buildSectionTitle(
              'Danh sách nhà cung cấp',
              providers.length,
            ),
            const SizedBox(height: AppSpacing.space12),
            if (providers.isEmpty)
              TsEmptyState(
                title: 'Chưa có nhà cung cấp nào',
                message:
                    'Kết nối API key của nhà cung cấp AI để bắt đầu theo dõi '
                    'token và chi phí.',
                actionLabel: 'Kết nối nhà cung cấp',
                onAction: _handleConnect,
              )
            else
              for (final provider in providers) ...[
                AiProviderCard(
                  provider: _toCard(provider, cards),
                  onTap: () => _showProviderActions(provider),
                ),
                const SizedBox(height: AppSpacing.space12),
              ],
            const SizedBox(height: AppSpacing.space12),
            ConnectProviderCard(onConnect: _handleConnect),
            const SizedBox(height: AppSpacing.space16),
            const ProviderNote(),
          ],
        ),
      ),
    ];
  }

  // ── Tiêu đề nhóm ──────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, int count) {
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
        Text(
          '$count đang kết nối',
          style: AppTypography.bodySmall.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  // ── Chuyển dữ liệu thật sang model hiển thị ───────────────────────────
  /// Tỷ lệ chiếm hạn mức — tính theo tỷ trọng chi phí giữa các nhà cung cấp.
  int _percentOf(ProviderConnection provider) {
    final total = _controller.totalCost;
    if (total <= 0) return 0;
    return ((provider.totalCost / total) * 100).round().clamp(0, 100);
  }

  AiProvider _toCard(ProviderConnection provider, List<AiProvider> all) {
    final models = provider.models.isEmpty
        ? 'Chưa đọc được danh sách model'
        : provider.models.take(3).join(', ');

    final status = switch (provider.lastCheckStatus) {
      'success' => ProviderStatus.connected,
      'invalidKey' => ProviderStatus.error,
      'missingScope' => ProviderStatus.pending,
      'unreachable' => ProviderStatus.error,
      _ => provider.isActive ? ProviderStatus.connected : ProviderStatus.pending,
    };

    return AiProvider(
      name: provider.name,
      models: models,
      tokens: _formatNumber(provider.totalTokens),
      cost: '\$${provider.totalCost.toStringAsFixed(2)}',
      percent: _percentOf(provider),
      letter: provider.letter,
      color: _providerColors[provider.providerType] ?? AppColors.primary,
      status: status,
      statusLabel: status.label,
    );
  }

  List<AiProvider> _toCards(List<ProviderConnection> providers) {
    final cards = providers.map((p) => _toCard(p, const [])).toList();
    return cards;
  }

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

  // ── Hành động ─────────────────────────────────────────────────────────
  /// Mở màn hình kết nối nhà cung cấp mới.
  void _handleConnect() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConnectProviderScreen(
          onConnected: (name, provider) {
            _controller.loadProviders();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã kết nối "$name" với ${provider.name}.')),
            );
          },
        ),
      ),
    );
  }

  /// Menu thao tác cho một kết nối: kiểm tra lại, đồng bộ usage, xoá.
  Future<void> _showProviderActions(ProviderConnection provider) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.name, style: AppTypography.h3),
              const SizedBox(height: 4),
              Text(
                provider.maskedApiKey ?? 'Chưa có API key',
                style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
              ),
              if (provider.maskedAdminApiKey != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Admin key: ${provider.maskedAdminApiKey}',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                ),
              ],
              const SizedBox(height: AppSpacing.space12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.wifi_tethering_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                title: Text('Kiểm tra lại kết nối', style: AppTypography.label),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _recheck(provider);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.key_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                title: Text('Cập nhật khoá', style: AppTypography.label),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _showKeysSheet(provider);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                title: Text(
                  provider.providerType == 'google'
                      ? 'Xem token Gemini'
                      : 'Đồng bộ usage & billing',
                  style: AppTypography.label,
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (provider.providerType == 'google') {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => GeminiUsageDialog(providerId: provider.id),
                    );
                    return;
                  }
                  await _sync(provider);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                title: Text(
                  'Xoá kết nối',
                  style: AppTypography.label.copyWith(color: AppColors.error),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _delete(provider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mở sheet cập nhật khoá — mỗi loại khoá được cập nhật độc lập.
  Future<void> _showKeysSheet(ProviderConnection provider) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ProviderKeysSheet(
        provider: provider,
        onSave: ({
          apiKey,
          adminApiKey,
          workspaceId,
          clearAdminApiKey = false,
        }) async {
          final updated = await _controller.updateProviderKeys(
            provider.id,
            apiKey: apiKey,
            adminApiKey: adminApiKey,
            workspaceId: workspaceId,
            clearAdminApiKey: clearAdminApiKey,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật khoá cho "${provider.name}".')),
          );
          if ((updated.providerType == 'openai' ||
                  updated.providerType == 'anthropic') &&
              updated.maskedAdminApiKey != null &&
              (adminApiKey != null || workspaceId != null)) {
            unawaited(_sync(updated));
          }
        },
      ),
    );
  }

  Future<void> _recheck(ProviderConnection provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang kiểm tra lại kết nối...')),
    );

    try {
      final result = await _controller.recheck(provider.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kiểm tra: $error')),
      );
    }
  }

  Future<void> _sync(ProviderConnection provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang đồng bộ usage từ nhà cung cấp...')),
    );

    try {
      final result = await _controller.syncUsage(provider.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đồng bộ: $error')),
      );
    }
  }

  Future<void> _delete(ProviderConnection provider) async {
    try {
      await _controller.deleteProvider(provider.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xoá kết nối "${provider.name}".')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xoá kết nối: $error')),
      );
    }
  }

  /// Điều hướng dưới — chọn mục khác sẽ quay lại bảng điều khiển tổng quan.
  void _onNavChanged(int index) {
    if (index == 0) return;
    Navigator.of(context).maybePop();
  }
}
