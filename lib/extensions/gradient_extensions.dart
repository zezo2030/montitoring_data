import 'package:flutter/material.dart';

/// امتداد لإضافة طرق مساعدة للتدرجات اللونية
extension GradientExtensions on LinearGradient {
  /// إنشاء تدرج من الألوان الأساسية للتطبيق
  static LinearGradient appGradient(BuildContext context) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Theme.of(context).colorScheme.primary.withOpacity(0.8),
        Theme.of(context).colorScheme.secondary.withOpacity(0.9),
        Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
      ],
    );
  }

  /// إنشاء تدرج من الألوان المخصصة
  static LinearGradient custom({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
    List<double>? stops,
    TileMode tileMode = TileMode.clamp,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
      tileMode: tileMode,
    );
  }

  /// إنشاء تدرج من اللون الداكن إلى الفاتح
  static LinearGradient darkToLight(
    Color color, {
    double darkOpacity = 0.9,
    double lightOpacity = 0.4,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        color.withOpacity(darkOpacity),
        color.withOpacity(lightOpacity),
      ],
    );
  }

  /// إنشاء تدرج متعدد الإتجاهات
  static LinearGradient diagonal({
    required Color startColor,
    required Color endColor,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, endColor],
    );
  }

  /// إنشاء تدرج زجاجي (جلاس إيفكت)
  static LinearGradient glass(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.3),
        baseColor.withOpacity(0.1),
      ],
    );
  }
}
