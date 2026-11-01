import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/providers/auth_controller.dart';
import 'package:tokenscope/services/api_auth_service.dart';

/// Kiểm thử tích hợp thật với backend TokenScope đang chạy.
///
/// Bỏ qua nếu backend không khởi động tại http://localhost:3000.
void main() {
  final service = ApiAuthService(
    config: const ApiConfig(baseUrl: 'http://localhost:3000/api'),
  );

  Future<bool> backendAvailable() async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('http://localhost:3000/api/health'));
      final res = await req.close();
      await res.drain<void>();
      client.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  group('Tích hợp API thật', () {
    late bool available;

    setUpAll(() async {
      available = await backendAvailable();
      if (!available) {
        // ignore: avoid_print
        print('⚠ Backend không chạy — bỏ qua nhóm test tích hợp.');
      }
    });

    test('đăng nhập tài khoản demo trả về token và thông tin user', () async {
      if (!available) return;

      final controller = AuthController(service: service);
      final ok = await controller.login(
        email: 'demo@tokenscope.io',
        password: '123456',
      );

      expect(ok, isTrue);
      expect(controller.token, isNotNull);
      expect(controller.token, isNotEmpty);
      expect(controller.error, isNull);
    });

    test('đăng nhập sai mật khẩu báo lỗi INVALID_CREDENTIALS', () async {
      if (!available) return;

      final controller = AuthController(service: service);
      final ok = await controller.login(
        email: 'demo@tokenscope.io',
        password: 'mat-khau-sai',
      );

      expect(ok, isFalse);
      expect(controller.error, 'Email hoặc mật khẩu không đúng.');
      expect(controller.errorCode, 'INVALID_CREDENTIALS');
    });

    test('đăng ký email đã tồn tại báo lỗi EMAIL_ALREADY_EXISTS', () async {
      if (!available) return;

      final controller = AuthController(service: service);
      final ok = await controller.register(
        name: 'Test User',
        birthDate: '1995-05-20',
        email: 'demo@tokenscope.io',
        password: 'Abc12345',
      );

      expect(ok, isFalse);
      expect(controller.errorCode, 'EMAIL_ALREADY_EXISTS');
    });

    test('đăng ký email mới thành công', () async {
      if (!available) return;

      final email =
          'flutter.test.${DateTime.now().millisecondsSinceEpoch}@tokenscope.io';
      final controller = AuthController(service: service);
      final ok = await controller.register(
        name: 'Flutter Test',
        birthDate: '1995-05-20',
        email: email,
        password: 'Abc12345',
      );

      expect(ok, isTrue);
      expect(controller.token, isNotNull);
      expect(controller.user?.birthDate, '1995-05-20');
      expect(controller.displayName, 'Flutter Test');
    });

    test('đăng ký thiếu ngày sinh bị từ chối', () async {
      if (!available) return;

      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('http://localhost:3000/api/auth/register'),
      );
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode({
          'name': 'Thieu Ngay Sinh',
          'email':
              'flutter.nodate.${DateTime.now().millisecondsSinceEpoch}@tokenscope.io',
          'password': 'Abc12345',
        }),
      );
      final res = await req.close();
      final body = jsonDecode(await res.transform(utf8.decoder).join())
          as Map<String, dynamic>;

      expect(res.statusCode, 400);
      expect(body['message'], isNotEmpty);

      client.close();
    });

    test('quên mật khẩu luôn trả về thành công', () async {
      if (!available) return;

      final controller = AuthController(service: service);
      final ok = await controller.forgotPassword('demo@tokenscope.io');

      expect(ok, isTrue);
    });

    test('body trả về có đúng cấu trúc JSON', () async {
      if (!available) return;

      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('http://localhost:3000/api/auth/login'),
      );
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'email': 'demo@tokenscope.io', 'password': '123456'}));
      final res = await req.close();
      final body = jsonDecode(await res.transform(utf8.decoder).join())
          as Map<String, dynamic>;

      expect(res.statusCode, 200);
      expect(body['accessToken'], isA<String>());
      expect(body['refreshToken'], isA<String>());
      expect(body['expiresIn'], 900);
      expect(body['tokenType'], 'Bearer');
      expect((body['user'] as Map<String, dynamic>)['email'], 'demo@tokenscope.io');

      client.close();
    });
  });
}
