import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase nếu nền tảng được hỗ trợ cấu hình (Android theo yêu cầu Lab 3).
  // Đặt trong try-catch và kiểm tra !kIsWeb để khi chạy trên Web ứng dụng không bị crash trắng màn hình.
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Khởi tạo GoogleSignIn.instance.initialize() đúng một lần duy nhất theo chuẩn google_sign_in 7.2.0
      await FirebaseAuthService.ensureInitialized();
    }
  } catch (error) {
    debugPrint('Firebase/GoogleSignIn init notice: $error');
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
