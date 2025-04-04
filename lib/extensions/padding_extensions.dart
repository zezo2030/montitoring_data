import 'package:flutter/material.dart';

/// امتداد للـ Widget لتسهيل إضافة الـ padding بطريقة متسقة
extension PaddingExtensions on Widget {
  /// إضافة padding متساوي على جميع الجوانب
  Widget paddingAll(double value) {
    return Padding(
      padding: EdgeInsets.all(value),
      child: this,
    );
  }

  /// إضافة padding عمودي (أعلى وأسفل)
  Widget paddingVertical(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: value),
      child: this,
    );
  }

  /// إضافة padding أفقي (يمين ويسار)
  Widget paddingHorizontal(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: value),
      child: this,
    );
  }

  /// إضافة padding متناظر (عمودي وأفقي)
  Widget paddingSymmetric({double vertical = 0.0, double horizontal = 0.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: vertical,
        horizontal: horizontal,
      ),
      child: this,
    );
  }

  /// إضافة padding على كل جانب بشكل منفصل
  Widget paddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: this,
    );
  }

  /// إضافة padding من الجانب الأيسر فقط
  Widget paddingLeft(double value) {
    return Padding(
      padding: EdgeInsets.only(left: value),
      child: this,
    );
  }

  /// إضافة padding من الجانب الأيمن فقط
  Widget paddingRight(double value) {
    return Padding(
      padding: EdgeInsets.only(right: value),
      child: this,
    );
  }

  /// إضافة padding من الأعلى فقط
  Widget paddingTop(double value) {
    return Padding(
      padding: EdgeInsets.only(top: value),
      child: this,
    );
  }

  /// إضافة padding من الأسفل فقط
  Widget paddingBottom(double value) {
    return Padding(
      padding: EdgeInsets.only(bottom: value),
      child: this,
    );
  }

  /// إضافة padding بقيم محددة مسبقاً (صغير)
  Widget get paddingSmall {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: this,
    );
  }

  /// إضافة padding بقيم محددة مسبقاً (متوسط)
  Widget get paddingMedium {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: this,
    );
  }

  /// إضافة padding بقيم محددة مسبقاً (كبير)
  Widget get paddingLarge {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: this,
    );
  }

  /// إضافة padding بقيم محددة مسبقاً (كبير جداً)
  Widget get paddingXLarge {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: this,
    );
  }

  /// إضافة padding لعناصر النموذج (forms)
  Widget get formFieldPadding {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: this,
    );
  }

  /// إضافة padding للبطاقات (cards)
  Widget get cardPadding {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: this,
    );
  }

  /// إضافة padding للأزرار (buttons)
  Widget get buttonPadding {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      child: this,
    );
  }

  /// إضافة padding للقوائم (list items)
  Widget get listItemPadding {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: this,
    );
  }

  /// إضافة padding لعناصر الشاشة (screen edges)
  Widget get screenPadding {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: this,
    );
  }
}
