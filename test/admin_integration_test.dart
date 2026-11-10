import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tokenscope/services/api_client.dart';
import 'package:tokenscope/services/api_config.dart';
import 'package:tokenscope/services/app_usage_service.dart';
import 'package:tokenscope/services/crash_test_client.dart';

/// Địa chỉ backend TokenScope cho test tích hợp.
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api',
);

/// Client HTTP dùng chung cho các test.
http.Client gClient = http.Client();

/// Tạo một ApiClient trỏ về backend thật.
///
/// [tokenProvider] được gọi mỗi khi gửi request nên có thể thay đổi token
/// giữa chừng — mô phỏng đúng trạng thái app trước/sau khi đăng nhập.
ApiClient createClient({String? token, String? Function()? tokenProvider}) {
  return ApiClient(
    config: const ApiConfig(urls: [kBaseUrl]),
    client: gClient,
    tokenProvider: tokenProvider ?? (() => token),
  );
}

/// Đăng nhập với tài khoản demo để lấy access token.
Future<String> loginAdmin() async {
  final response = await gClient.post(
    Uri.parse('$kBaseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'demo@tokenscope.io',
      'password': '123456',
    }),
  );

  expect(response.statusCode, 200, reason: 'Đăng nhập thất bại');
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  return body['accessToken'] as String;
}

void main() {
  group('AppUsageService — ghi nhận sự kiện ứng dụng', () {
    test('gửi sự kiện app_open lên backend thành công', () async {
      final service = AppUsageService(client: createClient());
      service.startSession(userId: null);
      await service.logAppOpen(platform: 'flutter_test', appVersion: '1.0.0+1');

      // Không throw => sự kiện đã được gửi và backend đã ghi nhận.
      expect(service.sessionId, isNotNull);
    });

    test('ghi nhận sự kiện tính năng không làm hỏng app khi backend lỗi', () async {
      // Trỏ sai cổng để mô phỏng backend không chạy.
      final service = AppUsageService(
        client: ApiClient(
          config: const ApiConfig(urls: ['http://localhost:59999/api']),
          client: gClient,
        ),
      );

      service.startSession(userId: null);
      // Không ném exception — lỗi thống kê phải bị nuốt.
      await expectLater(
        service.logFeatureUsage('test_feature', screen: 'test_screen'),
        completes,
      );
    });

    test('app_open trước khi đăng nhập được gắn userId sau khi đăng nhập', () async {
      final token = await loginAdmin();
      final userId = '4d9eb581-de22-4f53-b39b-025798f3f376';

      // Mô phỏng đúng vòng đời thật: app khởi động (chưa có token) → ghi
      // app_open → người dùng đăng nhập (token xuất hiện) → setUserId.
      // `tokenHolder` được cập nhật đúng lúc đăng nhập thành công.
      String? tokenHolder;
      final service = AppUsageService(
        client: createClient(tokenProvider: () => tokenHolder),
      );

      // 1. App khởi động khi CHƯA đăng nhập → sự kiện ghi với userId = null.
      service.startSession(userId: null);
      await service.logAppOpen(platform: 'flutter_test', appVersion: '1.0.0+1');
      final sessionId = service.sessionId;

      // 2. Người dùng đăng nhập → token có sẵn, app gọi setUserId.
      //    Backend gắn userId vào bản ghi cũ (không tạo bản ghi mới).
      tokenHolder = token;
      await service.setUserId(userId);

      // 3. Truy vấn danh sách người dùng để xác nhận sự kiện đã có userId.
      final response = await gClient.get(
        Uri.parse('$kBaseUrl/admin/users?search=demo@tokenscope.io&limit=10'),
        headers: {'Authorization': 'Bearer $token'},
      );
      expect(response.statusCode, 200);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final users = (body['users'] as List<dynamic>).cast<Map<String, dynamic>>();
      final me = users.firstWhere((u) => u['id'] == userId);

      expect(me['usageCount'], greaterThan(0));
      expect(me['appOpenCount'], greaterThan(0));

      // 4. Không tạo bản ghi trùng — số lượt mở app không tăng gấp đôi.
      final before = me['appOpenCount'] as int;
      await service.setUserId(userId);
      final response2 = await gClient.get(
        Uri.parse('$kBaseUrl/admin/users?search=demo@tokenscope.io&limit=10'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body2 = jsonDecode(response2.body) as Map<String, dynamic>;
      final me2 = (body2['users'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((u) => u['id'] == userId);
      expect(me2['appOpenCount'], before);

      expect(sessionId, isNotNull);
    });
  });

  group('CrashTestClient — luồng crash test', () {
    test('đăng ký thiết bị và polling nhận yêu cầu crash', () async {
      final adminToken = await loginAdmin();

      final client = CrashTestClient(client: createClient());

      // 1. Admin tạo yêu cầu crash trước khi app polling.
      final createResponse = await gClient.post(
        Uri.parse('$kBaseUrl/crash-testing/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: jsonEncode({'reason': 'Flutter integration test'}),
      );
      expect(createResponse.statusCode, 201);
      final requestId =
          (jsonDecode(createResponse.body) as Map<String, dynamic>)['request']['id']
              as String;

      // 2. App polling — endpoint poll là public (không cần token).
      final pollResponse = await gClient.get(
        Uri.parse('$kBaseUrl/crash-testing/poll?deviceId=${client.deviceId}'),
      );
      expect(pollResponse.statusCode, 200);

      final requests =
          (jsonDecode(pollResponse.body) as Map<String, dynamic>)['requests']
              as List<dynamic>;
      expect(requests, isNotEmpty, reason: 'App phải nhận được yêu cầu crash');
      expect(requests.first['id'], requestId);
      expect(requests.first['status'], 'triggered');

      // 3. App báo cáo lại trạng thái 'reported'.
      final reportResponse = await gClient.post(
        Uri.parse('$kBaseUrl/crash-testing/requests/$requestId/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'reported',
          'result': 'Da ghi nhan log Crashlytics.',
        }),
      );
      expect(reportResponse.statusCode, 200);

      final reported =
          (jsonDecode(reportResponse.body) as Map<String, dynamic>)['request']
              as Map<String, dynamic>;
      expect(reported['status'], 'reported');
      expect(reported['reportedAt'], isNotNull);
    });

    test('deviceId ổn định qua nhiều lần gọi', () {
      final a = CrashTestClient(client: createClient());
      final b = CrashTestClient(client: createClient());

      expect(a.deviceId, isNotEmpty);
      expect(a.deviceId, startsWith('flutter-device-'));
      expect(a.deviceId, isNot(b.deviceId));
    });
  });
}
