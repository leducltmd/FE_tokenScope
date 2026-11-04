import 'package:tokenscope/models/usage_record.dart';
import 'package:tokenscope/services/usage_history_service.dart';

/// Dịch vụ Mock cung cấp dữ liệu giả lập cho lịch sử gọi API TokenScope.
class MockUsageHistoryService implements UsageHistoryService {
  MockUsageHistoryService({
    this.simulateDelay = const Duration(milliseconds: 350),
    this.shouldFail = false,
  });

  final Duration simulateDelay;
  final bool shouldFail;

  static final List<UsageRecord> _mockDatabase = [
    // 1. OpenAI GPT-4o (Thành công - khớp hoàn toàn mô tả trong hình Figma và yêu cầu đề bài)
    UsageRecord(
      id: 'rec_01hk8a92m4b',
      promptId: 'pmt_94821a0f',
      provider: 'OpenAI',
      model: 'gpt-4o',
      project: 'Chatbot Support',
      projectIconType: 'folder',
      timestamp: _StaticTime.time1,
      timeDisplay: '10:42:15',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 1420,
      outputTokens: 580,
      totalTokens: 2000,
      cost: 0.0158,
      latencyMs: 420,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview:
          'Hãy hướng dẫn khách hàng cách tích hợp webhook nhận thông báo thanh toán thành công qua REST API.',
      responsePreview:
          'Để tích hợp webhook nhận thông báo thanh toán:\n1. Đăng ký URL endpoint nhận POST request\n2. Xác thực chữ ký số HMAC-SHA256 trên header\n3. Trả về mã HTTP 200 trong vòng 3 giây...',
      apiEndpoint: 'https://api.openai.com/v1/chat/completions',
    ),

    // 2. Anthropic Claude 3.5 Sonnet
    UsageRecord(
      id: 'rec_01hk8a93n5c',
      promptId: 'pmt_88319e7b',
      provider: 'Anthropic',
      model: 'claude-3-5-sonnet',
      project: 'Developer Assistant',
      projectIconType: 'code',
      timestamp: _StaticTime.time2,
      timeDisplay: '10:38:02',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 3850,
      outputTokens: 1240,
      totalTokens: 5090,
      cost: 0.0385,
      latencyMs: 680,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview:
          'Refactor đoạn mã TypeScript quản lý state của session sang cấu trúc Repository Pattern và Dependency Injection.',
      responsePreview:
          'Tôi đã tái cấu trúc đoạn code: tách AuthRepository interface, triển khai PrismaAuthRepository và inject vào AuthService qua constructor...',
      apiEndpoint: 'https://api.anthropic.com/v1/messages',
    ),

    // 3. Google Gemini 1.5 Pro
    UsageRecord(
      id: 'rec_01hk8a94o6d',
      promptId: 'pmt_77208d6a',
      provider: 'Google Gemini',
      model: 'gemini-1.5-pro',
      project: 'Content Generator',
      projectIconType: 'edit',
      timestamp: _StaticTime.time3,
      timeDisplay: '10:25:40',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 8500,
      outputTokens: 1100,
      totalTokens: 9600,
      cost: 0.0142,
      latencyMs: 310,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview:
          'Tóm tắt tài liệu báo cáo nghiên cứu quy chuẩn thiết kế Mobile App 2026 và đưa ra 5 xu hướng trải nghiệm người dùng nổi bật.',
      responsePreview:
          'Báo cáo tóm tắt 5 xu hướng UX/UI hàng đầu 2026:\n1. Micro-interactions nhạy bén theo ngữ cảnh\n2. Dark/Light mode thích ứng theo ánh sáng môi trường...',
      apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro',
    ),

    // 4. OpenAI GPT-4o (LỖI - 429 Rate Limit)
    UsageRecord(
      id: 'rec_01hk8a95p7e',
      promptId: 'pmt_66197c59',
      provider: 'OpenAI',
      model: 'gpt-4o',
      project: 'Chatbot Support',
      projectIconType: 'folder',
      timestamp: _StaticTime.time4,
      timeDisplay: '09:55:18',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 450,
      outputTokens: 0,
      totalTokens: 450,
      cost: 0.0000,
      latencyMs: 120,
      statusCode: 429,
      statusMessage: 'Lỗi Rate Limit (429)',
      isSuccess: false,
      errorMessage:
          'Rate limit exceeded: 500 requests per minute (RPM). Quota sẽ tự động làm mới sau 20 giây. Vui lòng kiểm tra gói hạn mức tổ chức.',
      promptPreview:
          'Kiểm tra tình trạng đơn hàng mã vận chuyển GHN_998124 và gửi tin nhắn cập nhật cho người nhận.',
      responsePreview:
          '{"error": {"message": "Rate limit reached for model gpt-4o", "type": "tokens", "param": null, "code": "rate_limit_exceeded"}}',
      apiEndpoint: 'https://api.openai.com/v1/chat/completions',
    ),

    // 5. Google Gemini 1.5 Flash
    UsageRecord(
      id: 'rec_01hk8a96q8f',
      promptId: 'pmt_55086b48',
      provider: 'Google Gemini',
      model: 'gemini-1.5-flash',
      project: 'Content Generator',
      projectIconType: 'edit',
      timestamp: _StaticTime.time5,
      timeDisplay: '09:30:12',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 2200,
      outputTokens: 420,
      totalTokens: 2620,
      cost: 0.0018,
      latencyMs: 290,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview:
          'Viết 3 tiêu đề hấp dẫn cho thông báo đẩy ứng dụng chúc mừng sinh nhật khách hàng thân thiết.',
      responsePreview:
          '1. 🎂 Chúc mừng sinh nhật bạn! Nhận ngay voucher 50K từ TokenScope.\n2. Quà sinh nhật đặc biệt đang chờ bạn mở hộp hôm nay!\n3. Ngày của bạn, ưu đãi của bạn! Giảm 30% toàn bộ gói cước.',
      apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash',
    ),

    // 6. OpenAI GPT-4o-mini (Cho phân trang "Tải thêm")
    UsageRecord(
      id: 'rec_01hk8a97r9g',
      promptId: 'pmt_44975a37',
      provider: 'OpenAI',
      model: 'gpt-4o-mini',
      project: 'Marketing Agent',
      projectIconType: 'robot',
      timestamp: _StaticTime.time6,
      timeDisplay: '09:15:44',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 1100,
      outputTokens: 310,
      totalTokens: 1410,
      cost: 0.0006,
      latencyMs: 210,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview:
          'Phân loại cảm xúc khách hàng trong 5 đoạn đánh giá phản hồi trên App Store.',
      responsePreview:
          'Kết quả phân tích cảm xúc: 4 phản hồi tích cực (5 sao), 1 phản hồi trung lập đề xuất cải tiến tốc độ tải trang.',
      apiEndpoint: 'https://api.openai.com/v1/chat/completions',
    ),

    // 7. Anthropic Claude 3 Haiku
    UsageRecord(
      id: 'rec_01hk8a98s0h',
      promptId: 'pmt_33864c26',
      provider: 'Anthropic',
      model: 'claude-3-haiku',
      project: 'Copilot Backend',
      projectIconType: 'code',
      timestamp: _StaticTime.time7,
      timeDisplay: '08:52:19',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 950,
      outputTokens: 180,
      totalTokens: 1130,
      cost: 0.0004,
      latencyMs: 195,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview: 'Kiểm tra cú pháp chuỗi Regex xác thực ngày sinh theo định dạng YYYY-MM-DD.',
      responsePreview: 'Regex chuẩn xác thực ngày sinh: ^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])\$',
      apiEndpoint: 'https://api.anthropic.com/v1/messages',
    ),

    // 8. Google Gemini 1.5 Pro
    UsageRecord(
      id: 'rec_01hk8a99t1i',
      promptId: 'pmt_22753d15',
      provider: 'Google Gemini',
      model: 'gemini-1.5-pro',
      project: 'RAG Search',
      projectIconType: 'search',
      timestamp: _StaticTime.time8,
      timeDisplay: '08:30:05',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 4200,
      outputTokens: 750,
      totalTokens: 4950,
      cost: 0.0076,
      latencyMs: 440,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview: 'Trích xuất các điều khoản thanh toán từ hợp đồng cung cấp dịch vụ viễn thông.',
      responsePreview: 'Các điều khoản thanh toán chính: Thanh toán chậm nhất 15 ngày kể từ ngày xuất hóa đơn...',
      apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro',
    ),

    // 9. OpenAI GPT-4o
    UsageRecord(
      id: 'rec_01hk8a9au2j',
      promptId: 'pmt_11642e04',
      provider: 'OpenAI',
      model: 'gpt-4o',
      project: 'Developer Assistant',
      projectIconType: 'code',
      timestamp: _StaticTime.time9,
      timeDisplay: '08:14:22',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 3100,
      outputTokens: 890,
      totalTokens: 3990,
      cost: 0.0245,
      latencyMs: 510,
      statusCode: 200,
      statusMessage: 'Thành công (200 OK)',
      isSuccess: true,
      promptPreview: 'Tạo migration SQL Server thêm cột `revokedAt` vào bảng `sessions`.',
      responsePreview: 'ALTER TABLE [sessions] ADD [revokedAt] DATETIME2 NULL;',
      apiEndpoint: 'https://api.openai.com/v1/chat/completions',
    ),

    // 10. Anthropic Claude 3.5 Sonnet (LỖI 500)
    UsageRecord(
      id: 'rec_01hk8a9bv3k',
      promptId: 'pmt_00531f93',
      provider: 'Anthropic',
      model: 'claude-3-5-sonnet',
      project: 'Developer Assistant',
      projectIconType: 'code',
      timestamp: _StaticTime.time10,
      timeDisplay: '07:45:10',
      dateDisplay: 'Hôm nay (15/10)',
      inputTokens: 1800,
      outputTokens: 0,
      totalTokens: 1800,
      cost: 0.0000,
      latencyMs: 950,
      statusCode: 500,
      statusMessage: 'Lỗi máy chủ (500 Internal Error)',
      isSuccess: false,
      errorMessage: 'Anthropic API overload: Nhà cung cấp đang gặp sự cố quá tải tạm thời.',
      promptPreview: 'Chạy phân tích hiệu năng thuật toán tìm kiếm đồ thị A*.',
      responsePreview: '{"error": {"type": "api_error", "message": "Internal server error"}}',
      apiEndpoint: 'https://api.anthropic.com/v1/messages',
    ),
  ];

