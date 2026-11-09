import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/theme/app_theme.dart';
import 'package:tokenscope/models/budget_overview.dart';
import 'package:tokenscope/models/provider_connection.dart';
import 'package:tokenscope/models/usage_record.dart';
import 'package:tokenscope/models/usage_summary.dart';
import 'package:tokenscope/providers/auth_controller.dart';
import 'package:tokenscope/providers/budget_controller.dart';
import 'package:tokenscope/providers/dashboard_controller.dart';
import 'package:tokenscope/providers/providers_controller.dart';
import 'package:tokenscope/providers/usage_history_controller.dart';
import 'package:tokenscope/screens/dashboard/dashboard_screen.dart';
import 'package:tokenscope/screens/dashboard/widgets/hero_metric_card.dart';
import 'package:tokenscope/services/budget_service.dart';
import 'package:tokenscope/services/provider_service.dart';

import 'helpers/fake_controllers.dart';
import 'helpers/fake_services.dart';

/// Bọc dashboard trong khung 390 × 844 để mô phỏng thiết bị mobile.
Widget _wrap({
  DashboardController? dashboardController,
  UsageHistoryController? historyController,
  BudgetController? budgetController,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 844,
        child: DashboardScreen(
          controller: AuthController(),
          dashboardController:
              dashboardController ?? buildFakeDashboardController(),
          historyController: historyController ?? buildFakeHistoryController(),
          budgetController: budgetController ?? buildFakeBudgetController(),
        ),
      ),
    ),
  );
}

class _SplitDashboardService implements DashboardService {
  @override
  Future<UsageSummary> getSummary() async => const UsageSummary(
    totalTokens: 2450000,
    inputTokens: 1800000,
    outputTokens: 650000,
    totalCost: 34.8,
    requestCount: 1,
    byProvider: [],
    daily: [],
  );
}

class _DashboardBudgetService implements BudgetService {
  const _DashboardBudgetService({required this.limit});

  final double limit;

  @override
  Future<BudgetOverview> getOverview() async => BudgetOverview(
    periodLabel: '01/11 - 30/11',
    totalLimit: limit,
    threshold: limit * 0.8,
    spent: 11.25,
    percent: limit > 0 ? 11.25 / limit * 100 : 0,
    thresholdPercent: 0,
    providers: [],
    projects: [],
    forecast: 11.25,
  );
}

class _CountingDashboardService extends FakeDashboardService {
  int loads = 0;

  @override
  Future<UsageSummary> getSummary() {
    loads++;
    return super.getSummary();
  }
}

class _SyncProviderService extends ApiProviderService {
  int synced = 0;

  @override
  Future<ProviderSyncResult> syncUsage(String providerId) async =>
      ProviderSyncResult(synced: synced, message: 'Kết quả đồng bộ');

  @override
  Future<ProvidersOverview> getProviders() async => const ProvidersOverview(
    providers: [],
    totalTokens: 0,
    totalCost: 0,
    requestCount: 0,
    connectedCount: 0,
  );
}

void main() {
  testWidgets('Dashboard hiển thị tỷ lệ token và ngân sách từ API', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        dashboardController: DashboardController(
          service: _SplitDashboardService(),
        ),
        budgetController: BudgetController(
          service: const _DashboardBudgetService(limit: 50),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final heroFinder = find.byType(TsHeroMetricCard);
    final hero = tester.widget<TsHeroMetricCard>(heroFinder);
    expect(find.text('Tổng token đã ghi nhận'), findsOneWidget);
    expect(hero.totalTokens, '2.450.000');
    expect(hero.inputTokens, '1.800.000');
    expect(hero.outputTokens, '650.000');
    expect(hero.inputPercent, closeTo(1800000 / 2450000, 0.00001));
    expect(hero.outputPercent, closeTo(650000 / 2450000, 0.00001));
    expect(hero.remainingLabel, r'$11.25 / $50.00');
    expect(hero.spentPercent, closeTo(0.225, 0.00001));

    final progress = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: heroFinder,
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(progress.value, closeTo(0.225, 0.00001));
  });

  testWidgets('Dashboard bỏ tỷ lệ chi tiêu khi chưa có hạn mức', (tester) async {
    await tester.pumpWidget(
      _wrap(
        budgetController: BudgetController(
          service: const _DashboardBudgetService(limit: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hero = tester.widget<TsHeroMetricCard>(find.byType(TsHeroMetricCard));
    expect(hero.spentPercent, isNull);
  });

  testWidgets('Đồng bộ có dữ liệu làm mới tổng quan và truy vấn gần nhất', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final summaryService = _CountingDashboardService();
    final providerService = _SyncProviderService();
    final providers = ProvidersController(service: providerService);
    addTearDown(providers.dispose);
    final records = <UsageRecord>[];
    await tester.pumpWidget(
      _wrap(
        dashboardController: DashboardController(service: summaryService),
        historyController: buildFakeHistoryController(records: records),
      ),
    );
    await tester.pumpAndSettle();
    expect(summaryService.loads, 1);

    await providers.syncUsage('claude');
    await tester.pumpAndSettle();
    expect(summaryService.loads, 1);

    records.add(buildTestUsageRecord(model: 'claude-new-usage'));
    providerService.synced = 1;
    await providers.syncUsage('claude');
    await tester.pumpAndSettle();
    expect(summaryService.loads, 2);

    final latestModel = find.text('claude-new-usage');
    await tester.scrollUntilVisible(
      latestModel,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(latestModel, findsOneWidget);
  });

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
