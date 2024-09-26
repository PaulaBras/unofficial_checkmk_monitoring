import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/apiRequest.dart';
import 'ServiceActionScreen.dart';

class HostServiceScreen extends StatefulWidget {
  final String hostName;

  HostServiceScreen({Key? key, required this.hostName}) : super(key: key);

  @override
  _HostServiceScreenState createState() => _HostServiceScreenState();
}

class _HostServiceScreenState extends State<HostServiceScreen> {
  dynamic _service;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';

  @override
  void initState() {
    super.initState();
    _loadDateFormatAndLocale();
    _getService();
  }

  void _loadDateFormatAndLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
    _locale = prefs.getString('locale') ?? 'de_DE';
  }

  Future<void> _getService() async {
    var api = ApiRequest();
    var data = await api.Request(
        'objects/host/${widget.hostName}/collections/services?columns=description&columns=acknowledged&columns=current_attempt&columns=last_check&columns=last_time_ok&columns=max_check_attempts&columns=acknowledged&columns=state&columns=comments&columns=is_flapping');

    if (data == null) {
      Navigator.pop(context);
    } else {
      data['value'].sort((a, b) => (a['extensions']['description'] as String)
          .compareTo(b['extensions']['description'] as String));

      setState(() {
        _service = data;
      });
    }
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
                var lastCheck = DateFormat(_dateFormat, _locale).format(
                    DateTime.fromMillisecondsSinceEpoch(
                        service['extensions']['last_check'] * 1000));
                String stateText;
                Icon stateIcon;

                switch (state) {
                  case 0:
                    stateText = 'OK';
                    stateIcon = Icon(Icons.check_circle, color: Colors.green);
                    break;
                  case 1:
                    stateIcon = Icon(Icons.warning, color: Colors.yellow);
                    stateText = 'Warning';
                    break;
                  case 2:
                    stateIcon = Icon(Icons.error, color: Colors.red);
                    stateText = 'Critical';
                    break;
                  case 3:
                    stateIcon = Icon(Icons.help_outline, color: Colors.orange);
                    stateText = 'UNKNOWN';
                    break;
                  default:
                    stateText = 'N/A';
                    stateIcon = Icon(Icons.help_outline, color: Colors.grey);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      leading: stateIcon,
                      title: Text(service['extensions']['description']),
                      subtitle: state == 0
                          ? Text('State: $stateText\nLast Check: $lastCheck')
                          : Text('State: $stateText\n'
                              'Last Check: $lastCheck\n'
                              'Host Name: ${service['extensions']['host_name']}\n'
                              'Description: ${service['extensions']['description']}\n'
                              'Acknowledged: ${service['extensions']['acknowledged'] == 1 ? 'True' : 'False'}\n'
                              'Attempt: ${service['extensions']['current_attempt']}/${service['extensions']['max_check_attempts']}\n'
                              'Last Time OK: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_time_ok'] * 1000))}\n'
                              'Is Flapping: ${service['extensions']['is_flapping']}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceActionScreen(
                              service: service,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getService,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
