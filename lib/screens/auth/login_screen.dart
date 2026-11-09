import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/ts_checkbox.dart';
import '../../core/widgets/ts_social_button.dart';
import '../../core/widgets/ts_text_field.dart';
import '../../providers/auth_controller.dart';
import '../../services/api_auth_service.dart';
import '../../services/auth_service.dart';
import 'auth_header.dart';
import 'auth_status_banner.dart';

/// Màn hình đăng nhập TokenScope.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authService,
    this.controller,
    this.onRegisterTap,
    this.onForgotPasswordTap,
    this.onAuthenticated,
  });

  final AuthService? authService;
  final AuthController? controller;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  /// Được gọi sau khi đăng nhập thành công.
  final VoidCallback? onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _controller =
      widget.controller ??
      AuthController(service: widget.authService ?? ApiAuthService());

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGitHubLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final result = await _controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = result ? null : _controller.error;
    });

    if (result) {
      widget.onAuthenticated?.call();
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    final success = await _controller.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
      // Nếu người dùng hủy chọn tài khoản, error sẽ là null nên không hiện banner lỗi
      _errorMessage = success ? null : _controller.error;
    });

    if (success) {
      widget.onAuthenticated?.call();
    }
  }

  Future<void> _handleGitHubLogin() async {
    setState(() {
      _errorMessage = null;
      _isGitHubLoading = true;
    });

    final success = await _controller.signInWithGitHub();

    if (!mounted) return;

    setState(() {
      _isGitHubLoading = false;
      _errorMessage = success ? null : _controller.error;
    });

    if (success) {
      widget.onAuthenticated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoading || _isGoogleLoading || _isGitHubLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        // Toàn bộ nội dung nằm trong một vùng cuộn để không bao giờ tràn
        // chiều cao, kể cả khi viewport rất thấp hoặc rất hẹp.
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.space32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: const AuthHeader(
                  title: 'Chào mừng trở lại',
                  subtitle:
                      'Theo dõi mức sử dụng và chi phí API theo thời gian thực.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space24,
                  AppSpacing.screenPadding,
                  AppSpacing.space32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TsTextField(
                        label: 'Email',
                        hint: 'ban@congty.com',
                        icon: Icons.alternate_email_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        helperText: 'Dùng email đăng ký của bạn',
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      TsTextField(
                        label: 'Mật khẩu',
                        hint: 'Nhập mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => isBusy ? null : _handleLogin(),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      Row(
                        children: [
                          Expanded(
                            child: TsCheckbox(
                              value: _rememberMe,
                              label: 'Ghi nhớ đăng nhập',
                              onChanged: isBusy ? null : (v) => setState(() => _rememberMe = v),
                            ),
                          ),
                          TextButton(
                            onPressed: isBusy ? null : widget.onForgotPasswordTap,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Quên mật khẩu?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      if (_errorMessage != null) ...[
                        AuthStatusBanner(
                          message: _errorMessage!,
                          isError: true,
                        ),
                        const SizedBox(height: AppSpacing.space16),
                      ],
                      PrimaryButton(
                        label: 'Đăng nhập',
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        onPressed: isBusy ? null : _handleLogin,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      const TsOrDivider(),
                      const SizedBox(height: AppSpacing.space24),
                      TsSocialButton(
                        label: 'Tiếp tục với Google',
                        icon: Icons.g_mobiledata_rounded,
                        isLoading: _isGoogleLoading,
                        onPressed: isBusy ? null : _handleGoogleLogin,
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      TsSocialButton(
                        label: 'Tiếp tục với GitHub',
                        icon: Icons.code_rounded,
                        isLoading: _isGitHubLoading,
                        onPressed: isBusy ? null : _handleGitHubLogin,
                      ),
                      const SizedBox(height: AppSpacing.space32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Chưa có tài khoản?',
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space4),
                          GestureDetector(
                            onTap: isBusy ? null : widget.onRegisterTap,
                            child: Text(
                              'Đăng ký',
                              style: AppTypography.label.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(width: AppSpacing.space4),
                          Flexible(
                            child: Text(
                              'Dữ liệu được mã hoá đầu cuối',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
