import 'package:flutter/material.dart';

/// 01 · MÀU SẮC — Bảng màu ngữ nghĩa của TokenScope.
///
/// Dùng bảng màu này để phân biệt rõ hành động, nội dung và trạng thái
/// của API trên toàn bộ ứng dụng.
abstract final class AppColors {
  /// Chủ đạo — nút chính, liên kết, trạng thái chọn.
  static const Color primary = Color(0xFF6366F1);

  /// Chủ đạo đậm — nút khi nhấn, điểm nhấn tương tác.
  static const Color primaryDark = Color(0xFF4338CA);

  /// Xanh than — tiêu đề, nội dung quan trọng.
  static const Color navy = Color(0xFF111827);

  /// Nền — nền trang, vùng dữ liệu tổng quan.
  static const Color background = Color(0xFFF8FAFC);

  /// Bề mặt — thẻ dữ liệu, hộp thoại.
  static const Color surface = Color(0xFFFFFFFF);

  /// Chữ phụ — mô tả, chú thích, thời gian cập nhật.
  static const Color secondaryText = Color(0xFF475569);

  /// Đường viền — viền thẻ, đường phân cách.
  static const Color border = Color(0xFFE5E7EB);

  /// Thành công — API hoạt động, yêu cầu thành công.
  static const Color success = Color(0xFF16A34A);

  /// Cảnh báo — sắp vượt hạn mức, độ trễ tăng.
  static const Color warning = Color(0xFFD97706);

  // ── Bảng màu mở rộng cho giao diện hiện đại ─────────────────────────
  /// tím nhạt — nền chip, huy hiệu mềm.
  static const Color softPurple = Color(0xFFF5F3FF);

  /// tím chủ đạo sáng — điểm nhấn trong thẻ nền tối.
  static const Color violet = Color(0xFF8B5CF6);

  /// xanh biển — biểu đồ, trạng thái trực tiếp.
  static const Color azure = Color(0xFF3B82F6);

  /// kem — nền thẻ cảnh báo ngân sách.
  static const Color cream = Color(0xFFFEF7E4);

  /// viền kem — viền thẻ cảnh báo.
  static const Color creamBorder = Color(0xFFF6E4B4);

  /// xanh trạng thái "Live".
  static const Color live = Color(0xFF12B76A);

  /// nền xanh trạng thái "Live".
  static const Color liveLight = Color(0xFFE7F8F0);

  /// xanh lá nhạt cho biểu đồ nhà cung cấp.
  static const Color emerald = Color(0xFF10B981);

  /// cam nhạt cho biểu đồ nhà cung cấp.
  static const Color tangerine = Color(0xFFF59E0B);

  /// Lỗi — kết nối thất bại, lỗi API.
  static const Color error = Color(0xFFDC2626);

  // ── Màu phụ trợ (sinh ra từ bảng màu gốc) ───────────────────────────
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryBorder = Color(0xFFC7D2FE);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color onPrimary = Color(0xFFFFFFFF);
}
