import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/app.dart';

/// Dùng mock service để test không phụ thuộc backend.
const testApp = TokenScopeApp(useMockService: true);

void main() {
  testWidgets('Hiển thị màn hình đăng nhập với nội dung chuẩn', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp);

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Tiếp tục với GitHub'), findsOneWidget);
  });

  testWidgets('Chuyển sang màn hình đăng ký', (WidgetTester tester) async {
    await tester.pumpWidget(testApp);

    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản'), findsAtLeastNWidgets(1));
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
  });

  testWidgets('Chuyển sang màn hình quên mật khẩu', (WidgetTester tester) async {
    await tester.pumpWidget(testApp);

    await tester.ensureVisible(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();

    expect(find.text('Quên mật khẩu'), findsAtLeastNWidgets(1));
    expect(find.text('Gửi liên kết đặt lại'), findsOneWidget);
  });

  testWidgets('Đăng nhập thành công chuyển tới màn hình tổng quan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'demo@tokenscope.io');
    await tester.enterText(fields.at(1), '123456');

    await tester.ensureVisible(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Xin chào, Minh Anh'), findsOneWidget);
    expect(find.text('Tổng token tháng này'), findsOneWidget);
    expect(find.text('Tổng quan'), findsWidgets);

    // Cuộn xuống để thấy phần phân bổ nhà cung cấp.
    await tester.scrollUntilVisible(
      find.text('Phân bổ theo nhà cung cấp'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Phân bổ theo nhà cung cấp'), findsOneWidget);
  });

  testWidgets('Đăng nhập sai mật khẩu hiển thị thông báo lỗi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'demo@tokenscope.io');
    await tester.enterText(fields.at(1), 'sai-mat-khau');

    await tester.ensureVisible(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
  });

  testWidgets('Đăng ký báo lỗi khi mật khẩu không khớp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp);

    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Nguyen Van A');
    await tester.enterText(fields.at(1), 'a@b.com');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '654321');
    await tester.ensureVisible(find.text('Tạo tài khoản').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo tài khoản').last);
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
  });

  testWidgets('Đăng ký báo lỗi khi chưa chọn ngày sinh', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp);

    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Nguyen Van A');
    await tester.enterText(fields.at(1), 'a@b.com');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '123456');
    await tester.ensureVisible(find.text('Tạo tài khoản').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo tài khoản').last);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng chọn ngày sinh.'), findsOneWidget);
  });

  testWidgets('Màn hình đăng ký có trường ngày sinh', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp);

    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Ngày sinh'), findsOneWidget);
    expect(find.text('Chọn ngày sinh'), findsOneWidget);
  });
}
