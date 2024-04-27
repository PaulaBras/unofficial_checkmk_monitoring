import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../models/credentials.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _ignoreCertificate = false;
  var secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _getHosts();
  }

  Future<void> _getHosts() async {
    // Retrieve the credentials from secure storage
    var server = await secureStorage.readSecureData('server');
    var username = await secureStorage.readSecureData('username');
    var password = await secureStorage.readSecureData('password');
    var site = await secureStorage.readSecureData('site');

    // Construct the URL
    final url = Uri.parse('https://$server/$site/check_mk/api/1.0/domain-types/host_config/collections/all?effective_attributes=false');
    // Encode the username and password in the format username:password
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));

    // Create an HttpClient
    final httpClient = HttpClient()
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => _ignoreCertificate);

    // Create an IOClient with the modified HttpClient
    final ioClient = IOClient(httpClient);

    // Make the GET request
    final response = await ioClient.get(
      url,
      headers: <String, String>{
        'authorization': basicAuth,
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8'
      },
    );
    // Check the status code of the response
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, then parse the JSON.
      print(jsonDecode(response.body));
    } else {
      // If the server returns an error response, then throw an exception.
      throw Exception('Failed to get hosts' + response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: const Text('Welcome to the app!'),
      ),
    );
  }
}