import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:data_usage_monitor/screens/login_screen.dart';
import 'package:data_usage_monitor/screens/signup_screen.dart';
import 'package:data_usage_monitor/screens/permissions_screen.dart';
import 'package:data_usage_monitor/screens/home_screen.dart';
import 'package:data_usage_monitor/screens/apps_usage_screen.dart';

/// إنشاء مثيل من الموجه بناءً على كيوبت المصادقة
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/apps_usage',
        name: 'apps_usage',
        builder: (context, state) => const AppsUsageScreen(),
      ),
    ],
    // // التحقق من حالة المصادقة قبل الانتقال
    // redirect: (context, state) {
    //   // الحصول على حالة المصادقة الحالية
    //   final authState = authCubit.state;
    //   final isAuthenticated = authState.isAuthenticated;

    //   // المسارات التي لا تتطلب مصادقة
    //   final isLoginRoute = state.matchedLocation == '/login';
    //   final isSignupRoute = state.matchedLocation == '/signup';

    //   // إذا لم يكن المستخدم مسجل الدخول وحاول الوصول إلى صفحة محمية
    //   if (!isAuthenticated && !isLoginRoute && !isSignupRoute) {
    //     return '/login';
    //   }

    //   // إذا كان المستخدم مسجل الدخول وحاول الوصول إلى صفحة تسجيل الدخول أو التسجيل
    //   if (isAuthenticated && (isLoginRoute || isSignupRoute)) {
    //     return '/home';
    //   }

    //   // السماح بالاستمرار للمسار المطلوب
    //   return null;
    // },
    // بناء صفحة الخطأ
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'error: ${state.error}',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
