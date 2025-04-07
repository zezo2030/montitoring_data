class DeviceUsage {
  final String deviceId;
  final String deviceName;
  final int dataUsage; // بالميجابايت
  final Map<String, int> appUsage;
  final DateTime lastUpdated;
  final int dailyLimit;

  DeviceUsage({
    required this.deviceId,
    required this.deviceName,
    required this.dataUsage,
    required this.appUsage,
    required this.lastUpdated,
    required this.dailyLimit,
  });

  // إنشاء من Firebase JSON
  factory DeviceUsage.fromJson(String id, Map<String, dynamic> json) {
    final Map<String, dynamic> rawAppUsage = json['appUsage'] ?? {};
    final Map<String, int> appUsageMap = {};

    // تحويل بيانات استخدام التطبيقات
    rawAppUsage.forEach((key, value) {
      if (value is int) {
        appUsageMap[key] = value;
      }
    });

    return DeviceUsage(
      deviceId: id,
      deviceName: json['deviceName'] ?? 'جهاز غير معروف',
      dataUsage: json['dataUsage'] ?? 0,
      appUsage: appUsageMap,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : DateTime.now(),
      dailyLimit: json['settings']?['dailyLimit'] ?? 1000,
    );
  }

  // تحويل إلى JSON للحفظ في Firebase
  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'dataUsage': dataUsage,
      'appUsage': appUsage,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'settings': {
        'dailyLimit': dailyLimit,
      },
    };
  }

  // حساب النسبة المئوية للاستخدام من الحد اليومي
  double get usagePercentage {
    if (dailyLimit <= 0) return 0;
    return (dataUsage / dailyLimit).clamp(0.0, 1.0);
  }

  // التحقق مما إذا كان قد تم تجاوز الحد
  bool get isOverLimit => dataUsage > dailyLimit;

  // نسخة محدثة من الكائن
  DeviceUsage copyWith({
    String? deviceName,
    int? dataUsage,
    Map<String, int>? appUsage,
    DateTime? lastUpdated,
    int? dailyLimit,
  }) {
    return DeviceUsage(
      deviceId: this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      dataUsage: dataUsage ?? this.dataUsage,
      appUsage: appUsage ?? this.appUsage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}
