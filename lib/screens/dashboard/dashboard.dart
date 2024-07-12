import 'package:flutter/material.dart';

import '/services/apiRequest.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class StateWidget extends StatelessWidget {
  final int count;
  final Color color;
  final Color textColor;

  StateWidget({required this.count, required this.color, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  int hostOk = 0;
  int hostDown = 0;
  int hostUnreach = 0;
  int totalHosts = 0;
  double percentageHostOk = 0;
  double percentageHostWarn = 0;
  double percentageHostCrit = 0;
  double percentageHostUnknown = 0;

  int serviceOk = 0;
  int serviceWarn = 0;
  int serviceCrit = 0;
  int serviceUnknown = 0;
  int totalServices = 0;
  double percentageServiceOk = 0;
  double percentageServiceWarn = 0;
  double percentageServiceCrit = 0;
  double percentageServiceUnknown = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    var api = ApiRequest();
    var hostResponse = await api.Request('domain-types/host/collections/all?columns=state');
    var serviceResponse = await api.Request('domain-types/service/collections/all?columns=state');

    if (hostResponse != null && serviceResponse != null) {
      var hostData = hostResponse['value'];
      var serviceData = serviceResponse['value'];

      // Parse the host data and update the state counts
      hostOk = hostData.where((item) => item['extensions']['state'] == 0).length;
      hostDown = hostData.where((item) => item['extensions']['state'] == 1).length;
      totalHosts = hostOk + hostDown + hostUnreach;
      if (totalHosts != 0) {
        percentageHostOk = hostOk / totalHosts;
        percentageHostWarn = hostDown / totalHosts;
        percentageHostCrit = hostUnreach / totalHosts;
      }

      // Parse the service data and update the state counts
      serviceOk = serviceData.where((item) => item['extensions']['state'] == 0).length;
      serviceWarn = serviceData.where((item) => item['extensions']['state'] == 1).length;
      serviceCrit = serviceData.where((item) => item['extensions']['state'] == 2).length;
      serviceUnknown = serviceData.length - serviceOk - serviceWarn - serviceCrit;
      totalServices = serviceOk + serviceWarn + serviceCrit + serviceUnknown;
      if (totalServices != 0) {
        percentageServiceOk = serviceOk / totalServices;
        percentageServiceWarn = serviceWarn / totalServices;
        percentageServiceCrit = serviceCrit / totalServices;
        percentageServiceUnknown = serviceUnknown / totalServices;
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 20.0), // Add padding at the top
        child: Center(
          // Center the widgets
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Hosts: "),
                  StateWidget(count: hostOk, color: Colors.green),
                  StateWidget(count: hostDown, color: Colors.black, textColor: Colors.white), // DOWN
                  StateWidget(count: hostUnreach, color: Colors.deepPurple, textColor: Colors.white), // UNREACH
                ],
              ),
              SizedBox(height: 20), // Add some space between the rows
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the row
                children: <Widget>[
                  Text("Services: "),
                  StateWidget(count: serviceOk, color: Colors.green),
                  StateWidget(count: serviceWarn, color: Colors.yellow, textColor: Colors.black), // Make the text color black
                  StateWidget(count: serviceCrit, color: Colors.red),
                  StateWidget(count: serviceUnknown, color: Colors.orange),
                ],
              ),
              Expanded(
                child: EventConsole(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reloadDashboardData',
        onPressed: fetchData,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

class EventConsole extends StatefulWidget {
  @override
  _EventConsoleState createState() => _EventConsoleState();
}

class _EventConsoleState extends State<EventConsole> {
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    var api = ApiRequest();
    var serviceResponse = await api.Request(
        'domain-types/service/collections/all?columns=last_check&columns=last_hard_state&columns=last_hard_state_change&column=last_notification&column=last_state&column=last_state_change&column=last_time_critical&column=last_time_ok&column=last_time_unknown&column=last_time_warning');

    if (serviceResponse != null && serviceResponse.containsKey('value')) {
      var serviceData = serviceResponse['value'];

      // Get the current time
      var currentTime = DateTime.now().millisecondsSinceEpoch;

      // Filter the events that happened in the last 4 hours and are not 'OK' or 'notification'
      events = serviceData.where((item) {
        var lastCheck = item['extensions']['last_check'];
        var lastState = item['extensions']['last_state'];
        var lastNotification = item['extensions']['last_notification'];
        return lastCheck > currentTime - 4 * 60 * 60 * 1000 && lastState != 'OK' && lastNotification != 'notification';
      }).toList();

      // Sort the events chronologically
      events.sort((a, b) => b['extensions']['last_check'].compareTo(a['extensions']['last_check']));

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        var event = events[index];
        return ListTile(
          title: Text('Service: ${event['name']}'),
          subtitle: Text('Last check: ${DateTime.fromMillisecondsSinceEpoch(event['extensions']['last_check'])}\n'
              'Last state: ${event['extensions']['last_state']}\n'
              'Last hard state change: ${DateTime.fromMillisecondsSinceEpoch(event['extensions']['last_hard_state_change'])}\n'
              'Last critical time: ${DateTime.fromMillisecondsSinceEpoch(event['extensions']['last_time_critical'])}\n'
              'Last unknown time: ${DateTime.fromMillisecondsSinceEpoch(event['extensions']['last_time_unknown'])}\n'
              'Last warning time: ${DateTime.fromMillisecondsSinceEpoch(event['extensions']['last_time_warning'])}'),
        );
      },
    );
  }
}
