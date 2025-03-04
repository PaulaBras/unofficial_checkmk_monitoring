import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/service.dart';
import 'acknowledge_service_screen.dart';
import 'comment_service_screen.dart';
import 'downtime_service_screen.dart';

/// A screen that displays service details and provides actions for the service.
class ServiceActionScreen extends StatefulWidget {
  final Service service;

  const ServiceActionScreen({super.key, required this.service});

  @override
  _ServiceActionScreenState createState() => _ServiceActionScreenState();
}

class _ServiceActionScreenState extends State<ServiceActionScreen> {
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';

  @override
  void initState() {
    super.initState();
    _loadDateFormatAndLocale();
  }

  void _loadDateFormatAndLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
      _locale = prefs.getString('locale') ?? 'de_DE';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Actions'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service information card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      _buildInfoRow('Host', widget.service.hostName),
                      _buildInfoRow('Service', widget.service.description),
                      _buildInfoRow(
                        'State', 
                        widget.service.stateText,
                        valueColor: _getStateColor(widget.service.state),
                      ),
                      _buildInfoRow(
                        'Acknowledged', 
                        widget.service.isAcknowledged ? 'Yes' : 'No',
                        valueColor: widget.service.isAcknowledged ? Colors.green : null,
                      ),
                      _buildInfoRow(
                        'Current Attempt', 
                        '${widget.service.currentAttempt}/${widget.service.maxCheckAttempts}',
                      ),
                      _buildInfoRow(
                        'Last Check', 
                        DateFormat(_dateFormat, _locale).format(
                          DateTime.fromMillisecondsSinceEpoch(widget.service.lastCheck * 1000)
                        ),
                      ),
                      _buildInfoRow(
                        'Last Time OK', 
                        DateFormat(_dateFormat, _locale).format(
                          DateTime.fromMillisecondsSinceEpoch(widget.service.lastTimeOk * 1000)
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plugin Output:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.service.pluginOutput,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      
                      // Acknowledge action
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: const Text('Acknowledge'),
                        subtitle: const Text('Acknowledge this service problem'),
                        enabled: !widget.service.isAcknowledged && widget.service.state > 0,
                        onTap: () async {
                          if (widget.service.isAcknowledged || widget.service.state == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Service is already acknowledged or in OK state'),
                              ),
                            );
                            return;
                          }
                          
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AcknowledgeServiceScreen(service: widget.service),
                            ),
                          );
                          
                          if (result == true) {
                            // Refresh the service data
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                      
                      // Comment action
                      ListTile(
                        leading: const Icon(Icons.comment),
                        title: const Text('Add Comment'),
                        subtitle: const Text('Add a comment to this service'),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentServiceScreen(service: widget.service),
                            ),
                          );
                          
                          if (result == true) {
                            // Refresh the service data
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                      
                      // Schedule downtime action
                      ListTile(
                        leading: const Icon(Icons.schedule),
                        title: const Text('Schedule Downtime'),
                        subtitle: const Text('Schedule downtime for this service'),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DowntimeServiceScreen(service: widget.service),
                            ),
                          );
                          
                          if (result == true) {
                            // Refresh the service data
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(int state) {
    switch (state) {
      case 0: return Colors.green;
      case 1: return Colors.yellow.shade800;
      case 2: return Colors.red;
      case 3: return Colors.orange;
      default: return Colors.grey;
    }
  }
}
