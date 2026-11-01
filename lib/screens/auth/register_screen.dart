import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ts_checkbox.dart';
import '../../core/widgets/ts_date_field.dart';
import '../../core/widgets/password_strength_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/ts_text_field.dart';
import '../../providers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../services/mock_auth_service.dart';
import 'auth_header.dart';
import 'auth_status_banner.dart';

/// Màn hình đăng ký TokenScope.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.authService,
    this.controller,
    this.onLoginTap,
    this.onRegistered,
  });

  final AuthService? authService;
  final AuthController? controller;
  final VoidCallback? onLoginTap;

  /// Được gọi sau khi đăng ký thành công.
  final VoidCallback? onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthController _controller =
      widget.controller ??
      AuthController(service: widget.authService ?? MockAuthService());

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _errorMessage;

  /// Ngày sinh ở định dạng YYYY-MM-DD.
  String? _birthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _validate() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập họ và tên.');
      return;
    }
    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w.+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Email không hợp lệ.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(
        () => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.',
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }
    if (_birthDate == null) {
      setState(() => _errorMessage = 'Vui lòng chọn ngày sinh.');
      return;
    }
    if (!_acceptedTerms) {
      setState(
        () => _errorMessage = 'Bạn cần đồng ý với Điều khoản sử dụng.',
      );
      return;
    }
    setState(() => _errorMessage = null);
  }

  Future<void> _handleRegister() async {
    _validate();
    if (_errorMessage != null) return;

    setState(() => _isLoading = true);

    final result = await _controller.register(
      name: _nameController.text.trim(),
      birthDate: _birthDate!,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = result ? null : _controller.error;
    });

    if (result) {
      widget.onRegistered?.call();
    }
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
                  title: 'Tạo tài khoản',
                  subtitle:
                      'Bắt đầu giám sát chi phí API của bạn trong vài phút.',
                  showBackButton: true,
                  onBack: widget.onLoginTap,
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
                        label: 'Họ và tên',
                        hint: 'Nguyễn Văn A',
                        icon: Icons.person_outline_rounded,
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      TsDateField(
                        label: 'Ngày sinh',
                        value: _birthDate,
                        helperText: 'Dùng để gợi ý báo cáo và lưu trữ hồ sơ.',
                        onChanged: (value) => setState(() => _birthDate = value),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      TsTextField(
                        label: 'Email',
                        hint: 'ban@congty.com',
                        icon: Icons.alternate_email_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      TsTextField(
                        label: 'Mật khẩu',
                        hint: 'Tối thiểu 6 ký tự',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      PasswordStrengthBar(password: _passwordController.text),
                      const SizedBox(height: AppSpacing.space16),
                      TsTextField(
                        label: 'Xác nhận mật khẩu',
                        hint: 'Nhập lại mật khẩu',
                        icon: Icons.lock_reset_rounded,
                        controller: _confirmController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleRegister(),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      TsCheckbox(
                        value: _acceptedTerms,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        onChanged: (v) => setState(() => _acceptedTerms = v),
                        labelBuilder: const TextSpan(
                          style: AppTypography.bodySmall,
                          children: [
                            TextSpan(text: 'Tôi đồng ý với '),
                            TextSpan(
                              text: 'Điều khoản sử dụng',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: ' và '),
                            TextSpan(
                              text: 'Chính sách bảo mật',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: ' của TokenScope.'),
                          ],
                        ),
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
                        label: 'Tạo tài khoản',
                        icon: Icons.person_add_alt_rounded,
                        isLoading: _isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: AppSpacing.space32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Đã có tài khoản?',
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space4),
                          GestureDetector(
                            onTap: widget.onLoginTap,
                            child: Text(
                              'Đăng nhập',
                              style: AppTypography.label.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
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
