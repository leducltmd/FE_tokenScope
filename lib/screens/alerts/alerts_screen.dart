import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_card.dart';
import '../../models/in_app_notification.dart';
import '../../providers/firebase_lab3_controller.dart';
import '../budget/budget_screen.dart';
import '../providers/providers_screen.dart';

/// Màn hình Trung tâm thông báo (Alerts & Notifications).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _firebase = FirebaseLab3Controller.instance;

  @override
  void initState() {
    super.initState();
    _firebase.markAllNotificationsAsRead();
  }

  void _copyTokenToClipboard() {
    final token = _firebase.currentNotificationToken;
    if (token != null && token.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: token));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép mã thiết bị.'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có Device Token. Đang làm mới...')),
      );
      _firebase.fetchNotificationToken().then((_) => setState(() {}));
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await _firebase.requestNotificationPermission();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Đã cấp quyền nhận thông báo thành công!'
                : 'Quyền thông báo chưa được cấp hoặc bị từ chối.',
          ),
          backgroundColor: granted ? AppColors.emerald : AppColors.warning,
        ),
      );
    }
  }

  void _handleNotificationTap(InAppNotification notification) {
    final screen = notification.targetScreen;
    if (screen == 'budget') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const BudgetScreen()));
    } else if (screen == 'providers') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProvidersScreen()));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã mở: ${notification.title}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trung tâm thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_remove_rounded),
            tooltip: 'Xóa tất cả',
            onPressed: () {
              _firebase.clearNotifications();
              setState(() {});
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<InAppNotification>>(
        valueListenable: _firebase.notifications,
        builder: (context, notifications, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              _buildFcmStatusCard(),
              const SizedBox(height: AppSpacing.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thông báo đã nhận (${notifications.length})',
                    style: AppTypography.h3.copyWith(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              if (notifications.isEmpty)
                _buildEmptyState()
              else
                ...notifications.map(_buildNotificationItem),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFcmStatusCard() {
    final token =
        _firebase.currentNotificationToken ?? 'Đang tải hoặc chưa có token';
    final isAuthorized = _firebase.isNotificationAuthorized;

    return TsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông báo đẩy',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAuthorized
                                ? AppColors.emerald
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAuthorized
                              ? 'Quyền: Đã cho phép'
                              : 'Quyền: Chưa cấp quyền',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isAuthorized)
                TextButton(
                  onPressed: _requestNotificationPermission,
                  child: const Text(
                    'Xin quyền',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.space12),
          Text(
            'Mã thiết bị',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softPurple.withAlpha(80),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    token,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: _copyTokenToClipboard,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return TsCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.space12),
          const Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thông báo mới sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(InAppNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: TsCard(
        padding: const EdgeInsets.all(AppSpacing.space12),
        onTap: () => _handleNotificationTap(notification),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.softPurple.withAlpha(100)
                    : AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_rounded,
                size: 18,
                color: notification.isRead
                    ? AppColors.secondaryText
                    : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        notification.timeFormatted,
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (notification.targetScreen != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mở: ${notification.targetScreen}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
