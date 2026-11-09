import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/models/provider_connection.dart';
import 'package:tokenscope/screens/providers/connect_provider_screen.dart';
import 'package:tokenscope/screens/providers/widgets/connect_provider_widgets.dart';
import 'package:tokenscope/services/provider_service.dart';

/// Service giả lập cho test — trả về trạng thái kiểm tra theo yêu cầu.
class FakeProviderService implements ProviderService {
  FakeProviderService({this.result, this.delay = const Duration(milliseconds: 50)});

  /// Kết quả trả về cho lần kiểm tra kết nối.
  ProviderConnectionCheck? result;

  /// Độ trễ giả lập để mô phỏng thời gian chờ của network.
  final Duration delay;

  bool connectCalled = false;
  String? connectedName;

  /// Admin API Key nhận được ở lần kiểm tra kết nối cuối cùng.
  String? lastAdminApiKey;

  /// Admin API Key nhận được ở lần kết nối cuối cùng.
  String? lastConnectAdminApiKey;

  /// Workspace ID nhận được ở lần kiểm tra kết nối cuối cùng.
  String? lastWorkspaceId;

  /// Workspace ID nhận được ở lần kết nối cuối cùng.
  String? lastConnectWorkspaceId;

  @override
  Future<ProvidersOverview> getProviders() async {
    return const ProvidersOverview(
      providers: <ProviderConnection>[],
      totalTokens: 0,
      totalCost: 0,
      requestCount: 0,
      connectedCount: 0,
    );
  }

  @override
  Future<ProviderConnectionCheck> testConnection({
    required String providerType,
    required String apiKey,
    String? adminApiKey,
    String? workspaceId,
  }) async {
    await Future<void>.delayed(delay);
    lastAdminApiKey = adminApiKey;
    lastWorkspaceId = workspaceId;
    return result ??
        const ProviderConnectionCheck(
          status: 'success',
          message: 'Kết nối thành công.',
        );
  }

  @override
  Future<ProviderConnection> connect({
    required String name,
    required String providerType,
    required String apiKey,
    String? adminApiKey,
    String? workspaceId,
  }) async {
    await Future<void>.delayed(delay);
    connectCalled = true;
    connectedName = name;
    lastConnectAdminApiKey = adminApiKey;
    lastConnectWorkspaceId = workspaceId;
    return ProviderConnection(
      id: 'p1',
      name: name,
      providerType: providerType,
      providerName: providerType,
      letter: 'O',
      status: 'active',
      usageAvailable: true,
      models: const <String>[],
      totalTokens: 0,
      totalCost: 0,
      requestCount: 0,
    );
  }

