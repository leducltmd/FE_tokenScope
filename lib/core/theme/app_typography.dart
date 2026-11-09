import 'package:flutter/material.dart';

/// 02 · KIỂU CHỮ — Inter với 6 cấp kiểu chữ.
///
/// Phân cấp rõ ràng để đọc nhanh số liệu, cảnh báo và thông tin sử dụng.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  /// H1 · Tiêu đề lớn — 28px · Đậm (700).
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: Color(0xFF111827),
  );

  /// H2 · Tiêu đề mục — 22px · Đậm vừa (600).
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
    color: Color(0xFF111827),
  );

  /// H3 · Tiêu đề nhóm — 18px · Đậm vừa (600).
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
    color: Color(0xFF111827),
  );

  /// Nội dung — 16px · Thường (400).
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xFF111827),
  );

  /// Nội dung vừa — alias cho body (16px).
  static const TextStyle bodyMedium = body;

  /// Nội dung nhỏ — 14px · Thường (400).
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xFF475569),
  );

  /// Nhãn — 14px · Trung bình (500).
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFF111827),
  );
}
