import '../services/apiRequest.dart';
import '../models/downtime.dart';
import '../utils/downtime_constants.dart';

class DowntimeService {
  final ApiRequest _apiRequest;

  DowntimeService({ApiRequest? apiRequest})
      : _apiRequest = apiRequest ?? ApiRequest();

  /// Creates a downtime for a host or service
  Future<bool> createDowntime(DowntimeRequest request) async {
    try {
      final endpoint = request.isServiceDowntime
          ? DowntimeConstants.serviceDowntimeEndpoint
          : DowntimeConstants.hostDowntimeEndpoint;

      print('[DowntimeService] Creating downtime:');
      print('[DowntimeService] Endpoint: $endpoint');
      print('[DowntimeService] Request body: ${request.toJson()}');

      final result = await _apiRequest.Request(
        endpoint,
        method: 'POST',
        body: request.toJson(),
      );

      print('[DowntimeService] API Response: $result');
      print('[DowntimeService] Response type: ${result.runtimeType}');

      // Check if API returned null (indicates HTTP error)
      if (result == null) {
        print('[DowntimeService] API returned null - checking error message');
        String? errorMessage = _apiRequest.getErrorMessage();
        print('[DowntimeService] Error message: $errorMessage');

        if (errorMessage != null) {
          throw Exception('API Error: $errorMessage');
        } else {
          throw Exception('API request failed with no response');
        }
      }

      // Handle different result formats from the API
      if (result is bool) {
        print('[DowntimeService] Boolean result: $result');
        return result;
      } else if (result is Map<String, dynamic>) {
        print('[DowntimeService] Map result keys: ${result.keys}');
        print('[DowntimeService] Full map result: $result');

        // Check for success indicators in the response
        final success = result['success'] == true ||
            result['result'] == 'OK' ||
            result['status'] == 'success' ||
            result['result_code'] == 0 ||
            result.containsKey('value') ||
            result.containsKey('id') ||
            result.containsKey('downtime_id');
        print('[DowntimeService] Success determined: $success');

        // If no clear success, check for error indicators
        if (!success &&
            (result.containsKey('error') ||
                result.containsKey('detail') ||
                result.containsKey('title'))) {
          String errorMsg = result['error']?.toString() ??
              result['detail']?.toString() ??
              result['title']?.toString() ??
              'Unknown API error';
          throw Exception('API Error: $errorMsg');
        }

        return success;
      } else if (result is List) {
        print('[DowntimeService] List result length: ${result.length}');
        // Some APIs return a list, consider non-empty as success
        return result.isNotEmpty;
      } else {
        print(
            '[DowntimeService] Other result: $result (${result.runtimeType})');
        // For other types, consider truthy values as success
        return result != null && result != false;
      }
    } catch (e, stackTrace) {
      print('[DowntimeService] Error: $e');
      print('[DowntimeService] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Gets existing downtimes for a host
  Future<List<Map<String, dynamic>>> getHostDowntimes(String hostName) async {
    try {
      final result = await _apiRequest.Request(
        '${DowntimeConstants.hostDowntimeEndpoint}?host_name=$hostName',
        method: 'GET',
      );

      if (result is Map<String, dynamic> && result['value'] is List) {
        return List<Map<String, dynamic>>.from(result['value']);
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Gets existing downtimes for a service
  Future<List<Map<String, dynamic>>> getServiceDowntimes(
      String hostName, String serviceDescription) async {
    try {
      final result = await _apiRequest.Request(
        '${DowntimeConstants.serviceDowntimeEndpoint}?host_name=$hostName&service_description=$serviceDescription',
        method: 'GET',
      );

      if (result is Map<String, dynamic> && result['value'] is List) {
        return List<Map<String, dynamic>>.from(result['value']);
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }
}
