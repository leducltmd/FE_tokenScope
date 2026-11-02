import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/theme/app_theme.dart';
import 'package:tokenscope/models/usage_record.dart';
import 'package:tokenscope/providers/usage_history_controller.dart';
import 'package:tokenscope/screens/usage_history/usage_history_screen.dart';
import 'package:tokenscope/services/usage_history_service.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 844,
        child: child,
      ),
    ),
  );
}

void main() {
  group('UsageRecord Model Tests', () {
    test('Định dạng số token và chi phí chính xác theo chuẩn', () {
      final record = UsageRecord(
        id: 'test_1',
        promptId: 'pmt_test',
        provider: 'OpenAI',
        model: 'gpt-4o',
        project: 'Chatbot Support',
        projectIconType: 'folder',
        timestamp: DateTime(2026, 10, 15, 10, 42, 15),
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
        promptPreview: 'Test prompt',
        responsePreview: 'Test response',
      );

      expect(record.formattedInputTokens, '1.420');
      expect(record.formattedOutputTokens, '580');
      expect(record.formattedTotalTokens, '2.000');
      expect(record.formattedCost, '\$0.0158');
      expect(record.fullTimeDisplay, '10:42:15 - Hôm nay (15/10)');
      expect(UsageRecord.formatNumber(1482), '1.482');
    });
  });

  group('UsageHistoryController Unit Tests', () {
    test('Khởi tạo và tải danh sách ban đầu', () async {
      final controller = UsageHistoryController(
        service: MockUsageHistoryService(simulateDelay: Duration.zero),
      );

      await controller.loadRecords();

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.records.length, 5);
      expect(controller.totalCount, 1482);
      expect(controller.records.first.model, 'gpt-4o');
      expect(controller.records.first.cost, 0.0158);
      expect(controller.records.first.inputTokens, 1420);
      expect(controller.records.first.outputTokens, 580);
    });

    test('Lọc theo nhà cung cấp', () async {
      final controller = UsageHistoryController(
        service: MockUsageHistoryService(simulateDelay: Duration.zero),
      );

      await controller.loadRecords();
      await controller.setProvider('OpenAI');

      expect(controller.selectedProvider, 'OpenAI');
      expect(controller.records.every((r) => r.provider.contains('OpenAI')), isTrue);
    });

    test('Tìm kiếm theo từ khoá và xử lý Empty State', () async {
      final controller = UsageHistoryController(
        service: MockUsageHistoryService(simulateDelay: Duration.zero),
      );

      await controller.loadRecords();
      await controller.setSearchQuery('khong_ton_tai_123456');

      expect(controller.records.isEmpty, isTrue);
      expect(controller.isEmpty, isTrue);

      await controller.clearFilters();

      expect(controller.searchQuery, isEmpty);
      expect(controller.records.isNotEmpty, isTrue);
    });

    test('Tải thêm bản ghi (Phân trang)', () async {
      final controller = UsageHistoryController(
        service: MockUsageHistoryService(simulateDelay: Duration.zero),
      );

      await controller.loadRecords();
      expect(controller.records.length, 5);

      await controller.loadMore();
      expect(controller.records.length, greaterThan(5));
    });
  });

  group('UsageHistoryScreen Widget Tests', () {
    testWidgets('Hiển thị đầy đủ thanh công cụ, các bản ghi và thẻ lỗi theo Figma', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final controller = UsageHistoryController(
        service: MockUsageHistoryService(simulateDelay: Duration.zero),
      );

      await tester.pumpWidget(_wrap(UsageHistoryScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Đầu trang
      expect(find.text('TokenScope'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Lịch Sử'), findsOneWidget);

      // Ô tìm kiếm & Bộ lọc
      expect(find.text('Tìm kiếm theo prompt ID, model, dự án...'), findsOneWidget);
      expect(find.text('Tất cả nhà cung cấp'), findsOneWidget);
      expect(find.text('OpenAI'), findsAtLeastNWidgets(1));
      expect(find.text('Gemini'), findsOneWidget);
      expect(find.text('Anthropic'), findsAtLeastNWidgets(1));

      // Thống kê & LIVE STREAM
      expect(find.text('LIVE STREAM'), findsOneWidget);
      expect(find.textContaining('lượt gọi API hôm nay'), findsOneWidget);
      expect(find.text('Hiển thị 5 / 1.482 bản ghi ghi nhận'), findsOneWidget);

      // Thẻ đầu tiên: GPT-4o thành công ($0.0158)
      expect(find.textContaining('gpt-4o'), findsAtLeastNWidgets(1));
      expect(find.text('\$0.0158'), findsOneWidget);
      expect(find.text('Thành công (200 OK)'), findsAtLeastNWidgets(1));

      // Thẻ lỗi: 429 Rate Limit
      expect(find.text('Lỗi Rate Limit (429)'), findsOneWidget);
      expect(find.text('Xem chi tiết lỗi'), findsOneWidget);
      expect(find.text('\$0.0000'), findsOneWidget);

      // Nút tải thêm
      expect(find.text('Tải thêm 20 bản ghi'), findsOneWidget);
    });

    testWidgets('Tương tác tìm kiếm và xóa bộ lọc trong Empty State', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final controller = UsageHistoryController(
        service: MockUsageHistoryService(simulateDelay: Duration.zero),
      );

      await tester.pumpWidget(_wrap(UsageHistoryScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Nhập từ khóa không có kết quả
      await tester.enterText(
        find.byType(TextField),
        'chuoi_khong_the_tim_thay_9999',
      );
      await tester.pumpAndSettle();

      // Hiển thị Empty State
      expect(find.text('Không tìm thấy lượt gọi nào'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsOneWidget);

      // Nhấn nút xóa bộ lọc
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();

      // Danh sách hồi phục
      expect(find.text('Tải thêm 20 bản ghi'), findsOneWidget);
    });

    testWidgets('Chọn một bản ghi điều hướng sang UsageDetailsScreen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final controller = UsageHistoryController(
        service: MockUsageHistoryService(simulateDelay: Duration.zero),
      );

      await tester.pumpWidget(_wrap(UsageHistoryScreen(controller: controller)));
      await tester.pumpAndSettle();

      // Chạm vào thẻ đầu tiên (gpt-4o)
      await tester.tap(find.text('\$0.0158'));
      await tester.pumpAndSettle();

      // Màn hình Usage Details hiển thị
      expect(find.text('Chi tiết lượt gọi API'), findsOneWidget);
      expect(find.text('pmt_94821a0f'), findsAtLeastNWidgets(1));
      expect(find.text('Mô hình AI'), findsOneWidget);
      expect(find.text('Thông tin ngữ cảnh & Metadata'), findsOneWidget);

      // Cuộn xuống để xem nút quay lại
      final detailsScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Quay lại lịch sử'),
        200,
        scrollable: detailsScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Quay lại lịch sử'), findsOneWidget);

      // Nhấn nút quay lại
      await tester.tap(find.text('Quay lại lịch sử'));
      await tester.pumpAndSettle();

      // Trở lại danh sách lịch sử
      expect(find.text('LIVE STREAM'), findsOneWidget);
    });
  });
}
