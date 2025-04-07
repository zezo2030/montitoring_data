import 'package:ABRAR/cubits/cubit/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ABRAR/screens/login_screen.dart';
import 'package:ABRAR/screens/signup_screen.dart';
import 'package:ABRAR/screens/permissions_screen.dart';
import 'package:ABRAR/screens/home_screen.dart';
import 'package:ABRAR/screens/apps_usage_screen.dart';
import 'package:ABRAR/screens/settings_screen.dart';

/// إنشاء مثيل من الموجه بناءً على كيوبت المصادقة
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
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
        builder: (context, state) => BlocProvider(
          create: (context) => HomeCubit(),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/apps_usage',
        name: 'apps_usage',
        builder: (context, state) => const AppsUsageScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
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
