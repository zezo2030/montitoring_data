import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/app_data_usage_service.dart';
import '../services/app_icon_service.dart';

class AppsUsageScreen extends StatefulWidget {
  const AppsUsageScreen({Key? key}) : super(key: key);

  @override
  _AppsUsageScreenState createState() => _AppsUsageScreenState();
}

class _AppsUsageScreenState extends State<AppsUsageScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appsData = [];
  int _selectedTimeRange = 24; // افتراضي: آخر 24 ساعة
  late TabController _tabController;
  final Map<String, Image?> _appIcons = {};
  final Map<String, bool> _loadingIcons = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await AppDataUsageService.getSortedAppsDataUsage(
          timeRange: _selectedTimeRange);

      setState(() {
        _appsData = apps;
        _isLoading = false;
      });

      // تحميل أيقونات التطبيقات مسبقاً
      _preloadAppIcons();
    } catch (e) {
      print('خطأ في تحميل بيانات التطبيقات: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // تحميل أيقونات التطبيقات مسبقاً
  Future<void> _preloadAppIcons() async {
    for (final app in _appsData) {
      final packageName = app['packageName'] as String;

      if (!_appIcons.containsKey(packageName) &&
          !_loadingIcons.containsKey(packageName)) {
        // وضع علامة بأننا نقوم بتحميل الأيقونة لمنع التحميل المزدوج
        _loadingIcons[packageName] = true;

        try {
          final icon = await AppIconService.getAppIcon(packageName);

          // تحديث الواجهة فقط إذا كانت الشاشة لا تزال مرئية
          if (mounted) {
            setState(() {
              _appIcons[packageName] = icon;
              _loadingIcons.remove(packageName);
            });
          }
        } catch (e) {
          print('خطأ في تحميل أيقونة التطبيق $packageName: $e');
          if (mounted) {
            setState(() {
              _loadingIcons.remove(packageName);
            });
          }
        }
      }
    }
  }

  void _changeTimeRange(int hours) {
    if (_selectedTimeRange != hours) {
      setState(() {
        _selectedTimeRange = hours;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('استخدام التطبيقات'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.7),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'واي فاي'),
            Tab(text: 'بيانات الجوال'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 120), // تعويض عن AppBar والمؤشرات

            // أزرار تحديد النطاق الزمني
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                color: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _timeFilterButton('3 ساعات', 3),
                      _timeFilterButton('24 ساعة', 24),
                      _timeFilterButton('7 أيام', 168), // 7*24 = 168 ساعة
                    ],
                  ),
                ),
              ),
            ),

            // عرض البيانات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTotalUsageList(),
                        _buildWifiUsageList(),
                        _buildMobileUsageList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeFilterButton(String text, int hours) {
    final theme = Theme.of(context);
    final isSelected = _selectedTimeRange == hours;

    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextButton(
        onPressed: () => _changeTimeRange(hours),
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalUsageList() {
    if (_appsData.isEmpty) {
      return _buildEmptyView();
    }

    return _buildAppsList(
        _appsData, (app) => (app['totalUsageMB'] as num).toDouble());
  }

  Widget _buildWifiUsageList() {
    if (_appsData.isEmpty) {
      return _buildEmptyView();
    }

    // ترتيب التطبيقات حسب استخدام الواي فاي
    final wifiSortedApps = List<Map<String, dynamic>>.from(_appsData);
    wifiSortedApps.sort((a, b) => (b['wifiUsageMB'] as num)
        .toDouble()
        .compareTo((a['wifiUsageMB'] as num).toDouble()));

    return _buildAppsList(
        wifiSortedApps, (app) => (app['wifiUsageMB'] as num).toDouble(),
        networkType: 'واي فاي');
  }

  Widget _buildMobileUsageList() {
    if (_appsData.isEmpty) {
      return _buildEmptyView();
    }

    // ترتيب التطبيقات حسب استخدام بيانات الجوال
    final mobileSortedApps = List<Map<String, dynamic>>.from(_appsData);
    mobileSortedApps.sort((a, b) => (b['mobileUsageMB'] as num)
        .toDouble()
        .compareTo((a['mobileUsageMB'] as num).toDouble()));

    return _buildAppsList(
        mobileSortedApps, (app) => (app['mobileUsageMB'] as num).toDouble(),
        networkType: 'بيانات الجوال');
  }

  Widget _buildEmptyView() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد بيانات متاحة',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppsList(List<Map<String, dynamic>> apps,
      double Function(Map<String, dynamic>) getUsage,
      {String? networkType}) {
    // تصفية التطبيقات ذات استخدام البيانات الصفري
    final filteredApps = apps.where((app) => getUsage(app) > 0).toList();

    if (filteredApps.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final app = filteredApps[index];
        final packageName = app['packageName'] as String;
        final appName = app['appName'] as String;
        final usageMB = getUsage(app);

        return _buildAppUsageCard(
          index: index,
          appName: appName,
          usageMB: usageMB,
          packageName: packageName,
          networkType: networkType,
        );
      },
    );
  }

  Widget _buildAppUsageCard({
    required int index,
    required String appName,
    required double usageMB,
    required String packageName,
    String? networkType,
  }) {
    final theme = Theme.of(context);

    // التحقق مما إذا كان التطبيق هو تطبيق نظام
    final isSystemApp = _appsData.any(
        (app) => app['packageName'] == packageName && app['isSystem'] == true);

    // تنسيق استخدام البيانات
    final formattedUsage = usageMB >= 1024
        ? '${(usageMB / 1024).toStringAsFixed(2)} جيجابايت'
        : '${usageMB.toStringAsFixed(2)} ميجابايت';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isSystemApp
                      ? Colors.blue.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                  isSystemApp
                      ? Colors.lightBlue.withOpacity(0.4)
                      : Colors.white.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSystemApp
                    ? Colors.blue.withOpacity(0.5)
                    : Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _loadingIcons.containsKey(packageName)
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        ),
                      )
                    : _appIcons.containsKey(packageName) &&
                            _appIcons[packageName] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _appIcons[packageName],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                appName.isNotEmpty
                                    ? appName[0].toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      appName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isSystemApp)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'نظام',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    networkType != null
                        ? '$networkType • $packageName'
                        : packageName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSystemApp ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSystemApp
                        ? [Colors.blue[700]!, Colors.blue[500]!]
                        : [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formattedUsage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
