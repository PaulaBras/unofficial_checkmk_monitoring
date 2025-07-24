import '../services/apiRequest.dart';
import '../models/acknowledge.dart';
import '../utils/acknowledge_constants.dart';

class AcknowledgeService {
  final ApiRequest _apiRequest;

  AcknowledgeService({ApiRequest? apiRequest})
      : _apiRequest = apiRequest ?? ApiRequest();

  /// Acknowledges a host or service
  Future<bool> acknowledge(AcknowledgeRequest request) async {
    try {
      final endpoint = request.isServiceAcknowledge
          ? AcknowledgeConstants.serviceAcknowledgeEndpoint
          : AcknowledgeConstants.hostAcknowledgeEndpoint;

      final result = await _apiRequest.Request(
        endpoint,
        method: 'POST',
        body: request.toJson(),
      );

      return result == true;
    } catch (e) {
      rethrow;
    }
  }
}
