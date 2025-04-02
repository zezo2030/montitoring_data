import 'package:data_usage_monitor/screens/permissions_screen.dart';
import 'package:data_usage_monitor/screens/home_screen.dart';
import 'package:data_usage_monitor/screens/apps_usage_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Usage Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D7AF6),
          brightness: Brightness.light,
          primary: const Color(0xFF2D7AF6),
          secondary: const Color(0xFF5CE1E6),
          tertiary: const Color(0xFFAD7BFF),
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFF5F8FF),
        cardTheme: CardTheme(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withOpacity(0.8),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF2D7AF6)),
          titleTextStyle: const TextStyle(
            color: Color(0xFF2D7AF6),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Cairo',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D7AF6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2D7AF6),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PermissionsScreen(),
        '/home': (context) => const HomeScreen(),
        '/apps_usage': (context) => const AppsUsageScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
