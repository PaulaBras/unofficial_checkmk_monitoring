import 'package:flutter/material.dart';
import '../../services/apiRequest.dart';

class CriticalScreen extends StatefulWidget {
  final dynamic host;

  CriticalScreen({this.host});

  @override
  _CriticalScreenState createState() => _CriticalScreenState();
}


class _CriticalScreenState extends State<CriticalScreen> {
  dynamic _service;
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _getService();
  }

  Future<void> _getService() async {
    var api = ApiRequest();
    var data = await api.Request(''); // To be implemented

    setState(() {
      _service = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.host['title']),
      ),
      body: _service == null
          ? CircularProgressIndicator()
          : ListView.builder(
        itemCount: _service['value'].length,
        itemBuilder: (context, index) {
          var service = _service['value'][index];
          var state = service['extensions']['state'];
          var lastCheck = DateTime.fromMillisecondsSinceEpoch(service['extensions']['last_check'] * 1000);
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

          return ListTile(
            title: Text(service['title']),
            subtitle: Text('State: $stateText\nLast Check: $lastCheck'),
            trailing: Text(
              stateText,
              style: TextStyle(color: color),
            ),
          );
        },
      ),
    );
  }
}