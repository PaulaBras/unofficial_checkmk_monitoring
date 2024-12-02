import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notify/notify.dart';
import '/screens/main/ServiceActionScreen.dart';
import '/services/apiRequest.dart';

enum ServiceState { Warning, Critical, Unknown }

class ServiceSearch extends SearchDelegate {
  final List<dynamic> services;

  ServiceSearch(this.services);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = services.where((service) {
      return service['extensions']['host_name']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          service['extensions']['description']
              .toLowerCase()
              .contains(query.toLowerCase());
    });

    return ListView(
      children: results.map<Widget>((service) {
        return ListTile(
          title: Text(service['extensions']['host_name']),
          subtitle: Text(service['extensions']['description']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceActionScreen(service: service),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = services.where((service) {
      return service['extensions']['host_name']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          service['extensions']['description']
              .toLowerCase()
              .contains(query.toLowerCase());
    });

    return ListView(
      children: suggestions.map<Widget>((service) {
        return ListTile(
          title: Text(service['extensions']['host_name']),
          subtitle: Text(service['extensions']['description']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceActionScreen(service: service),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class StateFilterDialog extends StatefulWidget {
  final Set<ServiceState> selectedStates;
  final ValueChanged<Set<ServiceState>> onSelectedStatesChanged;

  StateFilterDialog({
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
      title: Text('Filter by state'),
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
          child: Text('OK'),
          onPressed: () {
            widget.onSelectedStatesChanged(_selectedStates);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class ServiceScreen extends StatefulWidget {
  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  dynamic _allServices = []; // Add this line to store all services
  dynamic _filteredServices = [];
  Set<ServiceState> _filterStates = {...ServiceState.values};
  Timer? _timer;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  String? _error;

  // Add a ScrollController
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadDateFormatAndLocale();
    _getService();
    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) => _getService());
  }

  void _loadDateFormatAndLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = prefs.getString('locale') ?? 'de_DE';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getService() async {
    var api = ApiRequest();
    var data = await api.Request(
        'domain-types/service/collections/all?query=%7B%22op%22%3A%20%22!%3D%22%2C%20%22left%22%3A%20%22state%22%2C%20%22right%22%3A%20%220%22%7D&columns=state&columns=description&columns=acknowledged&columns=current_attempt&columns=last_check&columns=last_time_ok&columns=max_check_attempts&columns=acknowledged&columns=plugin_output');

    var error = api.getErrorMessage();
    if (error != null) {
      // Handle the error, for example, show a dialog or a snackbar
      // Stop the timer
      setState(() {
        _error = error;
        _allServices = [];
      });
      _timer?.cancel();
    } else {
      setState(() {
        _allServices = data['value']; // Store all services
        _filterServices(); // Filter the services
        _error = null;
        // Restart the timer if it was stopped
        if (_timer == null || !_timer!.isActive) {
          _timer =
              Timer.periodic(Duration(minutes: 1), (Timer t) => _getService());
        }
      });
    }
    NotificationService().checkTimer();
  }

  void _filterServices() {
    if (_allServices.isNotEmpty) {
      if (_filterStates.isNotEmpty) {
        _filteredServices = _allServices.where((service) {
          var state = int.parse(service['extensions']['state'].toString());
          return _filterStates.contains(ServiceState.values[state - 1]);
        }).toList();
      } else {
        _filteredServices = _allServices;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort the services based on their state
    List<dynamic> sortedServices = _filteredServices ?? [];
    if (sortedServices.isNotEmpty) {
      sortedServices.sort((a, b) =>
          b['extensions']['state'].compareTo(a['extensions']['state']));
    }

    bool noRelevantServices = sortedServices.isEmpty ||
        sortedServices.every((service) {
          int state = int.parse(service['extensions']['state'].toString());
          return state < 1 ||
              state >
                  3; // Assuming 1, 2, 3 are the codes for Warning, Critical, Unknown
        });

    return Scaffold(
      appBar: AppBar(
        title: Text("Services Overview"),
        automaticallyImplyLeading: false, // Remove the back button
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
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
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ServiceSearch(_filteredServices),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _getService,
        child: _error != null
            ? Center(child: Text(_error!))
            : noRelevantServices
                ? Center(
                    child: Text(
                        'No services in Warning, Critical, or Unknown state'),
                  )
                : _allServices.isEmpty && _error == null
                    ? Center(child: CircularProgressIndicator())
                    : Scrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: sortedServices.length,
                          itemBuilder: (context, index) {
                            var service = sortedServices[index];
                            var state = service['extensions']['state'];
                            var description =
                                service['extensions']['description'];
                            String stateText;
                            Color color;

                            switch (state) {
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
                              child: Stack(children: [
                                ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ServiceActionScreen(
                                                service: service),
                                      ),
                                    );
                                  },
                                  title: Text(
                                    service['extensions']['host_name'],
                                    style: TextStyle(
                                      fontSize:
                                          20.0, // adjust the size as needed
                                      fontWeight: FontWeight
                                          .bold, // makes the text thicker
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          text: 'Service: ',
                                          style: DefaultTextStyle.of(context)
                                              .style
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: description,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          text: 'Output: ',
                                          style: DefaultTextStyle.of(context)
                                              .style
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: () {
                                                String output =
                                                    service['extensions']
                                                        ['plugin_output'];
                                                if (output.length > 50) {
                                                  // adjust the length as needed
                                                  output =
                                                      output.substring(0, 50) +
                                                          '...';
                                                }
                                                return output;
                                              }(),
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.normal),
                                            ),
                                          ],
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          text: 'Current Attempt: ',
                                          style: DefaultTextStyle.of(context)
                                              .style
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text:
                                                    '${service['extensions']['current_attempt']}/${service['extensions']['max_check_attempts']}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          text: 'Last Check: ',
                                          style: DefaultTextStyle.of(context)
                                              .style
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text:
                                                    '${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_check'] * 1000))}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          text: 'Last Time OK: ',
                                          style: DefaultTextStyle.of(context)
                                              .style
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text:
                                                    '${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_time_ok'] * 1000))}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal)),
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
                                          service['extensions']
                                                      ['acknowledged'] ==
                                                  1
                                              ? Icon(Icons.check_circle,
                                                  color: Colors.green)
                                              : Container(),
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
                              ]),
                            );
                          },
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reloadCriticalServices',
        onPressed: () {
          _getService;
          _refreshIndicatorKey.currentState?.show();
        },
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
