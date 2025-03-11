import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '/services/secureStorage.dart';
import 'site_connection_service.dart';

class ApiRequest {
  bool _ignoreCertificate = false;
  var secureStorage = SecureStorage();
  late SiteConnectionService _connectionService;
  String? _errorMessage;

  ApiRequest() {
    _connectionService = SiteConnectionService(secureStorage);
  }

  Future<dynamic> Request(String apiRequestUri,
      {String method = 'GET',
      Map<String, String>? headers,
      Map<String, dynamic>? body}) async {
    try {
      // Get the active connection
      final activeConnection = await _connectionService.getActiveConnection();
      
      if (activeConnection == null) {
        throw Exception('No active connection found');
      }
      
      // Use the connection details
      final protocol = activeConnection.protocol;
      final server = activeConnection.server;
      final username = activeConnection.username;
      final password = activeConnection.password;
      final site = activeConnection.site;
      _ignoreCertificate = activeConnection.ignoreCertificate;

      // Construct the URL
      final url = Uri.parse(
          '$protocol://$server${site.isNotEmpty ? '/$site' : ''}/check_mk/api/1.0/$apiRequestUri');
      
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
        var responseData = jsonDecode(response.body);
        
        // Add the connection name to the response data for multi-site support
        if (responseData is Map && responseData.containsKey('value') && responseData['value'] is List) {
          for (var item in responseData['value']) {
            if (item is Map && item.containsKey('extensions')) {
              item['extensions']['connection_name'] = activeConnection.name;
              item['extensions']['connection_id'] = activeConnection.id;
            }
          }
        }
        
        return responseData;
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
        _errorMessage = 'Failed to make network request: ${e.toString()}';
      }
      // Error is stored in _errorMessage and can be retrieved with getErrorMessage()
      //throw e;
    }
  }

  // Legacy method for backward compatibility
  Future<dynamic> RequestWithCredentials(
      String protocol,
      String server,
      String username,
      String password,
      String site,
      bool ignoreCertificate,
      String apiRequestUri,
      {String method = 'GET',
      Map<String, String>? headers,
      Map<String, dynamic>? body}) async {
    try {
      _ignoreCertificate = ignoreCertificate;

      // Construct the URL
      final url = Uri.parse(
          '$protocol://$server${site.isNotEmpty ? '/$site' : ''}/check_mk/api/1.0/$apiRequestUri');
      
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
        var responseData = jsonDecode(response.body);
        
        // Add the connection info to the response data for multi-site support
        if (responseData is Map && responseData.containsKey('value') && responseData['value'] is List) {
          for (var item in responseData['value']) {
            if (item is Map && item.containsKey('extensions')) {
              item['extensions']['connection_name'] = site.isNotEmpty ? '$server/$site' : server;
            }
          }
        }
        
        return responseData;
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
        _errorMessage = 'Failed to make network request: ${e.toString()}';
      }
      // Error is stored in _errorMessage and can be retrieved with getErrorMessage()
      //throw e;
    }
  }

  String? getErrorMessage() {
    return _errorMessage;
  }
}
