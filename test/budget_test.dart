import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/theme/app_theme.dart';
import 'package:tokenscope/screens/budget/budget_screen.dart';

import 'helpers/font_loader.dart';
import 'helpers/fake_controllers.dart';

/// Kiểm thử màn hình "Quản lý ngân sách AI".
void main() {
  const surfaceSize = Size(390, 844);

  setUpAll(loadInterFonts);

  Widget wrap() {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BudgetScreen(controller: buildFakeBudgetController()),
      ),
    );
  }

  testWidgets('hiển thị đầy đủ thành phần chính', (WidgetTester tester) async {
    tester.view.physicalSize = surfaceSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Đầu trang.
    expect(find.text('TokenScope'), findsOneWidget);
    expect(find.text('Quản lý ngân sách AI'), findsOneWidget);
    expect(find.text('CHU KỲ: 01/10 - 31/10'), findsOneWidget);

    // Thẻ hạn mức tổng.
    expect(find.text('Chi phí đã dùng'), findsOneWidget);
    expect(find.text('\$34.80'), findsOneWidget);
    expect(find.text('87.0%'), findsOneWidget);
    expect(find.text('HẠN MỨC'), findsOneWidget);
    expect(find.text('Còn lại \$5.20'), findsOneWidget);

    // Dải cảnh báo.
    expect(
      find.text('CẢNH BÁO: Đã vượt ngưỡng an toàn 80%'),
      findsOneWidget,
    );

    // Thanh tiêu trình.
    expect(find.text('Ngưỡng: \$32.00'), findsOneWidget);
    expect(find.text('Trần: \$40.00'), findsOneWidget);

    // Điều hướng dưới — "Ngân sách" đang chọn.
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Ngân sách'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
  });

  testWidgets('cuộn xuống thấy phân bổ và điều chỉnh ngân sách', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = surfaceSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;

    // Dự báo chi tiêu.
    await tester.scrollUntilVisible(
      find.text('Dự báo chi tiêu AI cuối tháng'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Dự báo chi tiêu AI cuối tháng'), findsOneWidget);

    // Công tắc giới hạn rate-limit.
    expect(find.text('Bật tự động giới hạn Rate-limit'), findsOneWidget);

    // Phân bổ theo nhà cung cấp.
    await tester.scrollUntilVisible(
      find.text('OpenAI API'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('OpenAI API'), findsOneWidget);
    expect(find.text('Anthropic Claude'), findsOneWidget);
    expect(find.text('Google Gemini'), findsOneWidget);

    // Điều chỉnh ngân sách & lịch sử thanh toán.
    await tester.scrollUntilVisible(
      find.text('Lưu ngân sách'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lưu ngân sách'), findsOneWidget);
    expect(
      find.text('Xem lịch sử chu kỳ thanh toán trước'),
      findsOneWidget,
    );
  });

  testWidgets('chuyển tab phân bổ sang theo dự án', (WidgetTester tester) async {
    tester.view.physicalSize = surfaceSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Theo dự án (3)'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Theo dự án (3)'));
    await tester.pumpAndSettle();

    expect(find.text('Copilot Backend'), findsOneWidget);
    expect(find.text('Marketing Agent'), findsOneWidget);
    expect(find.text('RAG Search'), findsOneWidget);
  });
}
