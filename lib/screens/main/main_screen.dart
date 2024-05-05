import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/screens/main/service_screen.dart';
import '../../models/credentials.dart';
import '../../services/apiRequest.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _ignoreCertificate = false;
  var secureStorage = SecureStorage();
  List<dynamic> _hosts = [];

  @override
  void initState() {
    super.initState();
    _getHosts();
  }

  Future<void> _getHosts() async {
    // If the server returns a 200 OK response, then parse the JSON.
    var api = ApiRequest();
    var data = await api.Request('domain-types/host_config/collections/all?effective_attributes=false');

    setState(() {
      _hosts = data['value'];
      // Sort the hosts so that the offline ones are at the top
      _hosts.sort((a, b) => (b['extensions']['is_offline'] == a['extensions']['is_offline']) ? 0 : (b['extensions']['is_offline'] ? -1 : 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Übersicht'),
      ),
      body: ListView.builder(
        itemCount: _hosts.length,
        itemBuilder: (context, index) {
          var host = _hosts[index];
          return Card(
            color: host['extensions']['is_offline'] ? Colors.red : null,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceScreen(host: host),
                  ),
                );
              },
              child: ListTile(
                leading: Icon(Icons.computer),
                title: Text(host['title']),
                subtitle: Text('Folder: ${host['extensions']['folder']}'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getHosts,
        tooltip: 'Reload',
        child: const Icon(
          Icons.refresh,
          color: Colors.black, // Make the icon black
        ),
        backgroundColor: Colors.yellow, // Keep the button yellow
      ),
    );
  }
}