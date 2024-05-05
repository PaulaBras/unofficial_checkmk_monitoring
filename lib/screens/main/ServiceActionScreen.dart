import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/actions/Acknowledge.dart';
import 'package:ptp_4_monitoring_app/actions/Downtime.dart';
import 'package:ptp_4_monitoring_app/actions/Comment.dart';

class ServiceActionScreen extends StatelessWidget {
  final dynamic service;

  ServiceActionScreen({required this.service});

  void recheckService() {
    // Implement your logic to recheck the service
  }

  void acknowledgeService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AcknowledgeServiceForm(service: service)),
    );
  }

  void downtimeService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DowntimeServiceWidget(hostName: service['extensions']['host_name'])),
    );
  }

  void commentService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentServiceWidget(hostName: service['extensions']['host_name'])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Actions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service: ${service['extensions']['host_name']}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: recheckService,
              child: Text('Recheck'),
            ),
            ElevatedButton(
              onPressed: () => acknowledgeService(context),
              child: Text('Acknowledge'),
            ),
            ElevatedButton(
              onPressed: () => downtimeService(context),
              child: Text('Downtime'),
            ),
            ElevatedButton(
              onPressed: () => commentService(context),
              child: Text('Comment'),
            ),
          ],
        ),
      ),
    );
  }
}