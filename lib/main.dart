import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/firebase_lab3_controller.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo các dịch vụ Firebase trên thiết bị Android theo yêu cầu Lab 3.
  // Đặt trong try-catch và kiểm tra !kIsWeb để tránh crash khi chạy thử nghiệm trên Web.
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Khởi tạo các tích hợp Firebase qua một ViewModel duy nhất.
      await FirebaseLab3Controller.instance.initialize();
    }
  } catch (error) {
    debugPrint('Firebase init notice: $error');
  }

  // Ghi nhận lượt mở ứng dụng & khởi động client Crash Testing.
  // Hai tác vụ này chỉ phục vụ Admin Web — không ảnh hưởng tới luồng chính
  // của app. Mọi lỗi đều được nuốt bên trong service.
  try {
    await FirebaseLab3Controller.instance.trackAppOpen();
    await FirebaseLab3Controller.instance.startCrashTestClient();
  } catch (error) {
    debugPrint('App usage tracking notice: $error');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const TokenScopeApp());
}
