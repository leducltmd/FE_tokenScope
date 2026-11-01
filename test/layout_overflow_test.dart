import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokenscope/app.dart';

/// Bảo đảm các màn hình xác thực không bao giờ tràn bố cục (RenderFlex
/// overflow) dù viewport nhỏ tới mức nào.
void main() {
  const app = TokenScopeApp(useMockService: true);

  for (final size in <Size>[
    const Size(390, 844),
    const Size(390, 600),
    const Size(390, 400),
    const Size(320, 480),
    const Size(1, 1),
  ]) {
    testWidgets('Không tràn bố cục ở viewport ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  }
}
