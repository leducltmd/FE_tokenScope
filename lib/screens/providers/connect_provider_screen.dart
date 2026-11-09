import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_button.dart';
import '../../core/widgets/ts_text_field.dart';
import '../../providers/firebase_lab3_controller.dart';
import '../../providers/providers_controller.dart';
import '../../services/provider_service.dart';
import 'widgets/connect_provider_widgets.dart';
import 'widgets/provider_key_widgets.dart';

/// Màn hình "Kết nối nhà cung cấp AI".
///
/// Bố cục: Đầu trang → Chọn nhà cung cấp → Form kết nối API → Trạng thái kiểm
/// tra → Thông tin usage & billing → Hành động.
class ConnectProviderScreen extends StatefulWidget {
  const ConnectProviderScreen({
    super.key,
    this.initialProviderId,
    this.onBack,
    this.onConnected,
    this.service,
  });

  /// Nhà cung cấp được chọn sẵn khi mở màn hình.
  final String? initialProviderId;

  /// Quay lại màn hình trước.
  final VoidCallback? onBack;

  /// Gọi khi kết nối thành công — truyền tên kết nối và nhà cung cấp.
  final void Function(String connectionName, ConnectableProvider provider)?
  onConnected;

  /// Nguồn dữ liệu — mặc định gọi backend thật.
  final ProviderService? service;

  @override
  State<ConnectProviderScreen> createState() => _ConnectProviderScreenState();
}

