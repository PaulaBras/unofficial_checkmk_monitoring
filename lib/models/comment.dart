class CommentRequest {
  final String comment;
  final bool persistent;
  final String commentType;
  final String hostName;
  final String? serviceDescription;

  const CommentRequest({
    required this.comment,
    required this.persistent,
    required this.commentType,
    required this.hostName,
    this.serviceDescription,
  });

  bool get isServiceComment => serviceDescription != null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'comment': comment,
      'persistent': persistent,
      'comment_type': commentType,
      'host_name': hostName,
    };

    if (serviceDescription != null) {
      json['service_description'] = serviceDescription!;
    }

    return json;
  }

  CommentRequest copyWith({
    String? comment,
    bool? persistent,
    String? commentType,
    String? hostName,
    String? serviceDescription,
  }) {
    return CommentRequest(
      comment: comment ?? this.comment,
      persistent: persistent ?? this.persistent,
      commentType: commentType ?? this.commentType,
      hostName: hostName ?? this.hostName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
    );
  }
}

enum CommentType {
  host('host'),
  service('service');

  const CommentType(this.value);
  final String value;
}
