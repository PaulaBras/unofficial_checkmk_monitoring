import 'package:flutter/material.dart';

import '/services/apiRequest.dart';

class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
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
        title: Text('Info Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: versionInfo.isEmpty
            ? Center(child: CircularProgressIndicator())
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
              label: Text('Property',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
          DataColumn(
              label: Text('Value',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text(
              'Site',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['site']}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Group',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['group']}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Rest API Revision',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['rest_api']['revision']}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Apache',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['versions']['apache'].join('.')}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Checkmk',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['versions']['checkmk']}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Python',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(
              Container(
                width: 200, // Adjust this value as needed
                child: Text(
                  '${versionInfo['versions']['python']}',
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Mod WSGI',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['versions']['mod_wsgi'].join('.')}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'WSGI',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['versions']['wsgi'].join('.')}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Edition',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['edition']}'))
          ]),
          DataRow(cells: [
            DataCell(Text(
              'Demo',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text('${versionInfo['demo'] ? 'Yes' : 'No'}'))
          ]),
        ],
      ),
    );
  }
}
