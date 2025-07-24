import '../services/apiRequest.dart';
import '../models/service.dart';
import '../utils/api_constants.dart';

class ServiceService {
  final ApiRequest _apiRequest;

  ServiceService({ApiRequest? apiRequest})
      : _apiRequest = apiRequest ?? ApiRequest();

  /// Fetches all services from the API
  Future<List<Service>> getAllServices() async {
    try {
      final result = await _apiRequest.Request(
        ApiConstants.servicesEndpoint,
        method: 'GET',
      );

      if (result is Map<String, dynamic> && result['value'] is List) {
        final serviceList = result['value'] as List;
        return serviceList
            .map((serviceData) => Service.fromJson(serviceData))
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches services for a specific host
  Future<List<Service>> getServicesForHost(String hostName) async {
    try {
      final services = await getAllServices();
      return services.where((service) => service.hostName == hostName).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Filters services by state
  List<Service> filterServicesByState(List<Service> services, int state) {
    return services.where((service) => service.state == state).toList();
  }

  /// Filters services by description (search)
  List<Service> filterServicesByDescription(
      List<Service> services, String searchQuery) {
    if (searchQuery.isEmpty) return services;

    final query = searchQuery.toLowerCase();
    return services
        .where((service) =>
            service.description.toLowerCase().contains(query) ||
            service.hostName.toLowerCase().contains(query))
        .toList();
  }

  /// Groups services by state
  Map<String, List<Service>> groupServicesByState(List<Service> services) {
    final Map<String, List<Service>> grouped = {};

    for (final service in services) {
      final stateName = ApiConstants.serviceStates[service.state] ?? 'Unknown';
      grouped[stateName] = (grouped[stateName] ?? [])..add(service);
    }

    return grouped;
  }

  /// Groups services by host
  Map<String, List<Service>> groupServicesByHost(List<Service> services) {
    final Map<String, List<Service>> grouped = {};

    for (final service in services) {
      grouped[service.hostName] = (grouped[service.hostName] ?? [])
        ..add(service);
    }

    return grouped;
  }

  /// Gets service statistics
  Map<String, int> getServiceStatistics(List<Service> services) {
    final stats = <String, int>{};

    for (final service in services) {
      final stateName = ApiConstants.serviceStates[service.state] ?? 'Unknown';
      stats[stateName] = (stats[stateName] ?? 0) + 1;
    }

    stats['Total'] = services.length;
    return stats;
  }

  /// Gets service statistics for a specific host
  Map<String, int> getServiceStatisticsForHost(
      List<Service> services, String hostName) {
    final hostServices =
        services.where((service) => service.hostName == hostName).toList();
    return getServiceStatistics(hostServices);
  }
}
