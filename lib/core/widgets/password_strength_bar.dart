import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Đánh giá độ mạnh mật khẩu theo 4 mức, hiển thị bằng màu ngữ nghĩa
/// của TokenScope (lỗi → cảnh báo → chủ đạo → thành công).
enum PasswordStrength { empty, weak, medium, strong, veryStrong }

extension PasswordStrengthX on PasswordStrength {
  String get label => switch (this) {
    PasswordStrength.empty => '',
    PasswordStrength.weak => 'Yếu',
    PasswordStrength.medium => 'Trung bình',
    PasswordStrength.strong => 'Mạnh',
    PasswordStrength.veryStrong => 'Rất mạnh',
  };

  Color get color => switch (this) {
    PasswordStrength.empty => AppColors.border,
    PasswordStrength.weak => AppColors.error,
    PasswordStrength.medium => AppColors.warning,
    PasswordStrength.strong => AppColors.primary,
    PasswordStrength.veryStrong => AppColors.success,
  };

  /// Số thanh đã lấp đầy (0..4).
  int get level => switch (this) {
    PasswordStrength.empty => 0,
    PasswordStrength.weak => 1,
    PasswordStrength.medium => 2,
    PasswordStrength.strong => 3,
    PasswordStrength.veryStrong => 4,
  };
}

/// Tính độ mạnh mật khẩu.
PasswordStrength evaluatePasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.empty;

  var score = 0;
  if (password.length >= 6) score++;
  if (password.length >= 10) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

  if (score <= 2) return PasswordStrength.weak;
  if (score == 3) return PasswordStrength.medium;
  if (score == 4) return PasswordStrength.strong;
  return PasswordStrength.veryStrong;
}

/// Thanh hiển thị độ mạnh mật khẩu.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = evaluatePasswordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < strength.level
                        ? strength.color
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: AppSpacing.space4),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          strength.label,
          style: AppTypography.bodySmall.copyWith(
            color: strength.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
