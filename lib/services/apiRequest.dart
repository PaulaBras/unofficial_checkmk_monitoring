import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/credentials.dart';

class ApiRequest {
  bool _ignoreCertificate = false;
  var secureStorage = SecureStorage();

  Future<dynamic> Request(String apiRequestUri) async {
    // Retrieve the credentials from secure storage
    var server = await secureStorage.readSecureData('server');
    var username = await secureStorage.readSecureData('username');
    var password = await secureStorage.readSecureData('password');
    var site = await secureStorage.readSecureData('site');
    var ignoreCertificate = await secureStorage.readSecureData('ignoreCertificate');

    // Convert the ignoreCertificate string to a boolean
    _ignoreCertificate = ignoreCertificate?.toLowerCase() == 'true';

    // Construct the URL
    final url = Uri.parse('https://$server/$site/check_mk/api/1.0/' + apiRequestUri);
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
      return jsonDecode(response.body);
    } else {
      // If the server returns an error response, then throw an exception.
      throw Exception('Failed to get api Request' + response.body);
    }
  }
}