import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/device_usage_sync_service.dart';
import '../services/data_usage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebaseService = FirebaseService();
  final _syncService = DeviceUsageSyncService();
  final _limitController = TextEditingController();
  bool _isLoading = true;
  bool _isConnected = false;
  int _currentLimit = 1000; // Default value
  int _pendingUpdates = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check connection status
      _isConnected = await _firebaseService.checkConnection();

      // Get current daily limit
      int limit;
      if (_isConnected) {
        // Get value from Firebase
        limit = await _firebaseService.getDailyLimit();
      } else {
        // Use locally stored value
        limit = (await DataUsageService.getDailyDataLimit()).toInt();
      }

      // Get pending updates count
      _pendingUpdates = _syncService.getPendingUpdatesCount();

      setState(() {
        _currentLimit = limit;
        _limitController.text = limit.toString();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');

      // Use local value in case of failure
      final localLimit = await DataUsageService.getDailyDataLimit();

      setState(() {
        _currentLimit = localLimit.toInt();
        _limitController.text = _currentLimit.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDailyLimit() async {
    final newLimitText = _limitController.text.trim();
    if (newLimitText.isEmpty) {
      _showErrorMessage('Please enter a valid value');
      return;
    }

    // Convert to integer
    final newLimit = int.tryParse(newLimitText);
    if (newLimit == null || newLimit <= 0) {
      _showErrorMessage('Please enter a positive integer');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update daily limit
      final success = await _syncService.updateDailyLimit(newLimit);

      setState(() {
        _isLoading = false;
        if (success) {
          _currentLimit = newLimit;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Daily limit successfully updated to $newLimit MB')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Daily limit updated locally only, will sync with Firebase when connection is available'),
              backgroundColor: Colors.amber,
            ),
          );
        }
      });
    } catch (e) {
      print('Error updating daily limit: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Error occurred while updating daily limit');
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.trySyncPendingData();
      await _loadSettings(); // Reload data
    } catch (e) {
      print('Sync error: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Error occurred during synchronization');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? Colors.green.shade100
                          : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: _isConnected ? Colors.green : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? 'Connected to Firebase'
                              : 'Not connected to Firebase',
                          style: TextStyle(
                            color: _isConnected
                                ? Colors.green
                                : Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daily limit title
                  const Text(
                    'Set Daily Data Limit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set your daily data usage limit in megabytes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_pendingUpdates > 0) ...[
                    const SizedBox(height: 32),
                    // Pending updates info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sync_problem,
                                  color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Pending Updates: $_pendingUpdates',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'There are local updates that have not been synced with Firebase yet. You can sync now if you are connected to the internet.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isConnected ? _syncNow : null,
                              icon: const Icon(Icons.sync),
                              label: const Text('Sync Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Current limit info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Limit Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Daily Limit:'),
                            Text(
                              '$_currentLimit MB',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Stored in Firebase:'),
                            Text(
                              _isConnected ? 'Yes' : 'No (Local storage only)',
                              style: TextStyle(
                                color: _isConnected
                                    ? Colors.green
                                    : Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }
}
