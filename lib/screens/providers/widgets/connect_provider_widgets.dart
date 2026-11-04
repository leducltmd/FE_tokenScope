import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Một nhà cung cấp AI có thể kết nối.
///
/// Mỗi nhà cung cấp mang theo hướng dẫn lấy API Key và liên kết tới trang
/// quản lý khóa chính thức.
class ConnectableProvider {
  const   ConnectableProvider({
    required this.id,
    required this.name,
    required this.letter,
    required this.color,
    required this.keyHint,
    required this.apiKeyUrl,
    required this.apiKeyUrlLabel,
    required this.instructions,
    this.supportsUsage = true,
    this.requiresScopeNote,
    this.supportsAdminKey = false,
    this.supportsWorkspaceId = false,
    this.adminKeyHint,
    this.adminKeyLabel,
    this.adminKeyHelper,
    this.adminKeyUrl,
    this.adminKeyUrlLabel,
  });

  /// Mã định danh — `openai`.
  final String id;

  /// Tên hiển thị — `OpenAI`.
  final String name;

  /// Chữ cái hiển thị trong ô logo.
  final String letter;

  /// Màu nhận diện.
  final Color color;

  /// Gợi ý định dạng API Key — `sk-...`.
  final String keyHint;

  /// Link trang quản lý API Key chính thức.
  final String apiKeyUrl;

  /// Nhãn của link — `platform.openai.com/api-keys`.
  final String apiKeyUrlLabel;

  /// Hướng dẫn ngắn về cách lấy API Key.
  final String instructions;

  /// Nhà cung cấp có cung cấp đầy đủ dữ liệu usage/billing qua API.
  final bool supportsUsage;

  /// Nhà cung cấp cần thêm Admin API Key (quản trị tổ chức) bên cạnh API Key
  /// thường để đọc Usage & Costs.
  ///
  /// Hiện có với OpenAI và Anthropic: endpoint
  /// `/v1/organization/usage/completions` (OpenAI) và
  /// `/v1/organizations/usage_report/messages` + `/v1/organizations/cost_report`
  /// (Anthropic) chỉ chấp nhận Admin API Key của tổ chức.
  final bool supportsAdminKey;

  /// Nhà cung cấp cần thêm Workspace ID (`wsp_...`) bên cạnh khoá.
  ///
  /// Hiện chỉ Anthropic là true — Secret API Key chưa được scope vào Workspace
  /// nào thì mọi request phải kèm header `anthropic-workspace-id`.
  final bool supportsWorkspaceId;

  /// Gợi ý định dạng Admin API Key (ví dụ `sk-ant-admin-...`).
  final String? adminKeyHint;

  /// Nhãn trường Admin API Key (ví dụ `Claude Admin API Key`).
  final String? adminKeyLabel;

  /// Giải thích thêm về Admin API Key (quyền tổ chức).
  final String? adminKeyHelper;

  /// Link trang tạo Admin API Key chính thức.
  final String? adminKeyUrl;

  /// Nhãn của link Admin API Key.
  final String? adminKeyUrlLabel;

  /// Ghi chú về quyền truy cập usage/billing nếu có.
  final String? requiresScopeNote;
}

