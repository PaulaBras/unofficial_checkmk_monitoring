import 'package:flutter/material.dart';

import '../../widgets/notification_management_widget.dart';
import '../../services/enhanced_notification_service.dart';

/// Screen for managing advanced notification settings
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotificationService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Update notification service based on app lifecycle
    switch (state) {
      case AppLifecycleState.resumed:
        _notificationService.setAppInBackground(false);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _notificationService.setAppInBackground(true);
        break;
      case AppLifecycleState.inactive:
        // Don't change anything for inactive state
        break;
      case AppLifecycleState.hidden:
        _notificationService.setAppInBackground(true);
        break;
    }
  }

  Future<void> _initializeNotificationService() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize notification service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),

            // Enhanced notification management widget
            const NotificationManagementWidget(),

            const SizedBox(height: 20),
            _buildInformationSection(),

            const SizedBox(height: 20),
            _buildTroubleshootingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notification_important,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Attempt-Based Notifications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This enhanced notification system monitors your CheckMK services and hosts, '
              'triggering alerts specifically when the current attempt count reaches the maximum attempts. '
              'This helps you identify persistent issues that require immediate attention.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'How It Works',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoPoint(
              Icons.schedule,
              'Monitoring Frequency',
              'Checks every minute for services and hosts in problematic states.',
            ),
            _buildInfoPoint(
              Icons.trending_up,
              'Trigger Condition',
              'Notifications sent only when current attempts equal max attempts.',
            ),
            _buildInfoPoint(
              Icons.warning,
              'Monitored States',
              'Services: WARNING, CRITICAL, UNKNOWN\nHosts: DOWN, UNREACHABLE',
            ),
            _buildInfoPoint(
              Icons.battery_saver,
              'Battery Optimization',
              'Automatically adjusts check frequency based on battery level and app state.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPoint(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Troubleshooting',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTroubleshootingPoint(
              'Not receiving notifications?',
              [
                'Check that notification permissions are granted',
                'Ensure notifications are enabled in this app',
                'Verify your CheckMK services have max attempt configurations',
                'Test with the "Test Notification" button',
              ],
            ),
            const SizedBox(height: 12),
            _buildTroubleshootingPoint(
              'Too many notifications?',
              [
                'Notifications have a 5-minute cooldown period',
                'Only triggered when attempts reach maximum',
                'Disable specific state monitoring if needed',
                'Check your CheckMK configuration for retry intervals',
              ],
            ),
            const SizedBox(height: 12),
            _buildTroubleshootingPoint(
              'Battery drain concerns?',
              [
                'App automatically reduces check frequency on low battery',
                'Uses efficient background processing',
                'Only checks during problematic states',
                'Can be disabled when not needed',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingPoint(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
        ),
        const SizedBox(height: 6),
        ...points
            .map((point) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.grey[600])),
                      Expanded(
                        child: Text(
                          point,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}
