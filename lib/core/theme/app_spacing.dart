import 'package:flutter/material.dart';

/// 03 · KHOẢNG CÁCH — Thang đo cho khoảng đệm và khoảng cách.
abstract final class AppSpacing {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  /// Khoảng cách lề ngang chuẩn của màn hình.
  static const double screenPadding = 24;
}

/// 04 · BO GÓC — Bốn mức bo góc tạo sự nhất quán cho các bề mặt.
abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;

  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));
  static const BorderRadius extraLargeRadius =
      BorderRadius.all(Radius.circular(extraLarge));
}
