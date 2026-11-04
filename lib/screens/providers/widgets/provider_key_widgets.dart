import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ── Trạng thái từng loại khoá (Anthropic Claude) ─────────────────────────

/// Trạng thái hiển thị của một loại khoá.
enum KeyCheckState {
  /// Chưa kiểm tra.
  idle('Chưa kiểm tra', AppColors.secondaryText, AppColors.background),

  /// Đang kiểm tra.
  checking('Đang kiểm tra', AppColors.primary, AppColors.primaryLight),

  /// Khoá hợp lệ và dùng được.
  connected('Đã kết nối', AppColors.success, AppColors.successLight),

  /// Khoá không hợp lệ.
  invalid('Khoá không hợp lệ', AppColors.error, AppColors.errorLight),

  /// Khoá thiếu quyền cấp tổ chức.
  missingPermissions(
    'Thiếu quyền tổ chức',
    AppColors.warning,
    AppColors.warningLight,
  ),

  /// Cần Workspace ID.
  missingWorkspace(
    'Thiếu Workspace ID',
    AppColors.warning,
    AppColors.warningLight,
  ),

  /// Chưa có khoá.
  missing('Chưa cấu hình', AppColors.secondaryText, AppColors.background);

  const KeyCheckState(this.label, this.color, this.background);

  /// Nhãn hiển thị.
  final String label;

  /// Màu nhấn.
  final Color color;

  /// Màu nền huy hiệu.
  final Color background;

  /// Biểu tượng ứng với trạng thái.
  IconData get icon {
    switch (this) {
      case KeyCheckState.idle:
        return Icons.help_outline_rounded;
      case KeyCheckState.checking:
        return Icons.sync_rounded;
      case KeyCheckState.connected:
        return Icons.check_circle_rounded;
      case KeyCheckState.invalid:
        return Icons.key_off_rounded;
      case KeyCheckState.missingPermissions:
        return Icons.lock_person_rounded;
      case KeyCheckState.missingWorkspace:
        return Icons.workspaces_outline;
      case KeyCheckState.missing:
        return Icons.remove_circle_outline_rounded;
    }
  }
}

/// Bảng ánh xạ trạng thái từ backend sang trạng thái hiển thị.
///
/// `null` khi backend không trả về trạng thái cho loại khoá đó.
KeyCheckState? keyCheckStateFrom(String? status) {
  switch (status) {
    case 'connected':
      return KeyCheckState.connected;
    case 'invalid':
      return KeyCheckState.invalid;
    case 'missingPermissions':
      return KeyCheckState.missingPermissions;
    case 'missingWorkspace':
      return KeyCheckState.missingWorkspace;
    case 'missing':
      return KeyCheckState.missing;
    default:
      return null;
  }
}

/// Huy hiệu trạng thái của một loại khoá — chấm màu kèm nhãn.
class KeyStatusBadge extends StatelessWidget {
  const KeyStatusBadge({super.key, required this.state, this.label});

  /// Trạng thái hiển thị.
  final KeyCheckState state;

  /// Nhãn tuỳ chỉnh (mặc định lấy từ [KeyCheckState]).
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: state.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: state.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label ?? state.label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: state.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bảng trạng thái riêng cho từng loại khoá của Claude.
///
/// Hiển thị **hai hàng độc lập**:
/// - Secret API Key → Connected / Invalid
/// - Admin API Key → Connected / Missing permissions / Invalid
class ProviderKeyStatusPanel extends StatelessWidget {
  const ProviderKeyStatusPanel({
    super.key,
    required this.secretState,
    required this.adminState,
    this.secretMessage,
    this.adminMessage,
    this.secretTitle = 'Claude Secret API Key',
    this.adminTitle = 'Claude Admin API Key',
  });

  /// Trạng thái Secret API Key.
  final KeyCheckState secretState;

  /// Trạng thái Admin API Key.
  final KeyCheckState adminState;

  /// Thông điệp chi tiết của Secret API Key.
  final String? secretMessage;

  /// Thông điệp chi tiết của Admin API Key.
  final String? adminMessage;

  /// Nhãn của hàng Secret API Key.
  final String secretTitle;

  /// Nhãn của hàng Admin API Key.
  final String adminTitle;

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
          Row(
            children: [
              const Icon(
                Icons.key_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Trạng thái khoá',
                style: AppTypography.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          _buildRow(
            title: secretTitle,
            state: secretState,
            message: secretMessage,
          ),
          const SizedBox(height: AppSpacing.space12),
          _buildRow(
            title: adminTitle,
            state: adminState,
            message: adminMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String title,
    required KeyCheckState state,
    String? message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: state.background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: state.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(state.icon, size: 18, color: state.color),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    KeyStatusBadge(state: state),
                  ],
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
