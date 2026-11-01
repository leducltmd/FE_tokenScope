import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/ts_text_field.dart';
import '../../providers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../services/mock_auth_service.dart';
import 'auth_header.dart';
import 'auth_status_banner.dart';

/// Màn hình quên mật khẩu — gửi liên kết đặt lại mật khẩu về email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.authService,
    this.controller,
    this.onBack,
  });

  final AuthService? authService;
  final AuthController? controller;
  final VoidCallback? onBack;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final AuthController _controller =
      widget.controller ??
      AuthController(service: widget.authService ?? MockAuthService());

  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      setState(() => _errorMessage = 'Email không hợp lệ.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final result = await _controller.forgotPassword(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _sent = result;
      _errorMessage = result ? null : _controller.error;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                child: AuthHeader(
                  title: 'Quên mật khẩu',
                  subtitle:
                      'Nhập email đã đăng ký, chúng tôi sẽ gửi liên kết đặt lại mật khẩu.',
                  showBackButton: true,
                  onBack: widget.onBack,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space24,
                  AppSpacing.screenPadding,
                  AppSpacing.space32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TsTextField(
                      label: 'Email',
                      hint: 'ban@congty.com',
                      icon: Icons.alternate_email_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSend(),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    if (_errorMessage != null) ...[
                      AuthStatusBanner(
                        message: _errorMessage!,
                        isError: true,
                      ),
                      const SizedBox(height: AppSpacing.space16),
                    ],
                    if (_sent) ...[
                      AuthStatusBanner(
                        message:
                            'Đã gửi liên kết đặt lại mật khẩu tới $_emailController.text.',
                        isError: false,
                      ),
                      const SizedBox(height: AppSpacing.space16),
                    ],
                    PrimaryButton(
                      label: 'Gửi liên kết đặt lại',
                      icon: Icons.send_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleSend,
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadius.mediumRadius,
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          Expanded(
                            child: Text(
                              'Liên kết đặt lại mật khẩu sẽ hết hạn sau 30 phút.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
