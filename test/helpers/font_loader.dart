import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nạp font Inter thật vào môi trường test để phép đo chữ chính xác
/// giống hệt khi chạy ứng dụng (mặc định test dùng font giả "Ahem"
/// khiến mọi chữ rộng bằng ô vuông và gây overflow giả).
Future<void> loadInterFonts() async {
  final loader = FontLoader('Inter');
  final dir = Directory('assets/fonts');

  for (final name in [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
  ]) {
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    if (!file.existsSync()) continue;
    loader.addFont(
      file.readAsBytes().then((b) => ByteData.view(b.buffer)),
    );
  }

  await loader.load();
}
