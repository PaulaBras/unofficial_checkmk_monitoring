import 'package:flutter/material.dart';
import '../../services/apiRequest.dart';

class ServiceScreen extends StatefulWidget {
  final dynamic host;

  ServiceScreen({this.host});

  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  dynamic _service;
  List<dynamic> _services = []; // Define a variable to hold the services data

  @override
  void initState() {
    super.initState();
    _getService();
  }

  Future<void> _getService() async {
    var api = ApiRequest();
    var data = await api.Request('objects/host/${widget.host['id']}/collections/services');

    for (var service in data['value']) {
      var showLink = service['links'].firstWhere((link) => link['rel'] == 'urn:com.checkmk:rels/show');
      var hrefWithoutBase = showLink['href'].replaceFirst('https://cmk.pabr.zz/pabr/check_mk/api/1.0/', '');
      var splitHref = hrefWithoutBase.split('=');
      var encodedHref = splitHref[0] + '=' + splitHref[1].replaceAll('/', '%2F');
      print(encodedHref);
      var serviceData = await api.Request(encodedHref);
      service['extensions'] = serviceData['extensions'];
      _services.add(service);
    }

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
            case 0:
              stateText = 'OK';
              color = Colors.green;
              break;
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
              stateText = 'N/A';
              color = Colors.grey;
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