class _ConnectProviderScreenState extends State<ConnectProviderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  /// Admin API Key của tổ chức (OpenAI / Anthropic) — để đọc Usage & Costs.
  final TextEditingController _adminKeyController = TextEditingController();

  /// Workspace ID của Anthropic (`wrkspc_...`) — tuỳ chọn.
  final TextEditingController _workspaceIdController = TextEditingController();

  /// Service gọi backend thật — kiểm tra và lưu API key.
  late final ProviderService _service = widget.service ?? ApiProviderService();

  /// Nhà cung cấp đang chọn.
  ConnectableProvider? _provider;

  /// Trạng thái kiểm tra kết nối.
  ConnectionStatus _status = ConnectionStatus.idle;

  /// Thông điệp chi tiết từ backend (mô tả lỗi của nhà cung cấp).
  String? _backendDetail;

  /// Trạng thái Secret API Key (Anthropic) — kiểm tra độc lập.
  KeyCheckState _secretKeyState = KeyCheckState.idle;

  /// Trạng thái Admin API Key (Anthropic) — kiểm tra độc lập.
  KeyCheckState _adminKeyState = KeyCheckState.idle;

  /// Thông điệp chi tiết của từng loại khoá (Anthropic).
  String? _secretKeyMessage;
  String? _adminKeyMessage;

  /// Danh sách model đọc được từ nhà cung cấp sau khi kiểm tra thành công.
  List<String> _detectedModels = const [];

  /// Thông điệp lỗi của trường tên kết nối.
  String? _nameError;

  /// Thông điệp lỗi của trường API Key.
  String? _keyError;

  /// Thông điệp lỗi của trường Admin API Key.
  String? _adminKeyError;

  /// Thông điệp lỗi của trường Workspace ID.
  String? _workspaceIdError;

  @override
  void initState() {
    super.initState();

    // Chọn sẵn nhà cung cấp nếu được truyền vào.
    if (widget.initialProviderId != null) {
      _provider = _findProvider(widget.initialProviderId!);
      _nameController.text = _provider?.name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _adminKeyController.dispose();
    _workspaceIdController.dispose();
    super.dispose();
  }

  // ── Tìm nhà cung cấp theo mã ─────────────────────────────────────────
  ConnectableProvider? _findProvider(String id) {
    for (final provider in kConnectableProviders) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space8,
                  AppSpacing.screenPadding,
                  AppSpacing.space32,
                ),
                children: [
                  _buildSectionTitle('1 · Chọn nhà cung cấp'),
                  const SizedBox(height: AppSpacing.space12),
                  ProviderPickerGrid(
                    providers: kConnectableProviders,
                    selectedId: _provider?.id,
                    onSelected: _handleSelectProvider,
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  if (_provider != null) ...[
                    _buildSectionTitle('2 · Kết nối API'),
                    const SizedBox(height: AppSpacing.space12),
                    _buildForm(),
                    const SizedBox(height: AppSpacing.space16),
                    _buildStatusPanel(),
                    const SizedBox(height: AppSpacing.space24),
                    _buildSectionTitle('3 · Usage & Billing'),
                    const SizedBox(height: AppSpacing.space12),
                    UsageBillingInfoCard(provider: _provider),
                    const SizedBox(height: AppSpacing.space24),
                    _buildActions(),
                  ] else
                    _buildEmptySelection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Đầu trang ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space12,
        AppSpacing.space8,
        AppSpacing.screenPadding,
        AppSpacing.space8,
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 21,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kết nối nhà cung cấp',
                  style: AppTypography.h3.copyWith(fontSize: 19),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Thêm nguồn dữ liệu token & chi phí',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tiêu đề nhóm ──────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.h3.copyWith(fontSize: 16),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Form kết nối API ──────────────────────────────────────────────────
  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tên kết nối.
          TsTextField(
            label: 'Tên kết nối',
            hint: '${_provider!.name} Personal',
            controller: _nameController,
            icon: Icons.badge_outlined,
            errorText: _nameError,
            helperText:
                'Đặt tên để phân biệt nhiều kết nối của cùng nhà cung cấp.',
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: AppSpacing.space16),
          // Secret API Key — dùng cho các API thông thường của nhà cung cấp.
          TsTextField(
            label: _secretKeyLabel,
            hint: _provider!.keyHint,
            controller: _keyController,
            icon: Icons.key_rounded,
            obscureText: true,
            errorText: _keyError,
            helperText: _secretKeyHelper,
            onChanged: (_) {
              if (_keyError != null) setState(() => _keyError = null);
              // Sửa Secret API Key làm trạng thái kiểm tra trở về "chưa kiểm tra".
              if (_status != ConnectionStatus.idle) {
                setState(() {
                  _status = ConnectionStatus.idle;
                  _backendDetail = null;
                  _detectedModels = const [];
                  _secretKeyState = KeyCheckState.idle;
                  _secretKeyMessage = null;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.space16),
          // Admin API Key của tổ chức — dùng riêng cho Usage & Cost report.
          if (_provider!.supportsAdminKey) ...[
            TsTextField(
              label: _adminKeyLabel,
              hint: _adminKeyHint,
              controller: _adminKeyController,
              icon: Icons.admin_panel_settings_outlined,
              obscureText: true,
              errorText: _adminKeyError,
              helperText: _adminKeyHelper,
              onChanged: (_) {
                if (_adminKeyError != null) {
                  setState(() => _adminKeyError = null);
                }
                if (_status != ConnectionStatus.idle) {
                  setState(() {
                    _status = ConnectionStatus.idle;
                    _backendDetail = null;
                    _detectedModels = const [];
                    _adminKeyState = KeyCheckState.idle;
                    _adminKeyMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.space16),
          ],
          // Workspace ID — chỉ Anthropic, tuỳ chọn.
          if (_provider!.supportsWorkspaceId) ...[
            TsTextField(
              label: 'Claude Workspace ID',
              hint: 'wrkspc_...',
              controller: _workspaceIdController,
              icon: Icons.workspaces_outline,
              errorText: _workspaceIdError,
              helperText:
                  'Tuỳ chọn. Chỉ cần nhập khi Secret API Key chưa được scope '
                  'vào Workspace nào — Anthropic sẽ yêu cầu header '
                  'anthropic-workspace-id.',
              onChanged: (_) {
                if (_workspaceIdError != null) {
                  setState(() => _workspaceIdError = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.space16),
          ],
          ApiKeyGuideCard(
            provider: _provider!,
            onOpenLink: _handleOpenApiKeyPage,
          ),
        ],
      ),
    );
  }

  // ── Nhãn & gợi ý theo từng loại khoá ──────────────────────────────────

  /// Nhãn của trường Secret API Key.
  String get _secretKeyLabel {
    if (_provider?.id == 'anthropic') return 'Claude Secret API Key';
    return 'API Key';
  }

  /// Gợi ý của trường Secret API Key.
  String get _secretKeyHelper {
    if (_provider?.id == 'anthropic') {
      return 'Khoá dùng cho các API thông thường của Claude: kiểm tra kết nối, '
          'đọc danh sách model và gọi model. Khóa được lưu mã hoá trên máy chủ.';
    }
    return 'Khóa được lưu cục bộ và chỉ dùng để gọi API của nhà cung cấp.';
  }

  /// Nhãn của trường Admin API Key.
  String get _adminKeyLabel => _provider?.adminKeyLabel ?? 'Admin API Key';

  /// Gợi ý định dạng của Admin API Key.
  String get _adminKeyHint =>
      _provider?.adminKeyHint ??
      (_provider?.id == 'openai' ? 'sk-admin-...' : 'sk-ant-admin-...');

  /// Giải thích Admin API Key.
  String get _adminKeyHelper {
    final custom = _provider?.adminKeyHelper;
    if (custom != null) return custom;
    return 'Tuỳ chọn. Khóa quản trị của tổ chức để đọc Usage & Costs. '
        'Bỏ trống nếu bạn không cần đồng bộ token/chi phí.';
  }

  // ── Bảng trạng thái kiểm tra kết nối ──────────────────────────────────
  Widget _buildStatusPanel() {
    final showKeyPanel = _provider?.id == 'anthropic';

    if (!showKeyPanel) {
      return ConnectionStatusPanel(
        status: _status,
        detail: _provider == null ? null : _statusDetail,
      );
    }

    // Claude dùng hai loại khoá tách biệt → hiển thị hai hàng trạng thái riêng.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProviderKeyStatusPanel(
          secretState: _secretKeyState,
          adminState: _adminKeyState,
          secretMessage: _secretKeyMessage,
          adminMessage: _adminKeyMessage,
        ),
        const SizedBox(height: AppSpacing.space12),
        ConnectionStatusPanel(
          status: _status,
          detail: _provider == null ? null : _statusDetail,
        ),
      ],
    );
  }

  String? get _statusDetail {
    switch (_status) {
      case ConnectionStatus.idle:
        return null;
      case ConnectionStatus.checking:
        return 'Đang kiểm tra ${_provider!.name}...';
      case ConnectionStatus.success:
        final models = _detectedModels.isEmpty
            ? ''
            : ' · Đã đọc được ${_detectedModels.length} model.';
        return '${_provider!.name} · TokenScope đã đọc được thông tin kết nối.$models';
      case ConnectionStatus.invalidKey:
        return _backendDetail ?? 'Mã lỗi: 401 Unauthorized';
      case ConnectionStatus.unreachable:
        return _backendDetail ?? 'Mã lỗi: 503 Service Unavailable';
      case ConnectionStatus.missingScope:
        return _backendDetail ??
            'Mã lỗi: 403 Forbidden — thiếu scope usage/billing';
    }
  }

  // ── Hành động ─────────────────────────────────────────────────────────
  Widget _buildActions() {
    final isBusy = _status.isChecking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kiểm tra kết nối.
        TsButton(
          label: 'Kiểm tra kết nối',
          icon: Icons.wifi_tethering_rounded,
          isLoading: isBusy,
          onPressed: isBusy ? null : _handleTestConnection,
        ),
        const SizedBox(height: AppSpacing.space12),
        // Kết nối.
        TsButton(
          label: 'Kết nối',
          icon: Icons.link_rounded,
          variant: TsButtonVariant.secondary,
          onPressed: isBusy ? null : _handleConnect,
        ),
        const SizedBox(height: AppSpacing.space12),
        // Hủy.
        TsButton(
          label: 'Hủy',
          variant: TsButtonVariant.danger,
          onPressed: isBusy ? null : () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  // ── Trạng thái chưa chọn nhà cung cấp ─────────────────────────────────
  Widget _buildEmptySelection() {
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
          const Icon(Icons.hub_outlined, size: 32, color: AppColors.disabled),
          const SizedBox(height: AppSpacing.space12),
          Text(
            'Chọn một nhà cung cấp',
            style: AppTypography.label.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Form kết nối API và hướng dẫn lấy khóa sẽ hiển thị tương ứng.',
            style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Hành vi ───────────────────────────────────────────────────────────
  /// Chọn nhà cung cấp — đặt lại form và trạng thái kiểm tra.
  void _handleSelectProvider(ConnectableProvider provider) {
    setState(() {
      _provider = provider;
      _status = ConnectionStatus.idle;
      _nameError = null;
      _keyError = null;
      _adminKeyError = null;
      _workspaceIdError = null;
      _backendDetail = null;
      _detectedModels = const [];
      _secretKeyState = KeyCheckState.idle;
      _adminKeyState = KeyCheckState.idle;
      _secretKeyMessage = null;
      _adminKeyMessage = null;

      // Gợi ý tên kết nối mặc định theo nhà cung cấp.
      if (_nameController.text.trim().isEmpty ||
          kConnectableProviders.any((p) => p.name == _nameController.text)) {
        _nameController.text = '${provider.name} Personal';
      }
    });
  }

  /// Kiểm tra kết nối — gọi API thật của nhà cung cấp qua backend.
  Future<void> _handleTestConnection() async {
    if (!_validateForm()) return;

    setState(() {
      _status = ConnectionStatus.checking;
      _backendDetail = null;
      _secretKeyState = KeyCheckState.checking;
      _adminKeyState = KeyCheckState.checking;
      _secretKeyMessage = null;
      _adminKeyMessage = null;
    });

    try {
      final result = await _service.testConnection(
        providerType: _provider!.id,
        apiKey: _keyController.text.trim(),
        adminApiKey: _adminApiKeyValue,
        workspaceId: _workspaceIdValue,
      );

      if (!mounted) return;

      setState(() {
        _status = _mapStatus(result.status);
        _detectedModels = result.models;
        _backendDetail = result.detail;

        // Trạng thái từng loại khoá (Anthropic) — độc lập, không suy ra từ
        // trạng thái tổng thể.
        if (result.hasSeparateKeys) {
          _secretKeyState =
              keyCheckStateFrom(result.secretKey?.status) ??
              (result.secretKey == null
                  ? KeyCheckState.missing
                  : KeyCheckState.idle);
          _adminKeyState =
              keyCheckStateFrom(result.adminKey?.status) ??
              (result.adminKey == null
                  ? KeyCheckState.missing
                  : KeyCheckState.idle);
          _secretKeyMessage = result.secretKey?.message;
          _adminKeyMessage = result.adminKey?.message;
        }
      });

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kết nối tới ${_provider!.name} thành công — API Key hợp lệ.',
            ),
          ),
        );
      }
    } catch (error, stack) {
      FirebaseLab3Controller.instance.recordError(
        error,
        stack,
        reason: 'Lỗi lưu kết nối provider ${_provider?.id}',
      );
      if (!mounted) return;
      setState(() {
        _status = ConnectionStatus.unreachable;
        _backendDetail = error.toString();
        _secretKeyState = KeyCheckState.invalid;
        _adminKeyState = KeyCheckState.invalid;
      });
    }
  }

  /// Chuyển trạng thái từ backend về trạng thái hiển thị của UI.
  ConnectionStatus _mapStatus(String status) {
    switch (status) {
      case 'success':
        return ConnectionStatus.success;
      case 'invalidKey':
        return ConnectionStatus.invalidKey;
      case 'missingScope':
        return ConnectionStatus.missingScope;
      default:
        return ConnectionStatus.unreachable;
    }
  }

  /// Kết nối — lưu API key (đã mã hoá) lên backend.
  Future<void> _handleConnect() async {
    if (!_validateForm()) return;

    if (_status != ConnectionStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy kiểm tra kết nối thành công trước khi kết nối.'),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();

    setState(() => _status = ConnectionStatus.checking);

    try {
      final connection = await _service.connect(
        name: name,
        providerType: _provider!.id,
        apiKey: _keyController.text.trim(),
        adminApiKey: _adminApiKeyValue,
        workspaceId: _workspaceIdValue,
      );
      if (connection.requestCount > 0) {
        ProvidersController.notifyUsageChanged();
      }
    } catch (error, stack) {
      FirebaseLab3Controller.instance.recordError(
        error,
        stack,
        reason: 'Lỗi lưu kết nối provider ${_provider?.id}',
      );
      if (!mounted) return;
      setState(() {
        _status = ConnectionStatus.unreachable;
        _backendDetail = error.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu kết nối: $error')));
      return;
    }

    if (!mounted) return;

    setState(() => _status = ConnectionStatus.success);
    // Ghi nhận sự kiện Analytics khi kết nối Provider.
    FirebaseLab3Controller.instance.logConnectProvider(
      providerType: _provider!.id,
      hasAdminKey: _adminApiKeyValue != null && _adminApiKeyValue!.isNotEmpty,
    );

    widget.onConnected?.call(name, _provider!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã kết nối "$name" với ${_provider!.name}.')),
    );

    if (mounted) Navigator.of(context).maybePop();
  }

  /// Admin API Key đã nhập, chuẩn hoá (rỗng nếu không có hoặc không dùng).
  String? get _adminApiKeyValue {
    if (_provider == null || !_provider!.supportsAdminKey) return null;
    final value = _adminKeyController.text.trim();
    return value.isEmpty ? null : value;
  }

  /// Workspace ID đã nhập, chuẩn hoá (rỗng nếu không có hoặc không dùng).
  String? get _workspaceIdValue {
    if (_provider == null || !_provider!.supportsWorkspaceId) return null;
    final value = _workspaceIdController.text.trim();
    return value.isEmpty ? null : value;
  }

  /// Kiểm tra dữ liệu nhập trước khi gọi API.
  bool _validateForm() {
    final name = _nameController.text.trim();
    final key = _keyController.text.trim();
    final adminKey = _adminKeyController.text.trim();
    final workspaceId = _workspaceIdController.text.trim();

    final nameError = name.isEmpty ? 'Vui lòng nhập tên kết nối.' : null;
    final keyError = key.isEmpty ? 'Vui lòng nhập API Key.' : null;

    // Admin API Key là tuỳ chọn — nhưng nếu có nhập thì phải đủ dài.
    final adminKeyError = adminKey.isNotEmpty && adminKey.length < 8
        ? 'Admin API Key quá ngắn.'
        : null;

    final workspaceIdError = validateClaudeWorkspaceId(workspaceId);

    setState(() {
      _nameError = nameError;
      _keyError = keyError;
      _adminKeyError = adminKeyError;
      _workspaceIdError = workspaceIdError;
    });

    return nameError == null &&
        keyError == null &&
        adminKeyError == null &&
        workspaceIdError == null;
  }

  /// Mở trang quản lý API Key chính thức của nhà cung cấp.
  ///
  /// Ứng dụng chưa phụ thuộc `url_launcher` nên link được sao chép vào clipboard
  /// kèm thông báo hướng dẫn mở bằng trình duyệt.
  Future<void> _handleOpenApiKeyPage() async {
    final url = _provider!.apiKeyUrl;

    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $url — mở bằng trình duyệt để tạo API Key.'),
      ),
    );
  }
}
