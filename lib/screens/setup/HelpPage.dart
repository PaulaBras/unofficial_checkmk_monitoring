import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/services/apiRequest.dart';

class HelpPage extends StatefulWidget {
  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  Map<String, dynamic> versionInfo = {};

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  Future<void> _getVersion() async {
    var api = ApiRequest();
    var data = await api.Request('version');
    setState(() {
      versionInfo = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: versionInfo.isEmpty
            ? CircularProgressIndicator()
            : VersionInfoWidget(versionInfo: versionInfo),
      ),
    );
  }
}

class VersionInfoWidget extends StatelessWidget {
  final Map<String, dynamic> versionInfo;

  VersionInfoWidget({required this.versionInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Site: ${versionInfo['site']}'),
        Text('Group: ${versionInfo['group']}'),
        Text('Rest API Revision: ${versionInfo['rest_api']['revision']}'),
        Text('Apache: ${versionInfo['versions']['apache'].join('.')}'),
        Text('Checkmk: ${versionInfo['versions']['checkmk']}'),
        Text('Python: ${versionInfo['versions']['python']}'),
        Text('Mod WSGI: ${versionInfo['versions']['mod_wsgi'].join('.')}'),
        Text('WSGI: ${versionInfo['versions']['wsgi'].join('.')}'),
        Text('Edition: ${versionInfo['edition']}'),
        Text('Demo: ${versionInfo['demo'] ? 'Yes' : 'No'}'),
      ],
    );
  }
}