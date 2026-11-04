import '../models/provider_connection.dart';
import 'api_client.dart';

/// Trạng thái kiểm tra riêng của một loại khoá (Claude dùng 2 loại).
///
/// `connected` | `invalid` | `missingPermissions` | `missingWorkspace` | `missing`.
class ProviderKeyCheck {
  const ProviderKeyCheck({
    required this.status,
    required this.message,
    this.httpStatus,
    this.detail,
  });

  /// Trạng thái của loại khoá.
  final String status;

  /// Thông điệp tiếng Việt từ backend.
  final String message;

  /// Mã HTTP thực tế từ nhà cung cấp.
  final int? httpStatus;

  /// Mô tả lỗi kỹ thuật.
  final String? detail;

  /// Khoá dùng được cho mục đích của nó.
  bool get isConnected => status == 'connected';

  /// Khoá không hợp lệ.
  bool get isInvalid => status == 'invalid';

  /// Khoá thiếu quyền cấp tổ chức.
  bool get isMissingPermissions => status == 'missingPermissions';

  /// Cần Workspace ID.
  bool get isMissingWorkspace => status == 'missingWorkspace';

  /// Chưa có khoá.
  bool get isMissing => status == 'missing';

  factory ProviderKeyCheck.fromJson(Map<String, dynamic> json) {
    return ProviderKeyCheck(
      status: json['status'] as String? ?? 'missing',
      message: json['message'] as String? ?? '',
      httpStatus: (json['httpStatus'] as num?)?.toInt(),
      detail: json['detail'] as String?,
    );
  }
}

/// Kết quả kiểm tra kết nối với nhà cung cấp (trả về từ backend).
class ProviderConnectionCheck {
  const ProviderConnectionCheck({
    required this.status,
    required this.message,
    this.httpStatus,
    this.models = const <String>[],
    this.detail,
    this.secretKey,
    this.adminKey,
  });

  /// `success` | `invalidKey` | `missingScope` | `unreachable`.
  final String status;

  /// Thông điệp tiếng Việt từ backend.
  final String message;

  /// Mã HTTP thực tế từ nhà cung cấp.
  final int? httpStatus;

  /// Danh sách model đọc được.
  final List<String> models;

  /// Mô tả lỗi kỹ thuật.
  final String? detail;

  /// Trạng thái Secret API Key — chỉ có với Anthropic.
  final ProviderKeyCheck? secretKey;

  /// Trạng thái Admin API Key — chỉ có với Anthropic.
  final ProviderKeyCheck? adminKey;

  bool get isSuccess => status == 'success';
  bool get isInvalidKey => status == 'invalidKey';
  bool get isMissingScope => status == 'missingScope';
  bool get isUnreachable => status == 'unreachable';

  /// Nhà cung cấp dùng hai loại khoá tách biệt (Anthropic).
  bool get hasSeparateKeys => secretKey != null || adminKey != null;

  factory ProviderConnectionCheck.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'];
    final rawSecret = json['secretKey'];
    final rawAdmin = json['adminKey'];
    return ProviderConnectionCheck(
      status: json['status'] as String? ?? 'unreachable',
      message: json['message'] as String? ?? '',
      httpStatus: (json['httpStatus'] as num?)?.toInt(),
      models: rawModels is List
          ? rawModels.map((m) => m.toString()).toList()
          : const <String>[],
      detail: json['detail'] as String?,
      secretKey: rawSecret is Map<String, dynamic>
          ? ProviderKeyCheck.fromJson(rawSecret)
          : null,
      adminKey: rawAdmin is Map<String, dynamic>
          ? ProviderKeyCheck.fromJson(rawAdmin)
          : null,
    );
  }
}

/// Kết quả đồng bộ usage từ nhà cung cấp.
class ProviderSyncResult {
  const ProviderSyncResult({required this.synced, required this.message});

  /// Số bản ghi đã đồng bộ.
  final int synced;

  /// Thông điệp kết quả.
  final String message;

