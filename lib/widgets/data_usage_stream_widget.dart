import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/data_usage_model.dart';
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

    // Ensure monitoring service is active
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

// Data usage card component
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

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Data Usage',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (onRefresh != null)
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.refresh,
                              color: theme.colorScheme.primary),
                          onPressed: onRefresh,
                          tooltip: 'Refresh Data',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildMetricCard(
                  context,
                  title: 'Today',
                  value: '${data.todayUsage.toStringAsFixed(2)}',
                  subtitle: 'MB',
                  icon: Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _buildMetricCard(
                  context,
                  title: 'Last 3 hours',
                  value: '${data.currentUsage.toStringAsFixed(2)}',
                  subtitle: 'MB',
                  icon: Icons.access_time,
                  color: theme.colorScheme.tertiary,
                ),
                if (data.dailyLimit > 0) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daily Limit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${data.dailyLimit.toStringAsFixed(2)} MB',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: dailyPercentage / 100,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: dailyPercentage > 90
                                        ? [
                                            Colors.red.shade300,
                                            Colors.red.shade600
                                          ]
                                        : dailyPercentage > 75
                                            ? [
                                                Colors.orange.shade300,
                                                Colors.orange.shade600
                                              ]
                                            : [
                                                theme.colorScheme.secondary,
                                                theme.colorScheme.primary,
                                              ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${dailyPercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: dailyPercentage > 90
                                    ? Colors.red
                                    : dailyPercentage > 75
                                        ? Colors.orange
                                        : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Last update: ${_formatUpdateTime(timeDifference)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatUpdateTime(Duration difference) {
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return '${difference.inHours} hours ago';
    }
  }
}
