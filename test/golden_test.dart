import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/app.dart';
import 'package:tokenscope/providers/auth_controller.dart';

import 'helpers/fake_controllers.dart';
import 'helpers/fake_services.dart';
import 'helpers/font_loader.dart';
import 'helpers/mock_auth_service.dart';

/// Sinh ảnh giao diện ở kích thước màn hình điện thoại để kiểm tra thị giác.
void main() {
  const surfaceSize = Size(390, 844);

  setUpAll(loadInterFonts);

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = surfaceSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TokenScopeApp(
        authController: AuthController(service: MockAuthService()),
        dashboardController: buildFakeDashboardController(),
        historyController: buildFakeHistoryController(),
        budgetController: buildFakeBudgetController(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Ảnh màn hình đăng nhập', (WidgetTester tester) async {
    await pumpApp(tester);
    await expectLater(
      find.byType(TokenScopeApp),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('Ảnh màn hình đăng ký', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TokenScopeApp),
      matchesGoldenFile('goldens/register.png'),
    );
  });

  testWidgets('Ảnh màn hình quên mật khẩu', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TokenScopeApp),
      matchesGoldenFile('goldens/forgot_password.png'),
    );
  });

  testWidgets('Ảnh màn hình tổng quan sau đăng nhập', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'demo@tokenscope.io');
    await tester.enterText(fields.at(1), '123456');
    await tester.ensureVisible(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(
      find.byType(TokenScopeApp),
      matchesGoldenFile('goldens/dashboard.png'),
    );
  });
}
