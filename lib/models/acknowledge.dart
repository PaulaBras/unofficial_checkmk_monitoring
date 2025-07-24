class AcknowledgeRequest {
  final String comment;
  final bool sticky;
  final bool persistent;
  final bool notify;
  final String hostName;
  final String? serviceDescription;

  const AcknowledgeRequest({
    required this.comment,
    required this.sticky,
    required this.persistent,
    required this.notify,
    required this.hostName,
    this.serviceDescription,
  });

  bool get isServiceAcknowledge => serviceDescription != null;

  String get acknowledgeType => isServiceAcknowledge ? 'service' : 'host';

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'acknowledge_type': acknowledgeType,
      'sticky': sticky,
      'persistent': persistent,
      'notify': notify,
      'comment': comment,
      'host_name': hostName,
    };

    if (serviceDescription != null) {
      json['service_description'] = serviceDescription!;
    }

    return json;
  }

  AcknowledgeRequest copyWith({
    String? comment,
    bool? sticky,
    bool? persistent,
    bool? notify,
    String? hostName,
    String? serviceDescription,
  }) {
    return AcknowledgeRequest(
      comment: comment ?? this.comment,
      sticky: sticky ?? this.sticky,
      persistent: persistent ?? this.persistent,
      notify: notify ?? this.notify,
      hostName: hostName ?? this.hostName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
    );
  }
}

enum AcknowledgeType {
  host('host'),
  service('service');

  const AcknowledgeType(this.value);
  final String value;
}
