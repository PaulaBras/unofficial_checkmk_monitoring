import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/battery_optimization_service.dart';

class BatteryOptimizationScreen extends StatefulWidget {
  const BatteryOptimizationScreen({Key? key}) : super(key: key);

  @override
  _BatteryOptimizationScreenState createState() => _BatteryOptimizationScreenState();
}

class _BatteryOptimizationScreenState extends State<BatteryOptimizationScreen> {
  final BatteryOptimizationService _batteryService = BatteryOptimizationService();
  bool _isOptimizationDisabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBatteryOptimizationStatus();
  }

  Future<void> _checkBatteryOptimizationStatus() async {
    final isDisabled = await _batteryService.isBatteryOptimizationDisabled();
    
    if (mounted) {
      setState(() {
        _isOptimizationDisabled = isDisabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestBatteryOptimization() async {
    setState(() {
      _isLoading = true;
    });
    
    await _batteryService.requestDisableBatteryOptimization();
    
    // Wait a moment for the system to process the request
    await Future.delayed(const Duration(seconds: 1));
    
    await _checkBatteryOptimizationStatus();
  }

  Future<void> _openBatterySettings() async {
    await _batteryService.openBatteryOptimizationSettings();
    
    // Mark that we've shown the battery optimization dialog
    await _batteryService.markBatteryOptimizationRequested();
  }

  Future<void> _skipOptimization() async {
    // Mark that we've shown the battery optimization dialog
    await _batteryService.markBatteryOptimizationRequested();
    
    // Save user preference to not show this again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_battery_optimization', true);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Optimization'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Battery Optimization',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This app needs to run in the background to monitor your services and send notifications when issues are detected.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To ensure reliable monitoring, we recommend disabling battery optimization for this app.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isOptimizationDisabled
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _isOptimizationDisabled
                                    ? Colors.green
                                    : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isOptimizationDisabled
                                      ? 'Battery optimization is disabled'
                                      : 'Battery optimization is enabled',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _isOptimizationDisabled
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isOptimizationDisabled
                                ? 'Great! Your device will allow this app to run properly in the background.'
                                : 'Your device may restrict this app from running in the background, which can cause delayed or missed notifications.',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isOptimizationDisabled) ...[
                    ElevatedButton(
                      onPressed: _requestBatteryOptimization,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Disable Battery Optimization'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _openBatterySettings,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Open Battery Settings'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _skipOptimization,
                      child: const Text('Skip (Not Recommended)'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
