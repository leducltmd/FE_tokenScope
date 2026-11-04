import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'providers/auth_controller.dart';
import 'providers/dashboard_controller.dart';
import 'providers/usage_history_controller.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/api_auth_service.dart';

class TokenScopeApp extends StatelessWidget {
  const TokenScopeApp({
    super.key,
    this.authController,
    this.dashboardController,
    this.historyController,
  });

  final AuthController? authController;

  /// Controller tổ quan dùng cho màn hình tổng quan (null → gọi backend thật).
  final DashboardController? dashboardController;

  /// Controller lịch sử dùng cho mục truy vấn gần nhất (null → gọi backend thật).
  final UsageHistoryController? historyController;

  @override
  Widget build(BuildContext context) {
    final controller = authController ?? AuthController(service: ApiAuthService());

    return MaterialApp(
      title: 'TokenScope',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _AuthFlow(
        controller: controller,
        dashboardController: dashboardController,
        historyController: historyController,
      ),
    );
  }
}

/// Điều hướng đơn giản giữa các màn hình xác thực.
class _AuthFlow extends StatefulWidget {
  const _AuthFlow({
    required this.controller,
    this.dashboardController,
    this.historyController,
  });

  final AuthController controller;
  final DashboardController? dashboardController;
  final UsageHistoryController? historyController;

  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  AuthPage _page = AuthPage.login;

  void _go(AuthPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: switch (_page) {
        AuthPage.login => LoginScreen(
          key: const ValueKey('login'),
          controller: widget.controller,
          onRegisterTap: () => _go(AuthPage.register),
          onForgotPasswordTap: () => _go(AuthPage.forgotPassword),
          onAuthenticated: () => _go(AuthPage.dashboard),
        ),
        AuthPage.register => RegisterScreen(
          key: const ValueKey('register'),
          controller: widget.controller,
          onLoginTap: () => _go(AuthPage.login),
          onRegistered: () => _go(AuthPage.dashboard),
        ),
        AuthPage.forgotPassword => ForgotPasswordScreen(
          key: const ValueKey('forgot-password'),
          controller: widget.controller,
          onBack: () => _go(AuthPage.login),
        ),
        AuthPage.dashboard => DashboardScreen(
          key: const ValueKey('dashboard'),
          controller: widget.controller,
          onLogout: () => _go(AuthPage.login),
          dashboardController: widget.dashboardController,
          historyController: widget.historyController,
        ),
      },
    );
  }
}

enum AuthPage { login, register, forgotPassword, dashboard }

/// Màn hình tạm thời trong lúc backend đang được tích hợp.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Đang phát triển',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