/// Danh sách nhà cung cấp hỗ trợ kết nối.
const List<ConnectableProvider> kConnectableProviders = [
  ConnectableProvider(
    id: 'openai',
    name: 'OpenAI',
    letter: 'O',
    color: AppColors.emerald,
    keyHint: 'sk-...',
    apiKeyUrl: 'https://platform.openai.com/api-keys',
    apiKeyUrlLabel: 'platform.openai.com/api-keys',
    instructions:
        'Vào Platform → Settings → API keys → Create new secret key, '
        'sau đó sao chép khóa (chỉ hiển thị một lần).',
    supportsAdminKey: true,
    requiresScopeNote:
        'Khóa cần quyền đọc Usage (organization) để đồng bộ token và chi phí.',
  ),
  ConnectableProvider(
    id: 'anthropic',
    name: 'Anthropic Claude',
    letter: 'A',
    color: AppColors.violet,
    keyHint: 'sk-ant-...',
    apiKeyUrl: 'https://console.anthropic.com/settings/keys',
    apiKeyUrlLabel: 'console.anthropic.com/settings/keys',
    instructions:
        'Vào Console → Settings → API Keys → Create Key, sao chép khóa '
        'ngay sau khi tạo.',
    supportsAdminKey: true,
    adminKeyHint: 'sk-ant-admin-...',
    adminKeyLabel: 'Claude Admin API Key',
    adminKeyHelper:
        'Khoá quản trị TỔ CHỨC dùng riêng cho Usage Report và Cost Report. '
        'Cần quyền đọc Usage & Costs ở cấp tổ chức '
        '(Anthropic Console → Settings → Admin keys). '
        'Secret API Key ở trên KHÔNG thay thế được cho khoá này.',
    adminKeyUrl: 'https://console.anthropic.com/settings/admin-keys',
    adminKeyUrlLabel: 'console.anthropic.com/settings/admin-keys',
    supportsWorkspaceId: true,
    requiresScopeNote:
        'Usage Report và Cost Report chỉ đọc được với Admin API Key có quyền '
        'tổ chức. Nếu Secret API Key chưa được scope vào Workspace nào, '
        'hãy nhập thêm Workspace ID (wsp_...).',
  ),
  ConnectableProvider(
    id: 'google',
    name: 'Google Gemini',
    letter: 'G',
    color: AppColors.azure,
    keyHint: 'AIza...',
    apiKeyUrl: 'https://aistudio.google.com/app/apikey',
    apiKeyUrlLabel: 'aistudio.google.com/app/apikey',
    instructions:
        'Vào Google AI Studio → Get API key → Create API key, sao chép '
        'khóa được hiển thị.',
    supportsUsage: false,
    requiresScopeNote:
        'Google AI Studio chưa cung cấp API billing đầy đủ — '
        'TokenScope sẽ ước tính chi phí từ số token đã dùng.',
  ),
  ConnectableProvider(
    id: 'mistral',
    name: 'Mistral AI',
    letter: 'M',
    color: AppColors.tangerine,
    keyHint: 'sk-...',
    apiKeyUrl: 'https://console.mistral.ai/api-keys',
    apiKeyUrlLabel: 'console.mistral.ai/api-keys',
    instructions:
        'Vào Console → API Keys → Create new key, sao chép khóa ngay '
        'sau khi tạo.',
  ),
  ConnectableProvider(
    id: 'groq',
    name: 'Groq',
    letter: 'G',
    color: AppColors.grape,
    keyHint: 'gsk_...',
    apiKeyUrl: 'https://console.groq.com/keys',
    apiKeyUrlLabel: 'console.groq.com/keys',
    instructions:
        'Vào Console → API Keys → Create API Key, sao chép khóa hiển thị.',
  ),
];

// ── Chọn nhà cung cấp ─────────────────────────────────────────────────────

/// Lưới chọn nhà cung cấp — mỗi ô là một nhà cung cấp có thể kết nối.
class ProviderPickerGrid extends StatelessWidget {
  const ProviderPickerGrid({
    super.key,
    required this.providers,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ConnectableProvider> providers;

  /// Mã nhà cung cấp đang chọn.
  final String? selectedId;

  /// Gọi khi người dùng chọn một nhà cung cấp.
  final ValueChanged<ConnectableProvider> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space12,
      runSpacing: AppSpacing.space12,
      children: [
        for (final provider in providers)
          _ProviderPickerTile(
            provider: provider,
            isSelected: provider.id == selectedId,
            onTap: () => onSelected(provider),
          ),
      ],
    );
  }
}