  @override
  Future<List<UsageRecord>> getRecords({
    String? searchQuery,
    String? provider,
    String? timeRange,
    int offset = 0,
    int limit = 5,
  }) async {
    await Future<void>.delayed(simulateDelay);

    if (shouldFail) {
      throw Exception('Không thể tải lịch sử sử dụng. Vui lòng kiểm tra kết nối mạng.');
    }

    var list = _filterList(searchQuery: searchQuery, provider: provider, timeRange: timeRange);

    if (offset >= list.length) {
      return [];
    }

    final end = (offset + limit < list.length) ? offset + limit : list.length;
    return list.sublist(offset, end);
  }

  @override
  Future<int> getTotalCount({
    String? searchQuery,
    String? provider,
    String? timeRange,
  }) async {
    final list = _filterList(searchQuery: searchQuery, provider: provider, timeRange: timeRange);
    // Nếu không có bộ lọc tìm kiếm và đang ở "Tất cả", trả về 1.482 như trên giao diện Figma.
    if ((searchQuery == null || searchQuery.trim().isEmpty) &&
        (provider == null || provider == 'all' || provider == 'Tất cả')) {
      return 1482;
    }
    return list.length;
  }

  @override
  Future<UsageRecord?> getRecordById(String id) async {
    await Future<void>.delayed(simulateDelay);
    try {
      return _mockDatabase.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<UsageRecord> _filterList({
    String? searchQuery,
    String? provider,
    String? timeRange,
  }) {
    var filtered = _mockDatabase;

    // Lọc theo Provider
    if (provider != null && provider != 'all' && provider != 'Tất cả') {
      final pLower = provider.toLowerCase();
      filtered = filtered.where((r) {
        if (pLower.contains('openai')) return r.provider.toLowerCase().contains('openai');
        if (pLower.contains('gemini')) return r.provider.toLowerCase().contains('gemini');
        if (pLower.contains('anthropic')) return r.provider.toLowerCase().contains('anthropic');
        return r.provider.toLowerCase().contains(pLower);
      }).toList();
    }

    // Lọc theo Search Query
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      filtered = filtered.where((r) {
        return r.promptId.toLowerCase().contains(query) ||
            r.model.toLowerCase().contains(query) ||
            r.project.toLowerCase().contains(query) ||
            r.provider.toLowerCase().contains(query) ||
            r.promptPreview.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}

class _StaticTime {
  static final DateTime time1 = DateTime(2026, 10, 15, 10, 42, 15);
  static final DateTime time2 = DateTime(2026, 10, 15, 10, 38, 2);
  static final DateTime time3 = DateTime(2026, 10, 15, 10, 25, 40);
  static final DateTime time4 = DateTime(2026, 10, 15, 9, 55, 18);
  static final DateTime time5 = DateTime(2026, 10, 15, 9, 30, 12);
  static final DateTime time6 = DateTime(2026, 10, 15, 9, 15, 44);
  static final DateTime time7 = DateTime(2026, 10, 15, 8, 52, 19);
  static final DateTime time8 = DateTime(2026, 10, 15, 8, 30, 5);
  static final DateTime time9 = DateTime(2026, 10, 15, 8, 14, 22);
  static final DateTime time10 = DateTime(2026, 10, 15, 7, 45, 10);
}
