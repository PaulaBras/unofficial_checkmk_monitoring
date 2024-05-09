import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/screens/main/ServiceActionScreen.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

enum SerivceState { Warning, Critical, Unknown }

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
  final Set<SerivceState> selectedStates;
  final ValueChanged<Set<SerivceState>> onSelectedStatesChanged;

  StateFilterDialog({
    required this.selectedStates,
    required this.onSelectedStatesChanged,
  });

  @override
  _StateFilterDialogState createState() => _StateFilterDialogState();
}

class _StateFilterDialogState extends State<StateFilterDialog> {
  late Set<SerivceState> _selectedStates;

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
        children: SerivceState.values.map((state) {
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
  dynamic _service;
  List<dynamic> _services = [];
  Set<SerivceState> _filterStates = {...SerivceState.values};

  @override
  void initState() {
    super.initState();

    _getService();
  }

  Future<void> _getService() async {
    var api = ApiRequest();
    var data = await api.Request(
        'domain-types/service/collections/all?query=%7B%22op%22%3A%20%22!%3D%22%2C%20%22left%22%3A%20%22state%22%2C%20%22right%22%3A%20%220%22%7D&columns=state&columns=description&columns=acknowledged&columns=current_attempt&columns=last_check&columns=last_time_ok&columns=max_check_attempts&columns=acknowledged');

    setState(() {
      _service = data['value'];
      if (_filterStates.isNotEmpty) {
        _service = _service.where((service) {
          var state = int.parse(service['extensions']['state'].toString());
          return _filterStates.contains(SerivceState.values[state - 1]);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort the services based on their state
    List<dynamic> sortedServices = _service;
    sortedServices.sort(
        (a, b) => b['extensions']['state'].compareTo(a['extensions']['state']));

    print(sortedServices);

    return Scaffold(
      appBar: AppBar(
        title: Text("Services Overview"),
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
                      _getService();
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
                delegate: ServiceSearch(_service),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _getService,
        child: _service == null
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: sortedServices.length,
                itemBuilder: (context, index) {
                  var service = sortedServices[index];
                  var state = service['extensions']['state'];
                  var description = service['extensions']['description'];
                  String stateText;
                  Color color;

                  switch (state) {
                    case 1:
                      stateText = 'Warning';
                      color = Colors.yellow;
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
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ServiceActionScreen(service: service),
                          ),
                        );
                      },
                      title: Text(service['extensions']['host_name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service: $description'),
                          Text(
                              'Current Attempt: ${service['extensions']['current_attempt']}/${service['extensions']['max_check_attempts']}'),
                          Text(
                              'Last Check: ${DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_check'] * 1000)}'),
                          Text(
                              'Last Time OK: ${DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_time_ok'] * 1000)}'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              service['extensions']['acknowledged'] == 1
                                  ? Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : Container(),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: color),
                              Text(
                                stateText,
                                style: TextStyle(color: color),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reloadCriticalServices',
        onPressed: _getService,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
