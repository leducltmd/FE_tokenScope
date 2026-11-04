import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/theme/app_theme.dart';
import 'package:tokenscope/providers/auth_controller.dart';
import 'package:tokenscope/screens/dashboard/dashboard_screen.dart';

import 'helpers/fake_services.dart';

/// Bọc dashboard trong khung 390 × 844 để mô phỏng thiết bị mobile.
Widget _wrap() {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 844,
        child: DashboardScreen(
          controller: AuthController(),
          dashboardController: buildFakeDashboardController(),
          historyController: buildFakeHistoryController(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Dashboard hiển thị đầy đủ các thành phần chính', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Đầu trang.
    expect(find.text('TokenScope'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Xin chào, Minh Anh'), findsOneWidget);
    expect(find.text('Theo dõi token & chi phí AI đa nền tảng'), findsOneWidget);
    expect(find.text('Đồng bộ 1m trước'), findsOneWidget);

    // Cảnh báo ngân sách.
    expect(find.text('Cảnh báo ngân sách'), findsOneWidget);
    expect(find.text('34.80 USD đã dùng'), findsOneWidget);

    // Thẻ chỉ số nổi bật.
    expect(find.text('2.450.000'), findsOneWidget);
    expect(find.text('\$34.80 USD'), findsOneWidget);

    // Lưới hành động nhanh.
    expect(find.text('Phân tích'), findsOneWidget);
    expect(find.text('Đối tác'), findsOneWidget);
    expect(find.text('Dự án'), findsOneWidget);
    expect(find.text('Cảnh báo'), findsOneWidget);

    // Thanh điều hướng dưới.
    for (final label in ['Tổng quan', 'Lịch sử', 'Ngân sách', 'Cài đặt']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Cuộn xuống thấy biểu đồ, nhà cung cấp và truy vấn gần nhất', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(find.text('Xu hướng sử dụng 7 ngày'), 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(find.text('Xu hướng sử dụng 7 ngày'), findsOneWidget);
    expect(find.text('7 ngày qua'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Phân bổ theo nhà cung cấp'), 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('Google Gemini'), findsOneWidget);
    expect(find.text('Anthropic Claude'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Truy vấn gần nhất'), 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(find.text('claude-3-5-sonnet'), findsOneWidget);
    expect(find.text('Copilot Backend'), findsOneWidget);
    expect(find.text('1.420 tkn'), findsOneWidget);
    expect(find.text('\$0.0042'), findsOneWidget);
  });
}
