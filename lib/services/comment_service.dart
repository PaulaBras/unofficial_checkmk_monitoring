import '../services/apiRequest.dart';
import '../models/comment.dart';
import '../utils/comment_constants.dart';

class CommentService {
  final ApiRequest _apiRequest;

  CommentService({ApiRequest? apiRequest})
      : _apiRequest = apiRequest ?? ApiRequest();

  /// Adds a comment for a host or service
  Future<bool> addComment(CommentRequest request) async {
    try {
      final endpoint = request.isServiceComment
          ? CommentConstants.serviceCommentEndpoint
          : CommentConstants.hostCommentEndpoint;

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
