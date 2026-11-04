import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/theme/app_theme.dart';
import 'package:tokenscope/screens/projects/projects_screen.dart';

import 'helpers/font_loader.dart';
import 'helpers/fake_controllers.dart';

/// Chụp toàn bộ nội dung cuộn của trang quản lý dự án.
void main() {
  setUpAll(loadInterFonts);

  testWidgets('Ảnh toàn trang quản lý dự án', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1412 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProjectsScreen(controller: buildFakeProjectsController()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/projects_full.png'),
    );
  });
}
