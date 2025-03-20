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
      Map<String, dynamic>? body,
      int timeoutSeconds = 30}) async {
    IOClient? ioClient;
    
    try {
      // Clear any previous error message
      _errorMessage = null;
      
      // Get the active connection
      final activeConnection = await _connectionService.getActiveConnection();
      
      if (activeConnection == null) {
        _errorMessage = 'No active connection found. Please set up a connection.';
        return null;
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
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';

      // Create an HttpClient with timeout
      final httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) =>
                _ignoreCertificate)
        ..connectionTimeout = Duration(seconds: timeoutSeconds);

      // Create an IOClient with the modified HttpClient
      ioClient = IOClient(httpClient);

      // Default headers
      final defaultHeaders = <String, String>{
        'authorization': basicAuth,
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8'
      };
      
      // Use provided headers or default headers
      final requestHeaders = headers ?? defaultHeaders;

      // Make the HTTP request with timeout
      http.Response response;
      
      try {
        if (method == 'GET') {
          response = await ioClient.get(
            url,
            headers: requestHeaders,
          ).timeout(Duration(seconds: timeoutSeconds));
        } else if (method == 'POST') {
          response = await ioClient.post(
            url,
            headers: requestHeaders,
            body: jsonEncode(body),
          ).timeout(Duration(seconds: timeoutSeconds));
        } else {
          throw Exception('HTTP method $method not supported');
        }
      } catch (e) {
        if (e is TimeoutException) {
          _errorMessage = 'Request timed out. Please check your connection and try again.';
        } else if (e is SocketException) {
          _errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = 'Request failed: ${e.toString()}';
        }
        return null;
      }

      // Check the status code of the response
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, then parse the JSON.
        try {
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
        } catch (e) {
          _errorMessage = 'Failed to parse response: ${e.toString()}';
          return null;
        }
      } else if (response.statusCode == 204) {
        return true;
      } else {
        // If the server returns an error response, set the error message
        _errorMessage = 'Server error: ${response.statusCode} - ${response.body}';
        return null;
      }
    } catch (e) {
      if (e is SocketException) {
        _errorMessage = 'Failed to make network request due to a network error';
      } else {
        _errorMessage = 'Failed to make network request: ${e.toString()}';
      }
      return null;
    } finally {
      // Always close the client to prevent resource leaks
      ioClient?.close();
    }
  }

  String? getErrorMessage() {
    return _errorMessage;
  }
}
