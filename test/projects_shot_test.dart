import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/core/theme/app_theme.dart';
import 'package:tokenscope/screens/projects/projects_screen.dart';

import 'helpers/font_loader.dart';

/// Chụp ảnh giao diện trang quản lý dự án để kiểm tra thị giác.
void main() {
  setUpAll(loadInterFonts);

  testWidgets('Ảnh trang quản lý dự án', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ProjectsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/projects.png'),
    );
  });
}
