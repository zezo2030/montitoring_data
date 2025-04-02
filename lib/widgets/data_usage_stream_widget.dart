import 'package:flutter/material.dart';
import '../services/data_usage_service.dart';

class DataUsageStreamWidget extends StatefulWidget {
  final Widget Function(BuildContext, DataUsageUpdate) builder;

  const DataUsageStreamWidget({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<DataUsageStreamWidget> createState() => _DataUsageStreamWidgetState();
}

class _DataUsageStreamWidgetState extends State<DataUsageStreamWidget> {
  late Stream<DataUsageUpdate> _dataStream;

  @override
  void initState() {
    super.initState();
    _dataStream = DataUsageService.getDataUsageStream();

    // التأكد من بدء خدمة المراقبة
    _ensureMonitoringIsActive();
  }

  Future<void> _ensureMonitoringIsActive() async {
    final isActive = await DataUsageService.isMonitoringActive();
    if (!isActive) {
      await DataUsageService.startMonitoringDataUsage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DataUsageUpdate>(
      stream: _dataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ??
            DataUsageUpdate(
              currentUsage: 0,
              todayUsage: 0,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              dailyLimit: 0,
            );

        return widget.builder(context, data);
      },
    );
  }
}

// مكون لعرض بطاقة استخدام البيانات
class DataUsageCard extends StatelessWidget {
  final DataUsageUpdate data;
  final VoidCallback? onRefresh;

  const DataUsageCard({
    Key? key,
    required this.data,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dailyPercentage = data.dailyLimit > 0
        ? (data.todayUsage / data.dailyLimit * 100).clamp(0, 100)
        : 0.0;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(data.timestamp);
    final timeDifference = DateTime.now().difference(lastUpdateTime);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'استخدام البيانات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'تحديث البيانات',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'اليوم',
              '${data.todayUsage.toStringAsFixed(2)} ميجابايت',
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'آخر 5 دقائق',
              '${data.currentUsage.toStringAsFixed(2)} ميجابايت',
              Icons.access_time,
            ),
            if (data.dailyLimit > 0) ...[
              const SizedBox(height: 16),
              Text(
                'الحد اليومي: ${data.dailyLimit.toStringAsFixed(2)} ميجابايت (${dailyPercentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: dailyPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  dailyPercentage > 90
                      ? Colors.red
                      : dailyPercentage > 75
                          ? Colors.orange
                          : Colors.green,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'آخر تحديث: ${_formatUpdateTime(timeDifference)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatUpdateTime(Duration difference) {
    if (difference.inSeconds < 60) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'منذ ${difference.inHours} ساعة';
    }
  }
}
