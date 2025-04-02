// صنف لتمثيل تحديث بيانات الاستخدام
class DataUsageUpdate {
  final double
  currentUsage; // استخدام البيانات الحالي (آخر 5 دقائق) بالميجابايت
  final double todayUsage; // استخدام البيانات اليومي بالميجابايت
  final int timestamp; // طابع الوقت للتحديث
  final double dailyLimit; // الحد اليومي بالميجابايت

  DataUsageUpdate({
    required this.currentUsage,
    required this.todayUsage,
    required this.timestamp,
    required this.dailyLimit,
  });
}