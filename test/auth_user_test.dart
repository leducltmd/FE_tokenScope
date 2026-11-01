import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/services/auth_service.dart';

/// Kiểm tra cách hiển thị tên người dùng trên dashboard.
void main() {
  group('AuthUser.displayName', () {
    test('lấy họ tên khi có', () {
      const user = AuthUser(name: 'Nguyễn Minh Anh', email: 'a@b.com');
      expect(user.displayName, 'Nguyễn Minh Anh');
    });

    test('fallback sang email khi không có họ tên', () {
      const user = AuthUser(email: 'minhanh@tokenscope.io');
      expect(user.displayName, 'minhanh');
    });

    test('fallback sang "bạn" khi không có gì', () {
      const user = AuthUser();
      expect(user.displayName, 'bạn');
    });
  });

  group('AuthUser.shortName — tên đệm + tên', () {
    test('ba từ: bỏ phần họ', () {
      const user = AuthUser(name: 'Nguyễn Minh Anh');
      expect(user.shortName, 'Minh Anh');
    });

    test('bốn từ: bỏ cả họ và tên đệm thứ', () {
      const user = AuthUser(name: 'Nguyễn Văn Minh Anh');
      expect(user.shortName, 'Minh Anh');
    });

    test('hai từ: giữ nguyên', () {
      const user = AuthUser(name: 'Minh Anh');
      expect(user.shortName, 'Minh Anh');
    });

    test('một từ: giữ nguyên', () {
      const user = AuthUser(name: 'Minh');
      expect(user.shortName, 'Minh');
    });

    test('bỏ khoảng trắng thừa giữa các từ', () {
      const user = AuthUser(name: '  Nguyễn   Minh   Anh  ');
      expect(user.shortName, 'Minh Anh');
    });
  });

  group('AuthUser.fromJson', () {
    test('đọc đủ thông tin từ JSON của backend', () {
      final user = AuthUser.fromJson({
        'id': 'abc-123',
        'email': 'minhanh@tokenscope.io',
        'name': 'Nguyễn Minh Anh',
        'birthDate': '1995-05-20T00:00:00.000Z',
        'avatarUrl': null,
      });

      expect(user.id, 'abc-123');
      expect(user.email, 'minhanh@tokenscope.io');
      expect(user.name, 'Nguyễn Minh Anh');
      expect(user.birthDate, '1995-05-20');
      expect(user.shortName, 'Minh Anh');
    });

    test('birthDate null vẫn parse được', () {
      final user = AuthUser.fromJson({'name': 'Minh Anh'});
      expect(user.birthDate, isNull);
    });
  });
}
