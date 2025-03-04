import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/service.dart';
import '../../services/api/api_service.dart';
import '../../services/notification/notification_service.dart';
import 'service_action_screen.dart';

/// Enum representing the possible states of a service.
enum ServiceState { Warning, Critical, Unknown }

/// A search delegate for searching services.
class ServiceSearch extends SearchDelegate {
  final List<Service> services;

  ServiceSearch(this.services);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = services.where((service) {
      return service.hostName.toLowerCase().contains(query.toLowerCase()) ||
          service.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final service = results[index];
        return ListTile(
          title: Text(service.hostName),
          subtitle: Text(service.description),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceActionScreen(service: service),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = services.where((service) {
      return service.hostName.toLowerCase().contains(query.toLowerCase()) ||
          service.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final service = suggestions[index];
        return ListTile(
          title: Text(service.hostName),
          subtitle: Text(service.description),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceActionScreen(service: service),
              ),
            ).then((refreshNeeded) {
              if (refreshNeeded == true) {
                close(context, true); // Return true to indicate refresh needed
              }
            });
          },
        );
      },
    );
  }
}

/// A dialog for filtering services by state.
class StateFilterDialog extends StatefulWidget {
  final Set<ServiceState> selectedStates;
  final ValueChanged<Set<ServiceState>> onSelectedStatesChanged;

  const StateFilterDialog({
    super.key,
    required this.selectedStates,
    required this.onSelectedStatesChanged,
  });

  @override
  _StateFilterDialogState createState() => _StateFilterDialogState();
}

class _StateFilterDialogState extends State<StateFilterDialog> {
  late Set<ServiceState> _selectedStates;

