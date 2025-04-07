import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ABRAR/widgets/login_form_widget.dart';
import 'package:ABRAR/extensions/gradient_extensions.dart';
import 'package:ABRAR/extensions/padding_extensions.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GradientExtensions.appGradient(context),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        LoginFormWidget(
                          onLogin: () {
                            // استخدام Go Router للانتقال إلى الصفحة الرئيسية
                            context.pushReplacementNamed('home');
                          },
                          onForgotPassword: () {
                            // منطق نسيت كلمة المرور
                          },
                        ).paddingTop(30),
                        _buildSignupSection(context),
                      ],
                    ),
                  ).paddingLarge,
                ),
              ).paddingAll(24),
            ),
          ),
        ),
      ),
    );
  }

  // استخراج جزء الرأس (أيقونة القفل والعنوان)
  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.lock,
          size: 70,
          color: Colors.white,
        ).paddingTop(24),
        Text(
          'تسجيل الدخول',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ).paddingTop(20),
      ],
    );
  }

  // استخراج جزء الذيل (إنشاء حساب جديد)
  Widget _buildSignupSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            // استخدام Go Router للانتقال إلى صفحة التسجيل
            context.goNamed('signup');
          },
          child: Text(
            'إنشاء حساب',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    ).paddingBottom(24);
  }
}
