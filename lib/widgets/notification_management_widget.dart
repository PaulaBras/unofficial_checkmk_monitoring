import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/enhanced_notification_service.dart';
import '../utils/notification_constants.dart';

/// Widget for managing notification settings and testing
class NotificationManagementWidget extends StatefulWidget {
  const NotificationManagementWidget({Key? key}) : super(key: key);

  @override
  State<NotificationManagementWidget> createState() =>
      _NotificationManagementWidgetState();
}

class _NotificationManagementWidgetState
    extends State<NotificationManagementWidget> {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();
  bool _isMonitoring = false;
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNotificationSettings();
  }

  Future<void> _initializeNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.initialize();
      // You might want to load these from SharedPreferences
      _notificationsEnabled = true;
      _isMonitoring = false;
    } catch (e) {
      _showErrorSnackBar('Failed to initialize notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Attempt-Based Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Monitor services and hosts for when current attempts match max attempts. '
              'Checks every minute for problematic states.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20),
            _buildNotificationToggle(),
            const SizedBox(height: 16),
            _buildMonitoringToggle(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildStatusInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Row(
      children: [
        Icon(
          _notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: _notificationsEnabled ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enable Notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Receive alerts when attempts reach maximum',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: _notificationsEnabled,
          onChanged: _onNotificationsToggled,
        ),
      ],
    );
  }

  Widget _buildMonitoringToggle() {
    return Row(
      children: [
        Icon(
          _isMonitoring ? Icons.monitor_heart : Icons.monitor_heart_outlined,
          color: _isMonitoring ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Background Monitoring',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Check every ${NotificationConstants.backgroundCheckInterval} seconds',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: _isMonitoring && _notificationsEnabled,
          onChanged: _notificationsEnabled ? _onMonitoringToggled : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _notificationsEnabled ? _onTestNotification : null,
            icon: const Icon(Icons.send),
            label: const Text('Test Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _onRequestPermissions,
            icon: const Icon(Icons.security),
            label: const Text('Permissions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Monitoring Configuration',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Check Frequency',
              '${NotificationConstants.backgroundCheckInterval} seconds'),
          _buildInfoRow('Host States', 'DOWN, UNREACHABLE'),
          _buildInfoRow('Service States', 'WARNING, CRITICAL, UNKNOWN'),
          _buildInfoRow('Trigger Condition', 'Current Attempt = Max Attempts'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationsToggled(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.setNotificationsEnabled(enabled);
      setState(() {
        _notificationsEnabled = enabled;
        if (!enabled) {
          _isMonitoring = false;
        }
      });

      _showSuccessSnackBar(
          enabled ? 'Notifications enabled' : 'Notifications disabled');
    } catch (e) {
      _showErrorSnackBar('Failed to toggle notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMonitoringToggled(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      if (enabled) {
        await _notificationService.startMonitoring();
      } else {
        await _notificationService.stopMonitoring();
      }

      setState(() => _isMonitoring = enabled);

      _showSuccessSnackBar(enabled
          ? 'Background monitoring started'
          : 'Background monitoring stopped');
    } catch (e) {
      _showErrorSnackBar('Failed to toggle monitoring: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onTestNotification() async {
    try {
      await _notificationService.sendTestNotification();
      _showSuccessSnackBar('Test notification sent');

      // Provide haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Failed to send test notification: $e');
    }
  }

  Future<void> _onRequestPermissions() async {
    try {
      final granted = await _notificationService.requestPermissions();

      if (granted) {
        _showSuccessSnackBar('Notification permissions granted');
      } else {
        _showErrorSnackBar('Notification permissions denied');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to request permissions: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