/// Ô chọn nhà cung cấp.
class _ProviderPickerTile extends StatelessWidget {
  const _ProviderPickerTile({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  final ConnectableProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.indigoSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: isSelected ? AppColors.indigo : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: provider.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  provider.letter,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: provider.color,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Text(
                provider.name,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.navy : AppColors.secondaryText,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.space8),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.indigo,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hướng dẫn lấy API Key ─────────────────────────────────────────────────

/// Thẻ hướng dẫn lấy API Key — mô tả các bước và liên kết chính thức.
class ApiKeyGuideCard extends StatelessWidget {
  const ApiKeyGuideCard({
    super.key,
    required this.provider,
    required this.onOpenLink,
  });

  final ConnectableProvider provider;

  /// Mở trang quản lý API Key chính thức.
  final VoidCallback onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Cách lấy API Key',
                style: AppTypography.label.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            provider.instructions,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: InkWell(
              onTap: onOpenLink,
              borderRadius: BorderRadius.circular(AppRadius.small),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.apiKeyUrlLabel,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trạng thái kiểm tra kết nối ───────────────────────────────────────────

/// Trạng thái kiểm tra kết nối tới nhà cung cấp.
enum ConnectionStatus {
  /// Chưa kiểm tra — người dùng chưa bấm "Kiểm tra kết nối".
  idle('Chưa kiểm tra', AppColors.secondaryText, AppColors.background),

  /// Đang kiểm tra kết nối.
  checking('Đang kiểm tra kết nối', AppColors.primary, AppColors.primaryLight),

  /// Kết nối thành công.
  success('Kết nối thành công', AppColors.success, AppColors.successLight),

  /// API Key không hợp lệ.
  invalidKey('API Key không hợp lệ', AppColors.error, AppColors.errorLight),

  /// Không thể kết nối tới nhà cung cấp.
  unreachable(
    'Không thể kết nối',
    AppColors.warning,
    AppColors.warningLight,
  ),

  /// API Key thiếu quyền truy cập usage/billing.
  missingScope(
    'Thiếu quyền truy cập',
    AppColors.warning,
    AppColors.warningLight,
  );

  const ConnectionStatus(this.label, this.color, this.background);

  /// Nhãn trạng thái.
  final String label;

  /// Màu nhấn.
  final Color color;

  /// Màu nền huy hiệu.
  final Color background;

  /// Đang trong quá trình kiểm tra.
  bool get isChecking => this == ConnectionStatus.checking;

  /// Đã kiểm tra thành công.
  bool get isSuccess => this == ConnectionStatus.success;

  /// Đã xảy ra lỗi — cần người dùng xử lý.
  bool get hasError =>
      this == ConnectionStatus.invalidKey ||
      this == ConnectionStatus.unreachable ||
      this == ConnectionStatus.missingScope;
}

/// Bảng thông điệp theo từng trạng thái kiểm tra kết nối.
const Map<ConnectionStatus, String> kConnectionMessages = {
  ConnectionStatus.idle:
      'Nhập API Key rồi bấm "Kiểm tra kết nối" để xác thực trước khi kết nối.',
  ConnectionStatus.checking:
      'Đang gửi yêu cầu tới nhà cung cấp để xác thực API Key...',
  ConnectionStatus.success:
      'API Key hợp lệ. TokenScope đã sẵn sàng đồng bộ token và chi phí.',
  ConnectionStatus.invalidKey:
      'API Key không hợp lệ hoặc đã bị thu hồi. Hãy kiểm tra lại khóa đã nhập.',
  ConnectionStatus.unreachable:
      'Không thể kết nối tới nhà cung cấp. Vui lòng kiểm tra mạng và thử lại.',
  ConnectionStatus.missingScope:
      'API Key hợp lệ nhưng thiếu quyền truy cập usage hoặc billing. '
      'Hãy bật thêm quyền này trong cài đặt nhà cung cấp rồi thử lại.',
};

/// Bảng gợi ý xử lý theo từng trạng thái lỗi.
const Map<ConnectionStatus, String> kConnectionHints = {
  ConnectionStatus.invalidKey:
      'Định dạng khóa thường bắt đầu bằng một tiền tố riêng của nhà cung cấp. '
      'Hãy dán lại khóa từ trang quản lý API Key.',
  ConnectionStatus.unreachable:
      'Nhà cung cấp có thể đang bảo trì hoặc tạm thời quá tải. '
      'Bạn vẫn có thể kết nối sau.',
  ConnectionStatus.missingScope:
      'TokenScope chỉ đọc được dữ liệu mà API Key được cấp quyền. '
      'Hãy kiểm tra các quyền Usage/Billing của khóa.',
};

/// Biểu tượng ứng với từng trạng thái kiểm tra kết nối.
IconData getConnectionIcon(ConnectionStatus status) {
  switch (status) {
    case ConnectionStatus.idle:
      return Icons.help_outline_rounded;
    case ConnectionStatus.checking:
      return Icons.sync_rounded;
    case ConnectionStatus.success:
      return Icons.check_circle_rounded;
    case ConnectionStatus.invalidKey:
      return Icons.key_off_rounded;
    case ConnectionStatus.unreachable:
      return Icons.cloud_off_rounded;
    case ConnectionStatus.missingScope:
      return Icons.lock_person_rounded;
  }
}

/// Bảng trạng thái kiểm tra kết nối — huy hiệu trạng thái kèm thông điệp.
class ConnectionStatusPanel extends StatelessWidget {
  const ConnectionStatusPanel({
    super.key,
    required this.status,
    this.detail,
  });

  /// Trạng thái hiện tại.
  final ConnectionStatus status;

  /// Chi tiết bổ sung (vd. tên nhà cung cấp, mã lỗi).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final message = kConnectionMessages[status] ?? '';
    final hint = kConnectionHints[status];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: status == ConnectionStatus.idle
              ? AppColors.border
              : status.color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (status.isChecking)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                  ),
                )
              else
                Icon(
                  getConnectionIcon(status),
                  size: 20,
                  color: status.color,
                ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  status.label,
                  style: AppTypography.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: status == ConnectionStatus.idle
                        ? AppColors.secondaryText
                        : AppColors.navy,
                  ),
                ),
              ),
              if (status.isSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Sẵn sàng',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.navy,
            ),
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.space12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: Text(
                      hint,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Thông tin usage & billing ─────────────────────────────────────────────

/// Khu vực giải thích về đồng bộ usage và billing.
class UsageBillingInfoCard extends StatelessWidget {
  const UsageBillingInfoCard({super.key, this.provider});

  /// Nhà cung cấp đang kết nối — dùng để ghi chú riêng nếu cần.
  final ConnectableProvider? provider;

  /// Các lưu ý dạng bullet.
  static const _notes = <(IconData, String)>[
    (
      Icons.sync_rounded,
      'Token usage và chi phí có thể được đồng bộ trực tiếp từ nhà cung cấp.',
    ),
    (
      Icons.info_outline_rounded,
      'Một số nhà cung cấp không cung cấp đầy đủ dữ liệu billing qua API — '
      'khi đó TokenScope sẽ ước tính từ số token đã dùng.',
    ),
    (
      Icons.calculate_outlined,
      'Chi phí ước tính từ token có thể khác với chi phí thực tế trên hóa đơn.',
    ),
    (
      Icons.shield_outlined,
      'TokenScope chỉ hiển thị dữ liệu mà API Key của bạn được cấp quyền truy cập.',
    ),
  ];

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
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.indigoSoft,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  'Usage & Billing',
                  style: AppTypography.label.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          for (final note in _notes) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(note.$1, size: 16, color: AppColors.secondaryText),
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: Text(
                    note.$2,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
          if (provider != null &&
              provider!.requiresScopeNote != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space12),
              decoration: BoxDecoration(
                color: AppColors.softPurple,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: Text(
                      provider!.requiresScopeNote!,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
