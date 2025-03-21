import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/actions/host/AcknowledgeHost.dart';
import '/actions/host/CommentHost.dart';
import '/actions/host/DowntimeHost.dart';
import '/screens/main/HostServicesScreen.dart';
import '/services/apiRequest.dart';

class HostActionScreen extends StatefulWidget {
  final dynamic host;

  HostActionScreen({required this.host});

  @override
  _HostActionScreenState createState() => _HostActionScreenState();
}

class _HostActionScreenState extends State<HostActionScreen> {
  dynamic _host;
  String _dateFormat = 'dd.MM.yyyy, HH:mm';
  String _locale = 'de_DE';

  @override
  void initState() {
    super.initState();
    _loadDateFormatAndLocale();
    _getHost();
  }

  void _loadDateFormatAndLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dateFormat = prefs.getString('dateFormat') ?? 'dd.MM.yyyy, HH:mm';
      _locale = prefs.getString('locale') ?? 'de_DE';
    });
  }

  void recheckHost() {
    // Implement your logic to recheck the host
  }

  void downtimeHost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              DowntimeHostWidget(hostName: widget.host['extensions']['name'])),
    );
  }

  void commentHost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CommentHostWidget(hostName: widget.host['extensions']['name'])),
    );
  }

  void acknowledgeHost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AcknowledgeHostForm(service: widget.host)),
    );
  }

  Future<void> _getHost() async {
    var api = ApiRequest();
    var data = await api.Request(
        'domain-types/host/collections/all?query=%7B%22op%22%3A%20%22%3D%22%2C%20%22left%22%3A%20%22name%22%2C%20%22right%22%3A%20%22${widget.host['extensions']['name']}%22%7D&columns=name&columns=address&columns=last_check&columns=last_time_up&columns=state&columns=total_services&columns=acknowledged');

    setState(() {
      _host = data['value'][0];
    });
  }

  Future<List<dynamic>> _getComments() async {
    var api = ApiRequest();
    var data = await api.Request(
        'domain-types/comment/collections/all?host_name=${widget.host['extensions']['name']}');
    return data['value'];
  }

  @override
  Widget build(BuildContext context) {
    if (_host == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    var host = _host;
    var state = host['extensions']['state'];
    Icon stateIcon;

    switch (state) {
      case 0:
        stateIcon = Icon(Icons.check_circle, color: Colors.green);
        break;
      case 1:
        stateIcon = Icon(Icons.warning, color: Colors.yellow);
        break;
      case 2:
        stateIcon = Icon(Icons.error, color: Colors.red);
        break;
      case 3:
        stateIcon = Icon(Icons.help_outline, color: Colors.orange);
        break;
      default:
        stateIcon = Icon(Icons.help_outline, color: Colors.grey);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Host Actions'),
      ),
      body: RefreshIndicator(
        onRefresh: _getHost,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  leading: stateIcon,
                  title: Text(
                    host['extensions']['name'],
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                      'Address: ${host['extensions']['address']}\n'
                      'Last Check: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(host['extensions']['last_check'] * 1000))}\n'
                      'Last Time Up: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(host['extensions']['last_time_up'] * 1000))}\n'
                      'State: ${host['extensions']['state']}\n'
                      'Total Services: ${host['extensions']['total_services']}\n'
                      'Acknowledged: ${host['extensions']['acknowledged'] == 1 ? 'Yes' : 'No'}\n'
                      '${host['extensions'].containsKey('connection_name') ? 'Site: ${host['extensions']['connection_name']}' : ''}'),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Recheck'),
                      onPressed: recheckHost,
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.check_circle),
                      label: Text('Acknowledge'),
                      onPressed: () => acknowledgeHost(context),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.timer),
                      label: Text('Downtime'),
                      onPressed: () => downtimeHost(context),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.comment),
                      label: Text('Comment'),
                      onPressed: () => commentHost(context),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HostServiceScreen(
                              hostName: host['extensions']['name'],
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.electrical_services),
                      label: Text('Services'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                FutureBuilder<List<dynamic>>(
                  future: _getComments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No comments available.');
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var comment = snapshot.data![index];
                          return ListTile(
                            title: Text('Author: ${comment['extensions']['author']}'),
                            subtitle: Text('Comment: ${comment['extensions']['comment']}'),
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'reloadHostActions',
        onPressed: _getHost,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