  @override
  void initState() {
    super.initState();
    _selectedStates = {...widget.selectedStates};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by state'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ServiceState.values.map((state) {
          return CheckboxListTile(
            title: Text(state.toString().split('.').last),
            value: _selectedStates.contains(state),
            onChanged: (bool? isChecked) {
              setState(() {
                if (isChecked == true) {
                  _selectedStates.add(state);
                } else {
                  _selectedStates.remove(state);
                }
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            widget.onSelectedStatesChanged(_selectedStates);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

/// A screen that displays a list of services.
class ServicesScreen extends StatefulWidget {
  final int? initialStateFilter;

  const ServicesScreen({super.key, this.initialStateFilter});

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<Service> _allServices = [];
  List<Service> _filteredServices = [];
  Set<ServiceState> _filterStates = {...ServiceState.values};
  Timer? _timer;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  String? _error;
  bool _isLoading = true;

  // Add a ScrollController
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadDateFormatAndLocale();
    
    // Apply initial filter if provided
    if (widget.initialStateFilter != null) {
      if (widget.initialStateFilter == 0) {
        // Services OK - clear the filter since we only show non-OK services by default
        _filterStates = {};
      } else if (widget.initialStateFilter! <= 3) {
        // For Warning (1), Critical (2), Unknown (3)
        _filterStates = {ServiceState.values[widget.initialStateFilter! - 1]};
      }
    }
    
    _getServices();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      if (mounted) {
        _getServices();
      } else {
        t.cancel(); // Cancel the timer if the widget is no longer mounted
      }
    });
  }

  void _loadDateFormatAndLocale() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
        _locale = prefs.getString('locale') ?? 'de_DE';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getServices() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final apiService = ApiService();
    final services = await apiService.getAllServices();

    if (!mounted) return;

    final error = apiService.getErrorMessage();
    
    setState(() {
      if (error != null) {
        _error = error;
        _allServices = [];
        _timer?.cancel();
      } else {
        _allServices = services;
        _filterServices();
        _error = null;
        
        // Restart periodic refresh if needed
        if (_timer == null || !_timer!.isActive) {
          _startPeriodicRefresh();
        }
      }
      _isLoading = false;
    });

    // Only call checkTimer if the widget is still mounted
    if (mounted) {
      NotificationService().checkTimer();
    }
  }

  void _filterServices() {
    if (_allServices.isNotEmpty) {
      if (_filterStates.isNotEmpty) {
        _filteredServices = _allServices.where((service) {
          // Map service state to ServiceState enum
          ServiceState? serviceState;
          switch (service.state) {
            case 1:
              serviceState = ServiceState.Warning;
              break;
            case 2:
              serviceState = ServiceState.Critical;
              break;
            case 3:
              serviceState = ServiceState.Unknown;
              break;
            default:
              return false; // Don't include services with state 0 (OK) or other states
          }
          return _filterStates.contains(serviceState);
        }).toList();
      } else {
        _filteredServices = _allServices;
      }
    } else {
      _filteredServices = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort the services based on their state (Critical first, then Warning, then Unknown)
    _filteredServices.sort((a, b) => b.state.compareTo(a.state));

    bool noRelevantServices = _filteredServices.isEmpty ||
        _filteredServices.every((service) => service.state < 1 || service.state > 3);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Services Overview"),
        automaticallyImplyLeading: false, // Remove the back button
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StateFilterDialog(
                    selectedStates: _filterStates,
                    onSelectedStatesChanged: (selectedStates) {
                      setState(() {
                        _filterStates = selectedStates;
                      });
                      _filterServices(); // Filter the services
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ServiceSearch(_filteredServices),
              ).then((refreshNeeded) {
                if (refreshNeeded == true) {
                  _refreshIndicatorKey.currentState?.show();
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _getServices,
        child: _error != null
            ? Center(child: Text(_error!))
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : noRelevantServices
                    ? const Center(
                        child: Text('No services in Warning, Critical, or Unknown state'),
                      )
                    : Scrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = _filteredServices[index];
                            String stateText;
                            Color color;

                            switch (service.state) {
                              case 1:
                                stateText = 'Warning';
                                color = Colors.yellow[600]!;
                                break;
                              case 2:
                                stateText = 'Critical';
                                color = Colors.red;
                                break;
                              case 3:
                                stateText = 'UNKNOWN';
                                color = Colors.orange;
                                break;
                              default:
                                return Container(); // Return an empty container if the state is not 1, 2, or 3
                            }
                            
                            return Container(
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary, // Use secondary color for better visibility
                                  width: 2.0,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ListTile(
                                    onTap: () async {
                                      final refreshNeeded = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ServiceActionScreen(
                                            service: service,
                                          ),
                                        ),
                                      );
                                      
                                      if (refreshNeeded == true) {
                                        _refreshIndicatorKey.currentState?.show();
                                      }
                                    },
                                    title: Text(
                                      service.hostName,
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text: 'Service: ',
                                            style: DefaultTextStyle.of(context)
                                                .style
                                                .copyWith(fontWeight: FontWeight.bold),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: service.description,
                                                style: const TextStyle(fontWeight: FontWeight.normal),
                                              ),
                                            ],
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            text: 'Output: ',
                                            style: DefaultTextStyle.of(context)
                                                .style
                                                .copyWith(fontWeight: FontWeight.bold),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: _truncateOutput(service.pluginOutput, 50),
                                                style: const TextStyle(fontWeight: FontWeight.normal),
                                              ),
                                            ],
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            text: 'Current Attempt: ',
                                            style: DefaultTextStyle.of(context)
                                                .style
                                                .copyWith(fontWeight: FontWeight.bold),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: '${service.currentAttempt}/${service.maxCheckAttempts}',
                                                style: const TextStyle(fontWeight: FontWeight.normal),
                                              ),
                                            ],
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            text: 'Last Check: ',
                                            style: DefaultTextStyle.of(context)
                                                .style
                                                .copyWith(fontWeight: FontWeight.bold),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: DateFormat(_dateFormat, _locale).format(
                                                  DateTime.fromMillisecondsSinceEpoch(service.lastCheck * 1000),
                                                ),
                                                style: const TextStyle(fontWeight: FontWeight.normal),
                                              ),
                                            ],
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            text: 'Last Time OK: ',
                                            style: DefaultTextStyle.of(context)
                                                .style
                                                .copyWith(fontWeight: FontWeight.bold),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: DateFormat(_dateFormat, _locale).format(
                                                  DateTime.fromMillisecondsSinceEpoch(service.lastTimeOk * 1000),
                                                ),
                                                style: const TextStyle(fontWeight: FontWeight.normal),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (service.isAcknowledged)
                                              const Icon(Icons.check_circle, color: Colors.green),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 10,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning, color: color),
                                        Text(
                                          stateText,
                                          style: TextStyle(color: color),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reloadServices',
        onPressed: () {
          _refreshIndicatorKey.currentState?.show();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _truncateOutput(String output, int maxLength) {
    if (output.length > maxLength) {
      return '${output.substring(0, maxLength)}...';
    }
    return output;
  }
}
