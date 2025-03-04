import '../../models/host.dart';
import '../../models/service.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// A service for making API requests to the CheckMK API.
class ApiService {
  final ApiClient _apiClient = ApiClient();

  /// Returns the error message from the last API request, if any.
  String? getErrorMessage() {
    return _apiClient.getErrorMessage();
  }

  /// Gets all hosts.
  /// 
  /// [onlyUp] - If true, only returns hosts that are up
  Future<List<Host>> getAllHosts({bool onlyUp = false}) async {
    final endpoint = HostEndpoints.getAllHosts(onlyUp: onlyUp);
    final response = await _apiClient.request(endpoint);
    
    if (response != null && response['value'] != null) {
      final List<dynamic> rawHosts = response['value'];
      return rawHosts.map((json) => Host.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Gets all services.
  /// 
  /// [excludeOk] - If true, excludes services that are OK
  Future<List<Service>> getAllServices({bool excludeOk = true}) async {
    final endpoint = ServiceEndpoints.getAllServices(excludeOk: excludeOk);
    final response = await _apiClient.request(endpoint);
    
    if (response != null && response['value'] != null) {
      final List<dynamic> rawServices = response['value'];
      return rawServices.map((json) => Service.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Acknowledges a service.
  /// 
  /// [hostName] - The name of the host
  /// [serviceDescription] - The description of the service
  /// [comment] - The comment to add to the acknowledgement
  /// [sticky] - If true, the acknowledgement will be sticky
  /// [persistent] - If true, the acknowledgement will be persistent
  /// [notify] - If true, a notification will be sent
  Future<bool> acknowledgeService({
    required String hostName,
    required String serviceDescription,
    required String comment,
    bool sticky = true,
    bool persistent = false,
    bool notify = true,
  }) async {
    final response = await _apiClient.request(
      ServiceEndpoints.acknowledge,
      method: 'POST',
      body: {
        'acknowledge_type': 'service',
        'sticky': sticky,
        'persistent': persistent,
        'notify': notify,
        'comment': comment,
        'host_name': hostName,
        'service_description': serviceDescription,
      },
    );
    
    return response == true;
  }

  /// Acknowledges a host.
  /// 
  /// [hostName] - The name of the host
  /// [comment] - The comment to add to the acknowledgement
  /// [sticky] - If true, the acknowledgement will be sticky
  /// [persistent] - If true, the acknowledgement will be persistent
  /// [notify] - If true, a notification will be sent
  Future<bool> acknowledgeHost({
    required String hostName,
    required String comment,
    bool sticky = true,
    bool persistent = false,
    bool notify = true,
  }) async {
    final response = await _apiClient.request(
      HostEndpoints.acknowledge,
      method: 'POST',
      body: {
        'acknowledge_type': 'host',
        'sticky': sticky,
        'persistent': persistent,
        'notify': notify,
        'comment': comment,
        'host_name': hostName,
      },
    );
    
    return response == true;
  }

  /// Adds a comment to a service.
  /// 
  /// [hostName] - The name of the host
  /// [serviceDescription] - The description of the service
  /// [comment] - The comment to add
  Future<bool> commentService({
    required String hostName,
    required String serviceDescription,
    required String comment,
  }) async {
    final response = await _apiClient.request(
      ServiceEndpoints.comment,
      method: 'POST',
      body: {
        'comment': comment,
        'host_name': hostName,
        'service_description': serviceDescription,
      },
    );
    
    return response == true;
  }

  /// Adds a comment to a host.
  /// 
  /// [hostName] - The name of the host
  /// [comment] - The comment to add
  Future<bool> commentHost({
    required String hostName,
    required String comment,
  }) async {
    final response = await _apiClient.request(
      HostEndpoints.comment,
      method: 'POST',
      body: {
        'comment': comment,
        'host_name': hostName,
      },
    );
    
    return response == true;
  }

  /// Schedules downtime for a service.
  /// 
  /// [hostName] - The name of the host
  /// [serviceDescription] - The description of the service
  /// [startTime] - The start time of the downtime
  /// [endTime] - The end time of the downtime
  /// [recur] - The recurrence type
  /// [duration] - The duration of the downtime in minutes
  /// [comment] - The comment to add to the downtime
  Future<bool> scheduleServiceDowntime({
    required String hostName,
    required String serviceDescription,
    required String startTime,
    required String endTime,
    String recur = 'fixed',
    int duration = 0,
    required String comment,
  }) async {
    final response = await _apiClient.request(
      ServiceEndpoints.downtime,
      method: 'POST',
      body: {
        'start_time': startTime,
        'end_time': endTime,
        'recur': recur,
        'duration': duration,
        'comment': comment,
        'downtime_type': 'service',
        'service_descriptions': [serviceDescription],
        'host_name': hostName,
      },
    );
    
    return response == true;
  }

  /// Schedules downtime for a host.
  /// 
  /// [hostName] - The name of the host
  /// [startTime] - The start time of the downtime
  /// [endTime] - The end time of the downtime
  /// [recur] - The recurrence type
  /// [duration] - The duration of the downtime in minutes
  /// [comment] - The comment to add to the downtime
  Future<bool> scheduleHostDowntime({
    required String hostName,
    required String startTime,
    required String endTime,
    String recur = 'fixed',
    int duration = 0,
    required String comment,
  }) async {
    final response = await _apiClient.request(
      HostEndpoints.downtime,
      method: 'POST',
      body: {
        'start_time': startTime,
        'end_time': endTime,
        'recur': recur,
        'duration': duration,
        'comment': comment,
        'downtime_type': 'host',
        'host_name': hostName,
      },
    );
    
    return response == true;
  }
}
