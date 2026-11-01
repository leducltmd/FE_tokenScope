import 'package:flutter/material.dart';

/// 05 · ĐỘ NỔI — Bóng đổ phân tách các lớp giao diện mà không làm nhiễu
/// thông tin giám sát. Độ lan luôn bằng 0px.
abstract final class AppElevation {
  static const double blur = 0;

  /// Cấp 0 · Bề mặt mặc định — không có bóng đổ.
  static const List<BoxShadow> level0 = [];

  /// Cấp 1 · Thẻ dữ liệu — rgba(17,24,39,0.06).
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x0F111827), offset: Offset(0, 2), blurRadius: 8),
  ];

  /// Cấp 2 · Bảng nổi — rgba(17,24,39,0.10).
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x1A111827), offset: Offset(0, 4), blurRadius: 16),
  ];

  /// Cấp 3 · Hộp thoại — rgba(17,24,39,0.14).
  static const List<BoxShadow> level3 = [
    BoxShadow(color: Color(0x24111827), offset: Offset(0, 8), blurRadius: 24),
  ];
}
