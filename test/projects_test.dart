import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/theme/app_theme.dart';
import 'package:tokenscope/screens/projects/projects_screen.dart';

import 'helpers/fake_controllers.dart';
import 'helpers/font_loader.dart';

/// Kiểm thử màn hình "Quản lý dự án".
void main() {
  const surfaceSize = Size(390, 844);

  setUpAll(loadInterFonts);

  Widget wrap() {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ProjectsScreen(controller: buildFakeProjectsController()),
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
    expect(find.text('Quản lý dự án'), findsOneWidget);
    expect(
      find.text('Giám sát mức tiêu thụ token & chi phí LLM'),
      findsOneWidget,
    );

    // Ô tìm kiếm.
    expect(find.text('Tìm kiếm dự án...'), findsOneWidget);

    // Bộ lọc.
    expect(find.text('Tất cả'), findsOneWidget);
    // "Đang chạy" xuất hiện ở huy hiệu trạng thái dự án.
    expect(find.text('Đang chạy'), findsAtLeastNWidgets(1));
    expect(find.text('Gần chạm trần (85%+)'), findsOneWidget);

    // Thẻ tóm tắt — số liệu lấy từ backend (fake service trong test).
    expect(find.text('Tổng quan tiêu thụ'), findsOneWidget);
    final now = DateTime.now();
    expect(
      find.text('Tháng ${now.month}/${now.year} · 3 dự án đang chạy'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('TỔNG CHI PHÍ'), findsOneWidget);
    expect(find.text('LƯỢNG TOKEN ĐÃ DÙNG'), findsOneWidget);
    expect(find.text('\$34.80'), findsOneWidget);
    expect(find.text('2.450.000'), findsOneWidget);
    expect(find.text('Còn lại \$12.20 USD'), findsOneWidget);
    // Phân bổ theo dự án.
    expect(find.text('Chatbot Support (55%)'), findsOneWidget);
    expect(find.text('Content Generator (28%)'), findsOneWidget);
    expect(find.text('Developer Assistant (16%)'), findsOneWidget);

    // Điều hướng dưới.
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Ngân sách'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
  });

  testWidgets('cuộn xuống thấy danh sách dự án', (WidgetTester tester) async {
    tester.view.physicalSize = surfaceSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Danh sách dự án'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Danh sách dự án'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Chatbot Support'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Chatbot Support'), findsOneWidget);
    expect(find.text('Hỗ trợ khách hàng tự động 24/7'), findsOneWidget);
    expect(find.text('Production'), findsOneWidget);
    expect(find.text('1.350.000'), findsOneWidget);
    expect(find.text('\$21.50 / \$25.00'), findsOneWidget);
    // "86%" xuất hiện ở cột phần trăm mức hạn và ở thang tiêu trình.
    expect(find.text('86%'), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(
      find.text('Content Generator'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Content Generator'), findsOneWidget);
    expect(find.text('Staging'), findsOneWidget);
    expect(find.text('Thử nghiệm'), findsOneWidget);
  });

  testWidgets('bộ lọc "Gần chạm trần" chỉ giữ dự án vượt 85%',
      (WidgetTester tester) async {
    tester.view.physicalSize = surfaceSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gần chạm trần (85%+)'));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Content Generator'),
      200,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('Content Generator'), findsOneWidget);
    expect(find.text('Developer Assistant'), findsNothing);
  });

  testWidgets('tìm kiếm không có kết quả hiện trạng thái rỗng',
      (WidgetTester tester) async {
    tester.view.physicalSize = surfaceSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy dự án'), findsOneWidget);
  });
}
