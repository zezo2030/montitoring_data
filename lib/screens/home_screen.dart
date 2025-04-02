import 'package:flutter/material.dart';
import 'dart:async';
import '../services/data_usage_service.dart';
import '../widgets/data_usage_stream_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _limitController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _updateDataManually() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DataUsageService.getCurrentDataUsage();
      await DataUsageService.getTodayDataUsage();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحديث البيانات');
    }
  }

  void _showDailyLimitDialog(double currentLimit) {
    _limitController.text = currentLimit > 0 ? currentLimit.toString() : '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعيين الحد اليومي'),
        content: TextField(
          controller: _limitController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الحد اليومي (ميجابايت)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _setDailyLimit();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _setDailyLimit() async {
    final limitText = _limitController.text.trim();
    if (limitText.isEmpty) {
      _showErrorSnackBar('الرجاء إدخال قيمة صحيحة');
      return;
    }

    final limit = double.tryParse(limitText);
    if (limit == null || limit < 0) {
      _showErrorSnackBar('الرجاء إدخال قيمة صحيحة');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await DataUsageService.setDailyDataLimit(limit);
      if (result) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessSnackBar('تم تعيين الحد اليومي بنجاح');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('فشل تعيين الحد اليومي');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تعيين الحد اليومي');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقب استهلاك البيانات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _updateDataManually,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : DataUsageStreamWidget(
                builder: (context, dataUpdate) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // بطاقة عرض استخدام البيانات
                        DataUsageCard(
                          data: dataUpdate,
                          onRefresh: _updateDataManually,
                        ),

                        const SizedBox(height: 16),

                        // زر تعيين الحد اليومي
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('تعيين الحد اليومي'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () =>
                              _showDailyLimitDialog(dataUpdate.dailyLimit),
                        ),

                        const SizedBox(height: 24),

                        // معلومات إضافية
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ملاحظات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• يتم تحديث البيانات تلقائياً كل 15 ثانية في الخلفية',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• هذا التطبيق يراقب استخدام بيانات الواي فاي فقط',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• تأكد من منح التطبيق الأذونات اللازمة للوصول إلى إحصائيات الاستخدام',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateDataManually,
        tooltip: 'تحديث البيانات',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
