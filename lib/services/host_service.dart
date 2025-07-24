import '../services/apiRequest.dart';
import '../models/host.dart';
import '../utils/api_constants.dart';

class HostService {
  final ApiRequest _apiRequest;

  HostService({ApiRequest? apiRequest})
      : _apiRequest = apiRequest ?? ApiRequest();

  /// Fetches all hosts from the API
  Future<List<Host>> getAllHosts() async {
    try {
      final result = await _apiRequest.Request(
        ApiConstants.hostsEndpoint,
        method: 'GET',
      );

      if (result is Map<String, dynamic> && result['value'] is List) {
        final hostList = result['value'] as List;
        return hostList.map((hostData) => Host.fromJson(hostData)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches a specific host by name
  Future<Host?> getHostByName(String hostName) async {
    try {
      final hosts = await getAllHosts();
      return hosts.where((host) => host.name == hostName).firstOrNull;
    } catch (e) {
      rethrow;
    }
  }

  /// Filters hosts by state
  List<Host> filterHostsByState(List<Host> hosts, int state) {
    return hosts.where((host) => host.state == state).toList();
  }

  /// Filters hosts by name (search)
  List<Host> filterHostsByName(List<Host> hosts, String searchQuery) {
    if (searchQuery.isEmpty) return hosts;

    final query = searchQuery.toLowerCase();
    return hosts
        .where((host) =>
            host.name.toLowerCase().contains(query) ||
            host.address.toLowerCase().contains(query))
        .toList();
  }

  /// Groups hosts by state
  Map<String, List<Host>> groupHostsByState(List<Host> hosts) {
    final Map<String, List<Host>> grouped = {};

    for (final host in hosts) {
      final stateName = ApiConstants.hostStates[host.state] ?? 'Unknown';
      grouped[stateName] = (grouped[stateName] ?? [])..add(host);
    }

    return grouped;
  }

  /// Gets host statistics
  Map<String, int> getHostStatistics(List<Host> hosts) {
    final stats = <String, int>{};

    for (final host in hosts) {
      final stateName = ApiConstants.hostStates[host.state] ?? 'Unknown';
      stats[stateName] = (stats[stateName] ?? 0) + 1;
    }

    stats['Total'] = hosts.length;
    return stats;
  }
}
