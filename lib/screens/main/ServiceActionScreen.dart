import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ptp_4_monitoring_app/actions/service/AcknowledgeService.dart';
import 'package:ptp_4_monitoring_app/actions/service/CommentService.dart';
import 'package:ptp_4_monitoring_app/actions/service/DowntimeService.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

import '../../services/secureStorage.dart';

class ServiceActionScreen extends StatefulWidget {
  final dynamic service;

  ServiceActionScreen({required this.service});

  @override
  _ServiceActionScreen createState() => _ServiceActionScreen();
}

class _ServiceActionScreen extends State<ServiceActionScreen> {
  dynamic _service;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';
  var secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();

    _loadDateFormatAndLocale();
    _getService();
  }

  void _loadDateFormatAndLocale() async {
    _dateFormat = await secureStorage.readSecureData('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = await secureStorage.readSecureData('locale') ?? 'de_DE';
  }

  void recheckService() {
    // Implement your logic to recheck the service
  }

  void acknowledgeService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AcknowledgeServiceForm(service: widget.service)),
    );
  }

  void downtimeService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DowntimeServiceWidget(
                hostName: widget.service['extensions']['host_name'],
                serviceDescription: widget.service['extensions']['description'],
              )),
    );
  }

  void commentService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentServiceWidget(hostName: widget.service['extensions']['host_name'])),
    );
  }

  Future<void> _getService() async {
    var api = ApiRequest();
    var data = await api.Request(
        'domain-types/service/collections/all?query=%7B%22op%22%3A%20%22!%3D%22%2C%20%22left%22%3A%20%22state%22%2C%20%22right%22%3A%20%220%22%7D&columns=state&columns=description&columns=acknowledged&columns=current_attempt&columns=last_check&columns=last_time_ok&columns=max_check_attempts&columns=acknowledged&columns=plugin_output');

    var services = data['value'];
    _service = services.firstWhere((service) => service['id'] == widget.service['id'], orElse: () => null);

    if (_service == null) {
      Navigator.pop(context);
    } else {
      setState(() {});
    }
  }

  Future<List<dynamic>> _getComments() async {
    var api = ApiRequest();
    var data = await api.Request('/domain-types/comment/collections/all?host_name=${widget.service['extensions']['host_name']}&service_description=${widget.service['extensions']['description']}');
    return data['value'];
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    var service = _service;
    var state = service['extensions']['state'];
    var description = service['extensions']['description'];
    var isFlapping = service['extensions']['is_flapping'];
    Icon stateIcon;
    Color color;

    switch (state) {
      case 1:
        stateIcon = Icon(Icons.warning, color: Colors.yellow);
        color = Colors.yellow;
        break;
      case 2:
        stateIcon = Icon(Icons.error, color: Colors.red);
        color = Colors.red;
        break;
      case 3:
        stateIcon = Icon(Icons.help_outline, color: Colors.orange);
        color = Colors.orange;
        break;
      default:
        return Container(); // Return an empty container if the state is not 1, 2, or 3
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Service Actions'),
      ),
      body: RefreshIndicator(
        onRefresh: _getService,
        child: _service == null
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      leading: stateIcon,
                      title: Text(service['extensions']['host_name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service: $description'),
                          Text('Output: ${service['extensions']['plugin_output']}'),
                          Text('Current Attempt: ${service['extensions']['current_attempt']}/${service['extensions']['max_check_attempts']}'),
                          Text('Last Check: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_check'] * 1000))}'),
                          Text('Last Time OK: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_time_ok'] * 1000))}'),
                          Text('Is Flapping: ${isFlapping == 1 ? 'Yes' : 'No'}'), // Display is_flapping
                          if (isFlapping == 1) Icon(Icons.waves), // Display wave icon if is_flapping is 1
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.refresh),
                          label: Text('Recheck'),
                          onPressed: null, // Disable the button by setting onPressed to null
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.check_circle),
                          label: Text('Acknowledge'),
                          onPressed: () => acknowledgeService(context),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.timer),
                          label: Text('Downtime'),
                          onPressed: () => downtimeService(context),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.comment),
                          label: Text('Comment'),
                          onPressed: () => commentService(context),
                        ),
                      ],
                    ),
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _getComments(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return ListView.builder(
                              itemCount: snapshot.data?.length ?? 0,
                              itemBuilder: (context, index) {
                                var comment = snapshot.data?[index];
                                return ListTile(
                                  title: Text('Author: ${comment['extensions']['author']}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Comment: ${comment['extensions']['comment']}'),
                                      Text('Persistent: ${comment['extensions']['persistent'] ? 'Yes' : 'No'}'),
                                      Text('Entry Time: ${comment['extensions']['entry_time']}'),
                                      if (comment['extensions']['expire_time'] != null) Text('Expire Time: ${comment['extensions']['expire_time']}'),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reloadServiceActions',
        onPressed: _getService,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
