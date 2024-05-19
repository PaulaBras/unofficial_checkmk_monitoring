import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ptp_4_monitoring_app/screens/main/HostActionScreen.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

import '../../services/secureStorage.dart';

enum HostState { OK, Warning, Critical, Unknown }

class HostNameSearch extends SearchDelegate<String> {
  final List<dynamic> hosts;

  HostNameSearch(this.hosts);

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
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? hosts
        : hosts
            .where((host) => host['extensions']['name']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]['extensions']['name']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HostActionScreen(host: suggestions[index]),
              ),
            );
          },
        );
      },
    );
  }
}

class StateFilterDialog extends StatefulWidget {
  final Set<HostState> selectedStates;
  final ValueChanged<Set<HostState>> onSelectedStatesChanged;

  StateFilterDialog({
    required this.selectedStates,
    required this.onSelectedStatesChanged,
  });

  @override
  _StateFilterDialogState createState() => _StateFilterDialogState();
}

class _StateFilterDialogState extends State<StateFilterDialog> {
  late Set<HostState> _selectedStates;

  @override
  void initState() {
    super.initState();

    _selectedStates = widget.selectedStates;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter by state'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: HostState.values.map((state) {
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

class HostScreen extends StatefulWidget {
  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  List<dynamic> _allHosts = []; // Add this line to store all hosts
  List<dynamic> _filteredHosts = [];
  Set<HostState> _filterStates = {...HostState.values};
  Timer? _timer;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  var secureStorage = SecureStorage();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDateFormatAndLocale();
    _getHosts();
    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) => _getHosts());
  }

  void _loadDateFormatAndLocale() async {
    _dateFormat =
        await secureStorage.readSecureData('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = await secureStorage.readSecureData('locale') ?? 'de_DE';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getHosts() async {
    var api = ApiRequest();
    var data = await api.Request(
        'domain-types/host/collections/all?query=%7B%22op%22%3A%20%22%3D%22%2C%20%22left%22%3A%20%22state%22%2C%20%22right%22%3A%20%220%22%7D&columns=name&columns=address&columns=last_check&columns=last_time_up&columns=state&columns=total_services&columns=acknowledged');

    var error = api.getErrorMessage();
    if (error != null) {
      // Stop the timer
      api.cancelTimer();
      setState(() {
        _error = error;
      });
    } else {
      setState(() {
        _allHosts = data['value'];
        _filterHosts();
        _error = null;
      });
    }
  }

  void _filterHosts() {
    if (_allHosts.isNotEmpty) {
      if (_filterStates.isNotEmpty) {
        _filteredHosts = _allHosts.where((host) {
          var state = host['extensions']['state'];
          return _filterStates.contains(HostState.values[state]);
        }).toList();
      } else {
        _filteredHosts = _allHosts;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort the services based on their state
    List<dynamic> sortedHosts = _filteredHosts;
    if (sortedHosts.isNotEmpty) {
      sortedHosts.sort((a, b) =>
          b['extensions']['state'].compareTo(a['extensions']['state']));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Overview'),
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
                      _filterHosts();
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
                delegate: HostNameSearch(_filteredHosts),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _getHosts,
        child: _error != null
            ? Center(child: Text(_error!))
            : _filteredHosts.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: sortedHosts.length,
                    itemBuilder: (context, index) {
                      var host = sortedHosts[index];
                      var state = host['extensions']['state'];
                      String stateText;
                      Icon stateIcon;
                      Color color;
                      switch (state) {
                        case 0:
                          stateText = 'OK';
                          color = Colors.green;
                          stateIcon =
                              Icon(Icons.check_circle, color: Colors.green);
                          break;
                        // For testing only
                        case 1:
                          stateText = 'Warning';
                          stateIcon = Icon(Icons.warning, color: Colors.yellow);
                          color = Colors.yellow;
                          break;
                        case 2:
                          stateText = 'Critical';
                          stateIcon = Icon(Icons.error, color: Colors.red);
                          color = Colors.red;
                          break;
                        case 3:
                          stateText = 'UNKNOWN';
                          stateIcon =
                              Icon(Icons.help_outline, color: Colors.orange);
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
                            color: Theme.of(context).colorScheme.surface,
                            width: 2.0,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HostActionScreen(
                                  host: host,
                                ),
                              ),
                            );
                          },
                          title: Text(host['extensions']['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Address: ${host['extensions']['address']}'),
                              Text(
                                'Last Check: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(host['extensions']['last_check'] * 1000))}',
                              ),
                              Text(
                                'Last Time Up: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(host['extensions']['last_time_up'] * 1000))}',
                              ),
                              Text(
                                  'Total Services: ${host['extensions']['total_services']}'),
                              Text(
                                  'Acknowledged: ${host['extensions']['acknowledged'] == 1 ? 'Yes' : 'No'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              stateIcon,
                              Text(
                                stateText,
                                style: TextStyle(color: color),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getHosts,
        tooltip: 'Refresh',
        child: const Icon(
          Icons.refresh,
          color: Colors.black,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
