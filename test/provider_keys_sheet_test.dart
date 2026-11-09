import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/models/provider_connection.dart';
import 'package:tokenscope/screens/providers/widgets/provider_keys_sheet.dart';

/// Bọc sheet trong một scaffold để test có ngữ cảnh Material.
Widget _wrap(ProviderConnection provider, Future<void> Function({
  String? apiKey,
  String? adminApiKey,
  String? workspaceId,
  bool clearAdminApiKey,
}) onSave) {
  return MaterialApp(
    home: Scaffold(
      body: ProviderKeysSheet(provider: provider, onSave: onSave),
    ),
  );
}

ProviderConnection _claudeProvider({
  String? secretKeyStatus = 'connected',
  String? adminKeyStatus = 'missingPermissions',
}) {
  return ProviderConnection(
    id: 'p1',
    name: 'Claude Personal',
    providerType: 'anthropic',
    providerName: 'Anthropic Claude',
    letter: 'A',
    status: 'active',
    usageAvailable: true,
    models: const <String>[],
    totalTokens: 0,
    totalCost: 0,
    requestCount: 0,
    secretKeyStatus: secretKeyStatus,
    adminKeyStatus: adminKeyStatus,
  );
}

void main() {
  group('Sheet cập nhật khoá Claude', () {
    testWidgets('hiển thị hai loại khoá và Workspace ID riêng biệt', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_claudeProvider(), ({
        apiKey,
        adminApiKey,
        workspaceId,
        clearAdminApiKey = false,
      }) async {}));

      expect(find.text('Claude Secret API Key'), findsNWidgets(2));
      expect(find.text('Claude Admin API Key'), findsNWidgets(2));
      expect(find.text('Claude Workspace ID'), findsOneWidget);
    });

    testWidgets('hiển thị trạng thái từng loại khoá', (tester) async {
      await tester.pumpWidget(_wrap(_claudeProvider(), ({
        apiKey,
        adminApiKey,
        workspaceId,
        clearAdminApiKey = false,
      }) async {}));

      expect(find.text('Đã kết nối'), findsOneWidget);
      expect(find.text('Thiếu quyền tổ chức'), findsOneWidget);
    });

    testWidgets('chỉ gửi loại khoá được nhập, không ghi đè loại kia', (
      tester,
    ) async {
      String? sentApiKey;
      String? sentAdminKey;
      String? sentWorkspace;

      await tester.pumpWidget(
        _wrap(
          _claudeProvider(),
          ({
            apiKey,
            adminApiKey,
            workspaceId,
            clearAdminApiKey = false,
          }) async {
            sentApiKey = apiKey;
            sentAdminKey = adminApiKey;
            sentWorkspace = workspaceId;
          },
        ),
      );

      // Field 0 = Secret API Key, 1 = Admin API Key, 2 = Workspace ID.
      await tester.enterText(
        find.byType(TextField).at(1),
        'sk-ant-admin-new-key',
      );
      await tester.ensureVisible(find.text('Lưu khoá'));
      await tester.tap(find.text('Lưu khoá'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 200));

      // Chỉ Admin API Key được gửi — Secret API Key giữ nguyên (null).
      expect(sentAdminKey, 'sk-ant-admin-new-key');
      expect(sentApiKey, isNull);
      expect(sentWorkspace, isNull);
    });

    testWidgets('gửi Workspace ID kèm khi có', (tester) async {
      String? sentWorkspace;

      await tester.pumpWidget(
        _wrap(
          _claudeProvider(),
          ({
            apiKey,
            adminApiKey,
            workspaceId,
            clearAdminApiKey = false,
          }) async {
            sentWorkspace = workspaceId;
          },
        ),
      );

      await tester.enterText(find.byType(TextField).at(2), 'wrkspc_abc123');
      await tester.ensureVisible(find.text('Lưu khoá'));
      await tester.tap(find.text('Lưu khoá'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 200));

      expect(sentWorkspace, 'wrkspc_abc123');
    });

    testWidgets('báo lỗi khi Workspace ID sai tiền tố', (tester) async {
      var called = false;

      await tester.pumpWidget(
        _wrap(
          _claudeProvider(),
          ({
            apiKey,
            adminApiKey,
            workspaceId,
            clearAdminApiKey = false,
          }) async {
            called = true;
          },
        ),
      );

      await tester.enterText(find.byType(TextField).at(2), 'abc123');
      await tester.ensureVisible(find.text('Lưu khoá'));
      await tester.tap(find.text('Lưu khoá'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 200));

      expect(called, isFalse);
      expect(
        find.text('Workspace ID của Anthropic phải bắt đầu bằng "wrkspc_".'),
        findsOneWidget,
      );
    });
  });
}