  factory ProviderSyncResult.fromJson(Map<String, dynamic> json) {
    return ProviderSyncResult(
      synced: (json['synced'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Interface định nghĩa các thao tác với nhà cung cấp AI.
abstract class ProviderService {
  /// Lấy danh sách nhà cung cấp đã kết nối kèm số liệu usage thật.
  Future<ProvidersOverview> getProviders();

  /// Kiểm tra API Key với nhà cung cấp thật (chưa lưu).
  ///
  /// [adminApiKey] là Admin API Key của tổ chức — dùng cho OpenAI và
  /// Anthropic để kiểm tra quyền đọc Usage & Costs.
  ///
  /// [workspaceId] là Workspace ID của Anthropic (`wsp_...`) — tuỳ chọn.
  Future<ProviderConnectionCheck> testConnection({
    required String providerType,
    required String apiKey,
    String? adminApiKey,
    String? workspaceId,
  });

  /// Tạo kết nối mới — backend kiểm tra rồi lưu API key đã mã hoá.
  ///
  /// [adminApiKey] được lưu mã hoá cùng kết nối.
  /// [workspaceId] được lưu mã hoá cùng kết nối (Anthropic).
  Future<ProviderConnection> connect({
    required String name,
    required String providerType,
    required String apiKey,
    String? adminApiKey,
    String? workspaceId,
  });

  /// Cập nhật khoá của một kết nối đã lưu — từng loại khoá độc lập.
  ///
  /// Chỉ trường được truyền lên mới thay đổi; các trường khác giữ nguyên.
  Future<ProviderConnection> updateKeys(
    String providerId, {
    String? apiKey,
    String? adminApiKey,
    String? workspaceId,
    bool clearAdminApiKey = false,
  });

  /// Kiểm tra lại một kết nối đã lưu.
  Future<ProviderConnectionCheck> recheck(String providerId);

  /// Đồng bộ usage & billing từ nhà cung cấp.
  Future<ProviderSyncResult> syncUsage(String providerId);

  /// Đổi tên kết nối.
  Future<ProviderConnection> rename(String providerId, String name);

  /// Xoá kết nối.
  Future<void> delete(String providerId);
}

/// Triển khai gọi backend thật.
class ApiProviderService implements ProviderService {
  ApiProviderService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<ProvidersOverview> getProviders() async {
    final data = await _client.get('/providers');
    return ProvidersOverview.fromJson(data);
  }

  @override
  Future<ProviderConnectionCheck> testConnection({
    required String providerType,
    required String apiKey,
    String? adminApiKey,
    String? workspaceId,
  }) async {
    final body = <String, dynamic>{
      'providerType': providerType,
      'apiKey': apiKey,
    };
    if (adminApiKey != null && adminApiKey.trim().isNotEmpty) {
      body['adminApiKey'] = adminApiKey.trim();
    }
    if (workspaceId != null && workspaceId.trim().isNotEmpty) {
      body['workspaceId'] = workspaceId.trim();
    }
    final data = await _client.post('/providers/test', body: body);
    return ProviderConnectionCheck.fromJson(data);
  }

  @override
  Future<ProviderConnection> connect({
    required String name,
    required String providerType,
    required String apiKey,
    String? adminApiKey,
    String? workspaceId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'providerType': providerType,
      'apiKey': apiKey,
    };
    if (adminApiKey != null && adminApiKey.trim().isNotEmpty) {
      body['adminApiKey'] = adminApiKey.trim();
    }
    if (workspaceId != null && workspaceId.trim().isNotEmpty) {
      body['workspaceId'] = workspaceId.trim();
    }
    final data = await _client.post('/providers', body: body);
    return ProviderConnection.fromJson(data['provider'] as Map<String, dynamic>);
  }

  @override
  Future<ProviderConnection> updateKeys(
    String providerId, {
    String? apiKey,
    String? adminApiKey,
    String? workspaceId,
    bool clearAdminApiKey = false,
  }) async {
    final body = <String, dynamic>{};
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      body['apiKey'] = apiKey.trim();
    }
    if (adminApiKey != null && adminApiKey.trim().isNotEmpty) {
      body['adminApiKey'] = adminApiKey.trim();
    }
    if (workspaceId != null && workspaceId.trim().isNotEmpty) {
      body['workspaceId'] = workspaceId.trim();
    }
    if (clearAdminApiKey) {
      body['clearAdminApiKey'] = true;
    }
    final data = await _client.patch(
      '/providers/$providerId/keys',
      body: body,
    );
    return ProviderConnection.fromJson(data['provider'] as Map<String, dynamic>);
  }

  @override
  Future<ProviderConnectionCheck> recheck(String providerId) async {
    final data = await _client.post('/providers/$providerId/check');
    return ProviderConnectionCheck.fromJson(data);
  }

  @override
  Future<ProviderSyncResult> syncUsage(String providerId) async {
    final data = await _client.post('/providers/$providerId/sync');
    return ProviderSyncResult.fromJson(data);
  }

  @override
  Future<ProviderConnection> rename(String providerId, String name) async {
    final data = await _client.patch(
      '/providers/$providerId',
      body: {'name': name},
    );
    return ProviderConnection.fromJson(data['provider'] as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String providerId) async {
    await _client.delete('/providers/$providerId');
  }
}
