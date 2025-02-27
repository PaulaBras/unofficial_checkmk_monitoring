import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../storage/secure_storage.dart';

/// A client for making API requests to the CheckMK API.
class ApiClient {
  bool _ignoreCertificate = false;
  final SecureStorage _secureStorage = SecureStorage();
  String? _errorMessage;

  /// Makes an API request to the specified endpoint.
  /// 
  /// [endpoint] - The API endpoint to request (without the base URL)
  /// [method] - The HTTP method to use (GET or POST)
  /// [queryParams] - Optional query parameters to include in the URL
  /// [headers] - Optional HTTP headers to include in the request
  /// [body] - Optional body to include in the request (for POST requests)
  Future<dynamic> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      // Retrieve the credentials from secure storage
      var protocol = await _secureStorage.readSecureData('protocol');
      var server = await _secureStorage.readSecureData('server');
      var username = await _secureStorage.readSecureData('username');
      var password = await _secureStorage.readSecureData('password');
      var site = await _secureStorage.readSecureData('site');
      var ignoreCertificate =
          await _secureStorage.readSecureData('ignoreCertificate');

      // Convert the ignoreCertificate string to a boolean
      _ignoreCertificate = ignoreCertificate?.toLowerCase() == 'true';

      // Build the URL with query parameters
      final uri = Uri(
        scheme: protocol,
        host: server,
        path: '/$site/check_mk/api/1.0/$endpoint',
        queryParameters: queryParams,
      );

      // Encode the username and password in the format username:password
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';

      // Create an HttpClient
      final httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) =>
                _ignoreCertificate);

      // Create an IOClient with the modified HttpClient
      final ioClient = IOClient(httpClient);

      // Make the HTTP request
      http.Response response;
      final defaultHeaders = <String, String>{
        'authorization': basicAuth,
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8'
      };

      // Merge default headers with custom headers if provided
      final mergedHeaders = {...defaultHeaders, ...?headers};

      if (method == 'GET') {
        response = await ioClient.get(
          uri,
          headers: mergedHeaders,
        );
      } else if (method == 'POST') {
        response = await ioClient.post(
          uri,
          headers: mergedHeaders,
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
        throw Exception('Failed to get API request: ${response.body} Error Code: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SocketException) {
        _errorMessage = 'Failed to make network request due to a network error';
      } else {
        _errorMessage = 'Failed to make network request: ${e.toString()}';
      }
      // Return null to indicate an error occurred
      return null;
    }
  }

  /// Returns the error message from the last API request, if any.
  String? getErrorMessage() {
    return _errorMessage;
  }
}
