import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ts_button.dart';
import '../../../core/widgets/ts_text_field.dart';
import '../../../models/provider_connection.dart';
import 'provider_key_widgets.dart';

/// Bottom sheet cập nhật khoá cho một kết nối đã lưu.
///
/// Mỗi loại khoá được cập nhật **độc lập**: trường bỏ trống sẽ **giữ nguyên**
/// khoá đang lưu, nên việc thay Admin API Key không làm mất Secret API Key và
/// ngược lại.
class ProviderKeysSheet extends StatefulWidget {
  const ProviderKeysSheet({
    super.key,
    required this.provider,
    required this.onSave,
  });

  /// Kết nối đang cập nhật — dùng để hiển thị trạng thái khoá hiện tại.
  final ProviderConnection provider;

  /// Lưu — trả về các trường đã thay đổi (null = giữ nguyên).
  final Future<void> Function({
    String? apiKey,
    String? adminApiKey,
    String? workspaceId,
    bool clearAdminApiKey,
  })
  onSave;

  @override
  State<ProviderKeysSheet> createState() => _ProviderKeysSheetState();
}

class _ProviderKeysSheetState extends State<ProviderKeysSheet> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _adminKeyController = TextEditingController();
  final TextEditingController _workspaceController = TextEditingController();

  String? _keyError;
  String? _adminKeyError;
  String? _workspaceError;

  bool _isSaving = false;
  bool _clearAdminKey = false;

  /// Nhà cung cấp dùng Workspace ID (Anthropic Claude).
  bool get _supportsWorkspaceId => widget.provider.providerType == 'anthropic';

  /// Nhãn của trường Secret API Key.
  String get _secretKeyLabel =>
      _supportsWorkspaceId ? 'Claude Secret API Key' : 'API Key';

  /// Gợi ý định dạng của Secret API Key.
  String get _secretKeyHint =>
      _supportsWorkspaceId ? 'sk-ant-...' : 'sk-...';

  /// Nhãn của trường Admin API Key.
  String get _adminKeyLabel =>
      _supportsWorkspaceId ? 'Claude Admin API Key' : 'Admin API Key';

  /// Gợi ý định dạng của Admin API Key.
  String get _adminKeyHint =>
      _supportsWorkspaceId ? 'sk-ant-admin-...' : 'sk-admin-...';

  @override
  void dispose() {
    _keyController.dispose();
    _adminKeyController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cập nhật khoá', style: AppTypography.h3),
              const SizedBox(height: 4),
              Text(
                provider.name,
                style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: AppSpacing.space16),
              // Trạng thái hiện tại của từng loại khoá.
              ProviderKeyStatusPanel(
                secretState:
                    keyCheckStateFrom(provider.secretKeyStatus) ??
                    KeyCheckState.idle,
                adminState:
                    keyCheckStateFrom(provider.adminKeyStatus) ??
                    KeyCheckState.idle,
                secretTitle: _secretKeyLabel,
                adminTitle: _adminKeyLabel,
              ),
              const SizedBox(height: AppSpacing.space16),
              TsTextField(
                label: _secretKeyLabel,
                hint: _secretKeyHint,
                controller: _keyController,
                icon: Icons.key_rounded,
                obscureText: true,
                errorText: _keyError,
                helperText:
                    'Bỏ trống nếu không muốn thay Secret API Key đang lưu.',
                onChanged: (_) {
                  if (_keyError != null) setState(() => _keyError = null);
                },
              ),
              const SizedBox(height: AppSpacing.space16),
              TsTextField(
                label: _adminKeyLabel,
                hint: _adminKeyHint,
                controller: _adminKeyController,
                icon: Icons.admin_panel_settings_outlined,
                obscureText: true,
                errorText: _adminKeyError,
                helperText:
                    'Khoá quản trị tổ chức cho Usage & Cost Report. '
                    'Bỏ trống nếu không muốn thay khoá đang lưu.',
                onChanged: (_) {
                  if (_adminKeyError != null) {
                    setState(() => _adminKeyError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.space8),
              CheckboxListTile(
                value: _clearAdminKey,
                onChanged: (value) {
                  setState(() => _clearAdminKey = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Xoá Admin API Key đang lưu',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              if (_supportsWorkspaceId) ...[
                TsTextField(
                  label: 'Claude Workspace ID',
                  hint: 'wrkspc_...',
                  controller: _workspaceController,
                  icon: Icons.workspaces_outline,
                  errorText: _workspaceError,
                  helperText:
                      'Tuỳ chọn — chỉ dùng khi Secret API Key chưa được scope '
                      'vào Workspace nào.',
                  onChanged: (_) {
                    if (_workspaceError != null) {
                      setState(() => _workspaceError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.space16),
              ],
              TsButton(
                label: 'Lưu khoá',
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _handleSave,
              ),
              const SizedBox(height: AppSpacing.space12),
              TsButton(
                label: 'Huỷ',
                variant: TsButtonVariant.danger,
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kiểm tra & gửi các trường đã thay đổi lên backend.
  Future<void> _handleSave() async {
    final key = _keyController.text.trim();
    final adminKey = _adminKeyController.text.trim();
    final workspaceId = _workspaceController.text.trim();

    final keyError = key.isNotEmpty && key.length < 8
        ? 'Secret API Key quá ngắn.'
        : null;
    final adminKeyError = adminKey.isNotEmpty && adminKey.length < 8
        ? 'Admin API Key quá ngắn.'
        : null;
    final workspaceError = validateClaudeWorkspaceId(workspaceId);

    setState(() {
      _keyError = keyError;
      _adminKeyError = adminKeyError;
      _workspaceError = workspaceError;
    });

    if (keyError != null || adminKeyError != null || workspaceError != null) {
      return;
    }

    // Không có gì thay đổi → không gọi API.
    final hasChange =
        key.isNotEmpty ||
        adminKey.isNotEmpty ||
        workspaceId.isNotEmpty ||
        _clearAdminKey;
    if (!hasChange) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        apiKey: key.isEmpty ? null : key,
        adminApiKey: adminKey.isEmpty ? null : adminKey,
        workspaceId: workspaceId.isEmpty ? null : workspaceId,
        clearAdminApiKey: _clearAdminKey,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu khoá: $error')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }
}
