import 'package:flutter/material.dart';

/// فئة مساعدة تحتوي على دوال للتحقق من صحة البيانات المدخلة
class ValidationUtils {
  /// التحقق من صحة البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }

    return null;
  }

  /// التحقق من صحة كلمة المرور
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }

    if (value.length < minLength) {
      return 'كلمة المرور يجب أن تكون $minLength أحرف على الأقل';
    }

    // للتحقق من قوة كلمة المرور (اختياري)
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters =
        value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasDigits || !hasSpecialCharacters) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير ورقم وحرف خاص';
    }

    return null;
  }

  /// التحقق من صحة اسم المستخدم
  static String? validateUsername(String? value, {int minLength = 3}) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال اسم المستخدم';
    }

    if (value.length < minLength) {
      return 'اسم المستخدم يجب أن يكون $minLength أحرف على الأقل';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام وشرطة سفلية فقط';
    }

    return null;
  }

  /// التحقق من صحة الاسم الكامل
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الاسم الكامل';
    }

    if (value.length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }

    return null;
  }

  /// التحقق من صحة رقم الهاتف
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    // نمط رقم الهاتف السعودي
    final saudiRegExp = RegExp(r'^(05)[0-9]{8}$');
    // نمط دولي عام
    final internationalRegExp = RegExp(r'^\+[0-9]{10,15}$');

    if (!saudiRegExp.hasMatch(value) && !internationalRegExp.hasMatch(value)) {
      return 'الرجاء إدخال رقم هاتف صحيح';
    }

    return null;
  }

  /// التحقق من تطابق كلمتي المرور
  static String? validatePasswordMatch(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'الرجاء تأكيد كلمة المرور';
    }

    if (password != confirmPassword) {
      return 'كلمتا المرور غير متطابقتين';
    }

    return null;
  }

  /// التحقق من قبول الشروط والأحكام
  static String? validateTermsAccepted(bool? value) {
    if (value == null || !value) {
      return 'يجب الموافقة على الشروط والأحكام للمتابعة';
    }

    return null;
  }

  /// التحقق من صحة الرمز البريدي
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الرمز البريدي';
    }

    // نمط الرمز البريدي السعودي (5 أرقام)
    final postalCodeRegExp = RegExp(r'^[0-9]{5}$');

    if (!postalCodeRegExp.hasMatch(value)) {
      return 'الرجاء إدخال رمز بريدي صحيح (5 أرقام)';
    }

    return null;
  }
}
