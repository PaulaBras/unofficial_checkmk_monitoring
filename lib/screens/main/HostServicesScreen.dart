import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

class HostServiceScreen extends StatefulWidget {
  final String hostName;

  HostServiceScreen({Key? key, required this.hostName}) : super(key: key);

  @override
  _HostServiceScreenState createState() => _HostServiceScreenState();
}

class _HostServiceScreenState extends State<HostServiceScreen> {
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
        'objects/host/${widget.hostName}/collections/services?columns=description&columns=acknowledged&columns=current_attempt&columns=last_check&columns=last_time_ok&columns=max_check_attempts&columns=acknowledged&columns=state&columns=comments&columns=is_flapping');

    setState(() {
      _service = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hostName),
      ),
      body: _service == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _service['value'].length,
              itemBuilder: (context, index) {
                var service = _service['value'][index];
                var state = service['extensions']['state'];
                var lastCheck = DateTime.fromMillisecondsSinceEpoch(
                    service['extensions']['last_check'] * 1000);
                String stateText;
                Icon stateIcon;
                Color color;

                switch (state) {
                  case 0:
                    stateText = 'OK';
                    stateIcon = Icon(Icons.check_circle, color: Colors.green);
                    color = Colors.green;
                    break;
                  case 1:
                    stateIcon = Icon(Icons.warning, color: Colors.yellow);
                    stateText = 'Warning';
                    color = Colors.yellow;
                    break;
                  case 2:
                    stateIcon = Icon(Icons.error, color: Colors.red);
                    stateText = 'Critical';
                    color = Colors.red;
                    break;
                  case 3:
                    stateIcon = Icon(Icons.help_outline, color: Colors.orange);
                    stateText = 'UNKNOWN';
                    color = Colors.orange;
                    break;
                  default:
                    stateText = 'N/A';
                    color = Colors.grey;
                    stateIcon = Icon(Icons.help_outline, color: Colors.grey);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      leading: stateIcon,
                      title: Text(service['extensions']['host_name']),
                      subtitle: state == 0
                          ? Text('State: $stateText\nLast Check: $lastCheck')
                          : Text('State: $stateText\n'
                              'Last Check: $lastCheck\n'
                              'Host Name: ${service['extensions']['host_name']}\n'
                              'Description: ${service['extensions']['description']}\n'
                              'Acknowledged: ${service['extensions']['acknowledged'] == 1 ? 'True' : 'False'}\n'
                              'Attempt: ${service['extensions']['current_attempt']}/${service['extensions']['max_check_attempts']}\n'
                              'Last Time OK: ${DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_time_ok'] * 1000)}\n'
                              'Is Flapping: ${service['extensions']['is_flapping']}'),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getService,
        tooltip: 'Refresh',
        child: const Icon(
          Icons.refresh,
          color: Colors.black, // Make the icon black
        ),
        backgroundColor: Colors.yellow, // Keep the button yellow
      ),
    );
  }
}
