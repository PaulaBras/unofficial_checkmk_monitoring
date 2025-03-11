import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/actions/service/AcknowledgeService.dart';
import '/actions/service/CommentService.dart';
import '/actions/service/DowntimeService.dart';
import '/services/apiRequest.dart';

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

  // Add a ScrollController
  final ScrollController _scrollController = ScrollController();

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

  void recheckService() {
    // Implement your logic to recheck the service
  }

  void acknowledgeService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              AcknowledgeServiceForm(service: widget.service)),
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
      MaterialPageRoute(
          builder: (context) => CommentServiceWidget(
              hostName: widget.service['extensions']['host_name'])),
    );
  }

  Future<void> _getService() async {
    try {
      var api = ApiRequest();
      var data = await api.Request(
          'domain-types/service/collections/all?host_name=${widget.service['extensions']['host_name']}&service_description=${widget.service['extensions']['description']}&columns=state&columns=description&columns=acknowledged&columns=current_attempt&columns=last_check&columns=last_time_ok&columns=max_check_attempts&columns=acknowledged&columns=plugin_output&columns=is_flapping');

      var services = data['value'];
      
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _service = services.isNotEmpty ? services.first : widget.service;
        });
      }
    } catch (e) {
      // Error fetching service details
      // Optionally show an error dialog or snackbar
    }
  }

  Future<List<dynamic>> _getComments() async {
    var api = ApiRequest();
    var data = await api.Request(
        '/domain-types/comment/collections/all?host_name=${widget.service['extensions']['host_name']}&service_description=${widget.service['extensions']['description']}');
    return data['value'];
  }

  @override
  Widget build(BuildContext context) {
    var service = _service ?? widget.service;
    var state = service['extensions']['state'];
    var description = service['extensions']['description'];
    var isFlapping = service['extensions']['is_flapping'];
    Icon stateIcon;
    Color color;

    switch (state) {
      case 0:
        stateIcon = Icon(Icons.check_circle, color: Colors.green);
        color = Colors.green;
        break;
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
        stateIcon = Icon(Icons.help_outline, color: Colors.grey);
        color = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Service Actions'),
      ),
      body: RefreshIndicator(
        onRefresh: _getService,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2.0,
                  ),
                ),
                child: ListTile(
                  leading: stateIcon,
                  title: Text(
                    service['extensions']['host_name'],
                    style: TextStyle(
                      fontSize: 20.0, // adjust the size as needed
                      fontWeight: FontWeight.bold, // makes the text thicker
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service: $description'),
                      Text(
                          'Output: ${service['extensions']['plugin_output']}'),
                      Text(
                          'Current Attempt: ${service['extensions']['current_attempt']}/${service['extensions']['max_check_attempts']}'),
                      Text(
                          'Last Check: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_check'] * 1000))}'),
                      Text(
                          'Last Time OK: ${DateFormat(_dateFormat, _locale).format(DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_time_ok'] * 1000))}'),
                      Text(
                          'Is Flapping: ${isFlapping == 1 ? 'Yes' : 'No'}'),
                      // Display is_flapping
                      if (isFlapping == 1) Icon(Icons.waves),
                      // Display wave icon if is_flapping is 1
                      if (service['extensions'].containsKey('connection_name'))
                        Text('Site: ${service['extensions']['connection_name']}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Recheck'),
                    onPressed:
                        null, // Disable the button by setting onPressed to null
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
              SizedBox(height: 20),
              Divider(
                color: Colors.grey,
                height: 2.0,
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _getComments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Scrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: snapshot.data?.length ?? 0,
                          itemBuilder: (context, index) {
                            var comment = snapshot.data?[index];
                            return ListTile(
                              title: Text(
                                  'Author: ${comment['extensions']['author']}'),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Comment: ${comment['extensions']['comment']}'),
                                  Text(
                                      'Persistent: ${comment['extensions']['persistent'] ? 'Yes' : 'No'}'),
                                  Text(
                                      'Entry Time: ${comment['extensions']['entry_time']}'),
                                  if (comment['extensions']
                                          ['expire_time'] !=
                                      null)
                                    Text(
                                        'Expire Time: ${comment['extensions']['expire_time']}'),
                                ],
                              ),
                            );
                          },
                        ),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
