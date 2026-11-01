import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Biểu tượng TokenScope: hình khe nước (token) đặt trong khung bo góc.
class TsLogo extends StatelessWidget {
  const TsLogo({super.key, this.size = 48, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: CustomPaint(painter: _TokenPainter()),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: AppSpacing.space12),
        const Text(
          'TokenScope',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _TokenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.24, h * 0.66)
      ..lineTo(w * 0.40, h * 0.38)
      ..lineTo(w * 0.56, h * 0.56)
      ..lineTo(w * 0.72, h * 0.30);

    canvas.drawPath(path, paint);

    // Điểm nhấn "scope"
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.30),
      size.width * 0.075,
      Paint()..color = AppColors.onPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
