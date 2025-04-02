import 'package:flutter/material.dart';

import '../services/permissions_service.dart';
import 'home_screen.dart';

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

  // معالجة تحديث حالة الأذونات
  void _updatePermissionsAndNavigate(bool hasPermissions) {
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

  Future<void> _checkPermissions() async {
    // تأخير بسيط ليظهر شاشة البداية
    await Future.delayed(const Duration(seconds: 1));

    // التحقق أولاً من الأذونات
    bool hasPermissions = await PermissionsService.checkAllPermissions(context);

    if (hasPermissions) {
      _updatePermissionsAndNavigate(true);
    } else {
      // طلب الأذونات تلقائيًا إذا لم تكن ممنوحة
      hasPermissions = await PermissionsService.requestAllPermissions(context);
      _updatePermissionsAndNavigate(hasPermissions);
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

                          bool hasPermissions =
                              await PermissionsService.requestAllPermissions(
                                  context);
                          _updatePermissionsAndNavigate(hasPermissions);
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
