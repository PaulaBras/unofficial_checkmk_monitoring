import 'package:flutter/material.dart';

import '/services/apiRequest.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.5, 0);
    path.lineTo(width, height * 0.25);
    path.lineTo(width, height * 0.75);
    path.lineTo(width * 0.5, height);
    path.lineTo(0, height * 0.75);
    path.lineTo(0, height * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StateWidget extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color textColor;

  StateWidget({
    required this.label,
    required this.count,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: HexagonClipper(),
      child: Container(
        width: 100,
        height: 115,
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HexagonGrid extends StatelessWidget {
  final List<StateWidget> hexagons;

  HexagonGrid({required this.hexagons});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: -30,
      children: hexagons.map((hexagon) {
        return Padding(
          padding: EdgeInsets.only(top: hexagons.indexOf(hexagon).isEven ? 0 : 30),
          child: hexagon,
        );
      }).toList(),
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
      hostUnreach = hostData.where((item) => item['extensions']['state'] == 2).length;
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Hosts and Services Overview',
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              HexagonGrid(
                hexagons: [
                  StateWidget(label: 'Hosts UP', count: hostOk, color: Colors.green),
                  StateWidget(label: 'Hosts DOWN', count: hostDown, color: Colors.red, textColor: Colors.white),
                  StateWidget(label: 'Hosts UNREACH', count: hostUnreach, color: Colors.deepPurple, textColor: Colors.white),
                ],
              ),
              SizedBox(height: 40), // Increased spacing between hosts and services
              HexagonGrid(
                hexagons: [
                  StateWidget(label: 'Services OK', count: serviceOk, color: Colors.green),
                  StateWidget(label: 'Services WARN', count: serviceWarn, color: Colors.yellow, textColor: Colors.black),
                  StateWidget(label: 'Services CRIT', count: serviceCrit, color: Colors.red, textColor: Colors.white),
                  StateWidget(label: 'Services UNKNOWN', count: serviceUnknown, color: Colors.orange),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Event Console',
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Container(
                height: 300, // Fixed height for the EventConsole
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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
