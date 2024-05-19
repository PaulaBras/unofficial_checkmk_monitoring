import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:ptp_4_monitoring_app/services/secureStorage.dart';

class ApiRequest {
  bool _ignoreCertificate = false;
  var secureStorage = SecureStorage();
  String? _errorMessage;

  Future<dynamic> Request(String apiRequestUri,
      {String method = 'GET',
      Map<String, String>? headers,
      Map<String, dynamic>? body}) async {
    try {
      // Retrieve the credentials from secure storage
      var server = await secureStorage.readSecureData('server');
      var username = await secureStorage.readSecureData('username');
      var password = await secureStorage.readSecureData('password');
      var site = await secureStorage.readSecureData('site');
      var ignoreCertificate =
          await secureStorage.readSecureData('ignoreCertificate');

      // Convert the ignoreCertificate string to a boolean
      _ignoreCertificate = ignoreCertificate?.toLowerCase() == 'true';

      // Construct the URL
      final url =
          Uri.parse('https://$server/$site/check_mk/api/1.0/' + apiRequestUri);
      // Encode the username and password in the format username:password
      String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$username:$password'));

      // Create an HttpClient
      final httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) =>
                _ignoreCertificate);

      // Create an IOClient with the modified HttpClient
      final ioClient = IOClient(httpClient);

      // Make the HTTP request
      http.Response response;
      if (method == 'GET') {
        response = await ioClient.get(
          url,
          headers: headers ??
              <String, String>{
                'authorization': basicAuth,
                'Accept': 'application/json',
                'Content-Type': 'application/json; charset=UTF-8'
              },
        );
      } else if (method == 'POST') {
        print("POST");
        response = await ioClient.post(
          url,
          headers: headers ??
              <String, String>{
                'authorization': basicAuth,
                'Accept': 'application/json',
                'Content-Type': 'application/json; charset=UTF-8'
              },
          body: jsonEncode(body),
        );
      } else {
        throw Exception('HTTP method $method not supported');
      }

      // Check the status code of the response
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, then parse the JSON.
        return jsonDecode(response.body);
      } else if (response.statusCode == 204) {
        return true;
      } else {
        // If the server returns an error response, then throw an exception.
        throw Exception('Failed to get api Request' +
            response.body +
            " Error Code: " +
            response.statusCode.toString());
      }
    } catch (e) {
      if (e is SocketException) {
        _errorMessage = 'Failed to make network request due to a network error';
      } else {
        _errorMessage = 'Failed to make network request';
      }
      //throw e;
    }
  }

  String? getErrorMessage() {
    return _errorMessage;
  }
}