  @override
  Future<ProviderConnection> updateKeys(
    String providerId, {
    String? apiKey,
    String? adminApiKey,
    String? workspaceId,
    bool clearAdminApiKey = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProviderConnectionCheck> recheck(String providerId) async {
    return const ProviderConnectionCheck(
      status: 'success',
      message: 'Kết nối thành công.',
    );
  }

  @override
  Future<ProviderSyncResult> syncUsage(String providerId) async {
    return const ProviderSyncResult(synced: 0, message: 'Không có dữ liệu.');
  }

  @override
  Future<ProviderConnection> rename(String providerId, String name) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String providerId) async {}
}

/// Kiểm thử màn hình kết nối nhà cung cấp AI.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? initialProviderId,
    void Function(String name, ConnectableProvider provider)? onConnected,
    ProviderService? service,
  }) async {
    // Màn hình dài — dùng surface lớn để toàn bộ nội dung được dựng sẵn.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        ConnectProviderScreen(
          initialProviderId: initialProviderId,
          onConnected: onConnected,
          service: service ?? FakeProviderService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Nội dung của trường nhập theo vị trí.
  String fieldText(WidgetTester tester, int index) {
    final field = tester.widgetList<TextField>(find.byType(TextField)).elementAt(index);
    return field.controller?.text ?? '';
  }

  group('Kết nối nhà cung cấp', () {
    testWidgets('chưa chọn nhà cung cấp thì chỉ hiện lưới chọn', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Kết nối nhà cung cấp'), findsOneWidget);
      expect(find.text('1 · Chọn nhà cung cấp'), findsOneWidget);
      expect(find.text('Chọn một nhà cung cấp'), findsOneWidget);

      // Form kết nối chưa hiện.
      expect(find.text('2 · Kết nối API'), findsNothing);
      expect(find.text('Kiểm tra kết nối'), findsNothing);
    });

    testWidgets('chọn nhà cung cấp hiện form và hướng dẫn lấy API Key', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      expect(find.text('2 · Kết nối API'), findsOneWidget);
      expect(find.text('Tên kết nối'), findsOneWidget);
      expect(find.text('API Key'), findsOneWidget);
      expect(find.text('Kiểm tra kết nối'), findsOneWidget);
      expect(find.text('Kết nối'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);

      // Hướng dẫn lấy API Key + link chính thức.
      expect(find.text('Cách lấy API Key'), findsOneWidget);
      expect(find.text('platform.openai.com/api-keys'), findsOneWidget);
    });

    testWidgets('API Key hiển thị dạng password và có nút hiện/ẩn', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      expect(field.obscureText, isTrue);

      // Nút hiện/ẩn API Key.
      expect(find.byTooltip('Hiện mật khẩu'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Hiện mật khẩu').first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
    });

    testWidgets('tên kết nối được gợi ý theo nhà cung cấp', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Google Gemini'));
      await tester.pumpAndSettle();

      expect(fieldText(tester, 0), 'Google Gemini Personal');
    });

    testWidgets('thiếu tên kết nối hoặc API Key thì báo lỗi tại chỗ', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      // Xoá tên kết nối và API Key.
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(
        find.text('Vui lòng nhập tên kết nối.'),
        findsOneWidget,
      );
      expect(find.text('Vui lòng nhập API Key.'), findsOneWidget);
    });
  });

  group('Trạng thái kiểm tra kết nối', () {
    testWidgets('mặc định là chưa kiểm tra', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa kiểm tra'), findsOneWidget);
    });

    testWidgets('đang kiểm tra rồi thành công', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-test-123',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pump();

      // Trạng thái đang kiểm tra.
      expect(find.text('Đang kiểm tra kết nối'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Kết nối thành công'), findsOneWidget);
      expect(find.text('Sẵn sàng'), findsOneWidget);
    });

    testWidgets('API Key không hợp lệ', (tester) async {
      final service = FakeProviderService(
        result: const ProviderConnectionCheck(
          status: 'invalidKey',
          message: 'API Key không hợp lệ.',
          httpStatus: 401,
        ),
      );

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-invalid-key',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(find.text('API Key không hợp lệ'), findsOneWidget);
      expect(find.textContaining('401'), findsOneWidget);
    });

    testWidgets('không thể kết nối tới nhà cung cấp', (tester) async {
      final service = FakeProviderService(
        result: const ProviderConnectionCheck(
          status: 'unreachable',
          message: 'Không thể kết nối đến nhà cung cấp.',
          httpStatus: 503,
        ),
      );

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-offline',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(find.text('Không thể kết nối'), findsOneWidget);
      expect(find.textContaining('503'), findsOneWidget);
    });

    testWidgets('thiếu quyền truy cập usage hoặc billing', (tester) async {
      final service = FakeProviderService(
        result: const ProviderConnectionCheck(
          status: 'missingScope',
          message: 'API Key thiếu quyền truy cập usage hoặc billing.',
          httpStatus: 403,
        ),
      );

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-scope-key',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(find.text('Thiếu quyền truy cập'), findsOneWidget);
      expect(find.textContaining('403'), findsOneWidget);
    });

    testWidgets('sửa lại API Key thì trạng thái trở về chưa kiểm tra', (
      tester,
    ) async {
      final service = FakeProviderService(
        result: const ProviderConnectionCheck(
          status: 'invalidKey',
          message: 'API Key không hợp lệ.',
          httpStatus: 401,
        ),
      );

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-invalid',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();
      expect(find.text('API Key không hợp lệ'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-ok',
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa kiểm tra'), findsOneWidget);
    });

    testWidgets('chưa kiểm tra thành công thì không cho kết nối', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-test',
      );
      await tester.tap(find.text('Kết nối'));
      await tester.pumpAndSettle();

      expect(
        find.text('Hãy kiểm tra kết nối thành công trước khi kết nối.'),
        findsOneWidget,
      );
    });
  });

  group('Usage & Billing', () {
    testWidgets('hiển thị đủ các lưu ý về usage và billing', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      expect(find.text('3 · Usage & Billing'), findsOneWidget);
      expect(
        find.textContaining('Token usage và chi phí có thể được đồng bộ'),
        findsOneWidget,
      );
      expect(
        find.textContaining('không cung cấp đầy đủ dữ liệu billing'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Chi phí ước tính từ token có thể khác'),
        findsOneWidget,
      );
      expect(
        find.textContaining('chỉ hiển thị dữ liệu mà API Key'),
        findsOneWidget,
      );
    });

    testWidgets('ghi chú quyền riêng cho từng nhà cung cấp', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Google Gemini'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Google AI Studio chưa cung cấp API billing'),
        findsOneWidget,
      );
    });
  });

  group('Admin API Key (OpenAI)', () {
    testWidgets('chỉ OpenAI mới hiện trường Admin API Key', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      expect(find.text('Admin API Key'), findsOneWidget);

      // Chuyển sang nhà cung cấp khác → trường này biến mất.
      await tester.tap(find.text('Google Gemini'));
      await tester.pumpAndSettle();

      expect(find.text('Admin API Key'), findsNothing);
    });

    testWidgets('gửi Admin API Key khi kiểm tra kết nối', (tester) async {
      final service = FakeProviderService();

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'sk-secret-key');
      await tester.enterText(
        find.byType(TextField).at(2),
        'sk-admin-key-123',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(service.lastAdminApiKey, 'sk-admin-key-123');
    });

    testWidgets('bỏ trống Admin API Key thì không gửi lên', (tester) async {
      final service = FakeProviderService();

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'sk-secret-key');
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(service.lastAdminApiKey, isNull);
    });

    testWidgets('Admin API Key quá ngắn thì báo lỗi tại chỗ', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'sk-secret-key');
      await tester.enterText(find.byType(TextField).at(2), 'abc');
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(find.text('Admin API Key quá ngắn.'), findsOneWidget);
    });

    testWidgets('gửi Admin API Key khi kết nối', (tester) async {
      final service = FakeProviderService();

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'sk-secret-key');
      await tester.enterText(
        find.byType(TextField).at(2),
        'sk-admin-key-123',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết nối'));
      await tester.pumpAndSettle();

      expect(service.connectCalled, isTrue);
      expect(service.lastConnectAdminApiKey, 'sk-admin-key-123');
    });
  });

  group('Claude — hai loại khoá tách biệt', () {
    testWidgets('Claude hiện Secret API Key, Admin API Key và Workspace ID riêng biệt', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Anthropic Claude'));
      await tester.pumpAndSettle();

      expect(find.text('Claude Secret API Key'), findsNWidgets(2));
      expect(find.text('Claude Admin API Key'), findsNWidgets(2));
      expect(find.text('Claude Workspace ID'), findsOneWidget);

      // Không còn nhãn chung "API Key" cho Claude.
      expect(find.text('API Key'), findsNothing);
    });

    testWidgets('cả hai khoá đều ẩn mật khẩu và có nút hiện/ẩn riêng', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Anthropic Claude'));
      await tester.pumpAndSettle();

      // Field 0 = tên, 1 = Secret API Key, 2 = Admin API Key, 3 = Workspace ID.
      final secret = tester.widget<TextField>(find.byType(TextField).at(1));
      final admin = tester.widget<TextField>(find.byType(TextField).at(2));

      expect(secret.obscureText, isTrue);
      expect(admin.obscureText, isTrue);

      // Hai nút hiện/ẩn (mỗi khoá một nút).
      expect(find.byTooltip('Hiện mật khẩu'), findsNWidgets(2));

      // Hiện khoá Secret → nút "Ẩn mật khẩu" xuất hiện.
      await tester.tap(find.byTooltip('Hiện mật khẩu').first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
    });

    testWidgets('gửi đúng Secret API Key, Admin API Key và Workspace ID', (
      tester,
    ) async {
      final service = FakeProviderService();

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('Anthropic Claude'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-ant-secret-key',
      );
      await tester.enterText(
        find.byType(TextField).at(2),
        'sk-ant-admin-key-123',
      );
      await tester.enterText(
        find.byType(TextField).at(3),
        'wrkspc_abc123',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(service.lastAdminApiKey, 'sk-ant-admin-key-123');
      expect(service.lastWorkspaceId, 'wrkspc_abc123');
    });

    testWidgets('hiển thị hai dòng trạng thái khoá riêng biệt', (
      tester,
    ) async {
      final service = FakeProviderService(
        result: const ProviderConnectionCheck(
          status: 'missingScope',
          message: 'Admin API Key thiếu quyền tổ chức.',
          secretKey: ProviderKeyCheck(
            status: 'connected',
            message: 'Secret API Key hợp lệ.',
          ),
          adminKey: ProviderKeyCheck(
            status: 'missingPermissions',
            message: 'Thiếu quyền đọc Usage & Costs.',
          ),
        ),
      );

      await pumpScreen(tester, service: service);
      await tester.tap(find.text('Anthropic Claude'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-ant-secret-key',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      // Hai dòng trạng thái độc lập (mỗi dòng có nhãn ở form + ở panel).
      expect(find.text('Claude Secret API Key'), findsNWidgets(2));
      expect(find.text('Claude Admin API Key'), findsNWidgets(2));
      expect(find.text('Đã kết nối'), findsOneWidget);
      expect(find.text('Thiếu quyền tổ chức'), findsOneWidget);
    });

    testWidgets('Workspace ID sai tiền tố thì báo lỗi tại chỗ', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Anthropic Claude'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-ant-secret-key',
      );
      await tester.enterText(find.byType(TextField).at(3), 'abc');
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      expect(
        find.text('Workspace ID của Anthropic phải bắt đầu bằng "wrkspc_".'),
        findsOneWidget,
      );
    });
  });

  group('Hành động', () {
    testWidgets('kết nối thành công thì gọi callback với tên và nhà cung cấp', (
      tester,
    ) async {
      String? connectedName;
      String? connectedProvider;
      final service = FakeProviderService();

      await pumpScreen(
        tester,
        service: service,
        onConnected: (name, provider) {
          connectedName = name;
          connectedProvider = provider.name;
        },
      );

      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-ok',
      );
      await tester.tap(find.text('Kiểm tra kết nối'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết nối'));
      await tester.pumpAndSettle();

      expect(service.connectCalled, isTrue);
      expect(connectedName, 'OpenAI Personal');
      expect(connectedProvider, 'OpenAI');
    });
  });
}
