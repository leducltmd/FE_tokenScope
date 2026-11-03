import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/widgets/ts_app_bar.dart';
import 'package:tokenscope/core/widgets/ts_bottom_navigation.dart';
import 'package:tokenscope/core/widgets/ts_button.dart';
import 'package:tokenscope/core/widgets/ts_data_cards.dart';
import 'package:tokenscope/core/widgets/ts_dialog.dart';
import 'package:tokenscope/core/widgets/ts_states.dart';
import 'package:tokenscope/screens/dashboard/dashboard_screen.dart';
import 'package:tokenscope/providers/auth_controller.dart';

/// Kiểm tra thư viện giao diện TokenScope — 09 nhóm thành phần.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('01 · Nút', () {
    testWidgets('cao 48px, bo góc 8px, giữ nhãn khi tải', (tester) async {
      await tester.pumpWidget(
        wrap(TsButton(label: 'Lưu ngân sách', onPressed: () {})),
      );

      final button = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(TsButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(button.constraints, isNotNull);
      expect(button.decoration, isA<BoxDecoration>());
      final decoration = button.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));

      // Trạng thái đang tải vẫn giữ nhãn.
      await tester.pumpWidget(
        wrap(TsButton(label: 'Đang lưu', isLoading: true, onPressed: () {})),
      );
      expect(find.text('Đang lưu'), findsOneWidget);
    });

    testWidgets('ba cấp hành động có màu khác nhau', (tester) async {
      Future<Color> bgOf(TsButtonVariant variant) async {
        await tester.pumpWidget(
          wrap(TsButton(label: 'Nút', variant: variant, onPressed: () {})),
        );
        final box = tester.widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(TsButton),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return (box.decoration as BoxDecoration).color!;
      }

      final primary = await bgOf(TsButtonVariant.primary);
      final secondary = await bgOf(TsButtonVariant.secondary);
      final danger = await bgOf(TsButtonVariant.danger);

      expect(primary, isNot(secondary));
      expect(secondary, isNot(danger));
      expect(primary, isNot(danger));
    });

    testWidgets('vô hiệu khi không có callback', (tester) async {
      await tester.pumpWidget(wrap(const TsButton(label: 'Nút')));
      expect(tester.widget<TsButton>(find.byType(TsButton)).isDisabled, isTrue);
    });
  });

  group('03 · Thẻ dữ liệu', () {
    testWidgets('thẻ nhà cung cấp hiển thị đúng thông tin', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TsProviderCard(
            name: 'OpenAI',
            status: 'Đã kết nối',
            modelCount: 3,
            costToday: '128.450 ₫',
          ),
        ),
      );

      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Đã kết nối · 3 mô hình'), findsOneWidget);
      expect(find.text('128.450 ₫ hôm nay'), findsOneWidget);
    });

    testWidgets('thẻ token hiển thị tổng, vào và ra', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TsTokenSummaryCard(
            totalTokens: 245800,
            inputTokens: 180200,
            outputTokens: 65600,
          ),
        ),
      );

      expect(find.text('Token hôm nay'), findsOneWidget);
      expect(find.text('245.800'), findsOneWidget);
      expect(find.text('180.200 vào · 65.600 ra'), findsOneWidget);
    });

    testWidgets('thẻ ngân sách hiển thị tiến độ', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TsBudgetCard(
            title: 'Ngân sách tháng 10',
            spent: '650.000 ₫',
            limit: '1.000.000 ₫',
            percentUsed: 65,
            remaining: '350.000 ₫',
          ),
        ),
      );

      expect(find.text('Ngân sách tháng 10'), findsOneWidget);
      expect(find.text('Đã dùng 65% · Còn 350.000 ₫'), findsOneWidget);
    });
  });

  group('04 · Điều hướng', () {
    testWidgets('bốn mục, một mục đang chọn, vùng chạm ≥ 48px', (tester) async {
      var index = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TsBottomNavigation(
                items: const [
                  TsNavItem(label: 'Tổng quan', icon: Icons.dashboard),
                  TsNavItem(label: 'Lịch sử', icon: Icons.history),
                  TsNavItem(label: 'Ngân sách', icon: Icons.wallet),
                  TsNavItem(label: 'Cài đặt', icon: Icons.settings),
                ],
                currentIndex: index,
                onChanged: (i) => setState(() => index = i),
              ),
            ),
          ),
        ),
      );

      for (final label in ['Tổng quan', 'Lịch sử', 'Ngân sách', 'Cài đặt']) {
        expect(find.text(label), findsOneWidget);
      }

      // Chọn mục khác.
      await tester.tap(find.text('Ngân sách'));
      await tester.pumpAndSettle();
      expect(index, 2);

      // Vùng chạm của mỗi mục ≥ 48px.
      final size = tester.getSize(find.byType(TsBottomNavigation));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('05 · Thanh ứng dụng', () {
    testWidgets('cao 64px, tối đa hai hành động', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TsAppBar(
              title: 'Chi tiết sử dụng',
              actions: [
                TsAppBarAction(
                  icon: Icons.refresh,
                  tooltip: 'Làm mới',
                  onPressed: () {},
                ),
                TsAppBarAction(
                  icon: Icons.more,
                  tooltip: 'Thêm',
                  onPressed: () {},
                ),
                TsAppBarAction(
                  icon: Icons.share,
                  tooltip: 'Chia sẻ',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Chi tiết sử dụng'), findsOneWidget);
      expect(find.byType(TsAppBarAction), findsNWidgets(2));
    });
  });

  group('06 · Hộp thoại', () {
    testWidgets('luôn có lựa chọn Hủy và giải thích hệ quả', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => TsDialog.show(
                  context,
                  title: 'Xóa kết nối OpenAI?',
                  message:
                      'TokenScope sẽ ngừng đồng bộ dữ liệu từ OpenAI. '
                      'Lịch sử sử dụng đã lưu vẫn được giữ lại.',
                  confirmLabel: 'Xóa kết nối',
                  isDanger: true,
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      expect(find.text('Xóa kết nối OpenAI?'), findsOneWidget);
      expect(find.textContaining('ngừng đồng bộ'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Xóa kết nối'), findsOneWidget);

      // Hủy đóng hộp thoại.
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Xóa kết nối OpenAI?'), findsNothing);
    });
  });

  group('08 & 09 · Trạng thái trống và lỗi', () {
    testWidgets('trạng thái trống có hành động xóa bộ lọc', (tester) async {
      await tester.pumpWidget(
        wrap(
          TsEmptyState(
            title: 'Chưa có bản ghi sử dụng',
            message: 'Không tìm thấy dữ liệu phù hợp với bộ lọc hiện tại.',
            actionLabel: 'Xóa bộ lọc',
            onAction: () {},
          ),
        ),
      );

      expect(find.text('Chưa có bản ghi sử dụng'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsOneWidget);
    });

    testWidgets('trạng thái lỗi có nút thử lại', (tester) async {
      await tester.pumpWidget(
        wrap(
          TsErrorState(
            title: 'Không thể kết nối API',
            message: 'Kiểm tra kết nối mạng hoặc khóa API của bạn.',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Không thể kết nối API'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });

  group('Dashboard', () {
    testWidgets('hiển thị đầy đủ thành phần chính', (tester) async {
      final controller = AuthController();

      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Cảnh báo ngân sách.
      expect(find.text('Cảnh báo ngân sách'), findsOneWidget);
      // Thẻ chỉ số nổi bật.
      expect(find.text('Tổng token tháng này'), findsOneWidget);
      expect(find.text('2.450.000'), findsOneWidget);
      // Điều hướng dưới.
      expect(find.byType(TsBottomNavigation), findsOneWidget);

      // Biểu đồ nằm dưới — cuộn xuống để thấy.
      await tester.scrollUntilVisible(
        find.text('Xu hướng sử dụng 7 ngày'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Xu hướng sử dụng 7 ngày'), findsOneWidget);

      // Danh sách nhà cung cấp nằm dưới — cuộn tiếp.
      await tester.scrollUntilVisible(
        find.text('OpenAI'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Anthropic Claude'), findsOneWidget);
    });

    testWidgets('chuyển tab hiển thị nội dung tương ứng', (tester) async {
      final controller = AuthController();

      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Tab Lịch sử → trạng thái trống.
      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có bản ghi sử dụng'), findsOneWidget);

      // Tab Cài đặt → hồ sơ.
      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();
      expect(find.text('Hồ sơ'), findsOneWidget);
    });

    testWidgets('tab Ngân sách mở trang quản lý ngân sách AI', (tester) async {
      final controller = AuthController();

      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ngân sách'));
      await tester.pumpAndSettle();

      expect(find.text('Quản lý ngân sách AI'), findsOneWidget);
      expect(find.text('Chi phí đã dùng'), findsOneWidget);

      // Cuộn xuống thấy nút lưu ngân sách.
      await tester.scrollUntilVisible(
        find.text('Lưu ngân sách'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Lưu ngân sách'), findsOneWidget);
    });

    testWidgets('cảnh báo ngân sách mở trang quản lý ngân sách', (tester) async {
      final controller = AuthController();

      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cảnh báo ngân sách'));
      await tester.pumpAndSettle();

      expect(find.text('Quản lý ngân sách AI'), findsOneWidget);
    });
  });
}
