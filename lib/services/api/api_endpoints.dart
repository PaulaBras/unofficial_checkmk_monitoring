/// A class containing all API endpoints used in the application.
class ApiEndpoints {
  /// Helper method to build an endpoint with query parameters and columns
  static String _buildEndpoint(
    String base, {
    Map<String, String>? queryParams,
    List<String>? columns,
  }) {
    if (queryParams == null && columns == null) {
      return base;
    }

    final uri = Uri.parse(base);
    final queryParameters = Map<String, dynamic>.from(uri.queryParameters);
    
    // Add query parameters
    if (queryParams != null) {
      queryParameters.addAll(queryParams);
    }
    
    // Add columns
    if (columns != null) {
      for (final column in columns) {
        if (queryParameters.containsKey('columns')) {
          if (queryParameters['columns'] is List) {
            (queryParameters['columns'] as List).add(column);
          } else {
            queryParameters['columns'] = [queryParameters['columns'], column];
          }
        } else {
          queryParameters['columns'] = column;
        }
      }
    }
    
    // Rebuild the URI with the updated query parameters
    final updatedUri = uri.replace(queryParameters: queryParameters);
    return updatedUri.toString();
  }
}

/// Host-related endpoints
class HostEndpoints {
  /// Get all hosts
  static String getAllHosts({bool onlyUp = false}) {
    final query = onlyUp 
        ? {'query': '{"op": "=", "left": "state", "right": "0"}'}
        : null;
    
    return ApiEndpoints._buildEndpoint(
      'domain-types/host/collections/all',
      queryParams: query,
      columns: [
        'name',
        'address',
        'last_check',
        'last_time_up',
        'state',
        'total_services',
        'acknowledged'
      ],
    );
  }

  /// Acknowledge a host
  static const acknowledge = 'domain-types/acknowledge/collections/host';

  /// Add a comment to a host
  static const comment = 'domain-types/comment/collections/host';

  /// Schedule downtime for a host
  static const downtime = 'domain-types/downtime/collections/host';
}

/// Service-related endpoints
class ServiceEndpoints {
  /// Get all services
  static String getAllServices({bool excludeOk = true}) {
    final query = excludeOk 
        ? {'query': '{"op": "!=", "left": "state", "right": "0"}'}
        : null;
    
    return ApiEndpoints._buildEndpoint(
      'domain-types/service/collections/all',
      queryParams: query,
      columns: [
        'state',
        'description',
        'acknowledged',
        'current_attempt',
        'last_check',
        'last_time_ok',
        'max_check_attempts',
        'plugin_output'
      ],
    );
  }

  /// Acknowledge a service
  static const acknowledge = 'domain-types/acknowledge/collections/service';

  /// Add a comment to a service
  static const comment = 'domain-types/comment/collections/service';

  /// Schedule downtime for a service
  static const downtime = 'domain-types/downtime/collections/service';
}
