import 'package:flutter/material.dart';
import 'services/permissions_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراقب استهلاك البيانات',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      home: const PermissionsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isCheckingPermissions = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // تأخير بسيط ليظهر شاشة البداية
    await Future.delayed(const Duration(seconds: 1));

    bool hasPermissions = await PermissionsService.checkAllPermissions(context);

    if (mounted) {
      setState(() {
        _isCheckingPermissions = false;
        _hasPermissions = hasPermissions;
      });
    }

    if (hasPermissions) {
      _navigateToHomeScreen();
    }
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isCheckingPermissions
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('التحقق من الأذونات...'),
                ],
              )
            : !_hasPermissions
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.security,
                        size: 80,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'الأذونات مطلوبة',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          'يحتاج التطبيق إلى بعض الأذونات للعمل بشكل صحيح.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isCheckingPermissions = true;
                          });
                          await _checkPermissions();
                        },
                        child: const Text('طلب الأذونات'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقب استهلاك البيانات'),
      ),
      body: const Center(
        child: Text('الشاشة الرئيسية - تم السماح بجميع الأذونات'),
      ),
    );
  }
}
