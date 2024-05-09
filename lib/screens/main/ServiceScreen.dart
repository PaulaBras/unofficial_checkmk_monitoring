import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';
import 'package:ptp_4_monitoring_app/screens/main/ServiceActionScreen.dart';

class ServiceScreen extends StatefulWidget {
  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  dynamic _service;
  List<dynamic> _services = [];

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
      _service = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort the services based on their state
    List<dynamic> sortedServices = _service['value'];
    sortedServices.sort(
        (a, b) => b['extensions']['state'].compareTo(a['extensions']['state']));

    return Scaffold(
      appBar: AppBar(
        title: Text("Critical Services"),
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
