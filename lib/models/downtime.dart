class DowntimeRequest {
  final String startTime;
  final String endTime;
  final String recur;
  final int duration;
  final String comment;
  final String downtimeType;
  final String hostName;
  final String? serviceDescription;

  const DowntimeRequest({
    required this.startTime,
    required this.endTime,
    required this.recur,
    required this.duration,
    required this.comment,
    required this.downtimeType,
    required this.hostName,
    this.serviceDescription,
  });

  bool get isServiceDowntime => serviceDescription != null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'start_time': startTime,
      'end_time': endTime,
      'comment': comment,
      'host_name': hostName,
    };

    if (serviceDescription != null) {
      // CheckMK expects 'service_descriptions' (plural) as a list
      json['service_descriptions'] = [serviceDescription!];
    }

    // Add CheckMK specific fields that might be required
    json['downtime_type'] = downtimeType;

    return json;
  }

  DowntimeRequest copyWith({
    String? startTime,
    String? endTime,
    String? recur,
    int? duration,
    String? comment,
    String? downtimeType,
    String? hostName,
    String? serviceDescription,
  }) {
    return DowntimeRequest(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recur: recur ?? this.recur,
      duration: duration ?? this.duration,
      comment: comment ?? this.comment,
      downtimeType: downtimeType ?? this.downtimeType,
      hostName: hostName ?? this.hostName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
    );
  }
}

enum DowntimeType {
  host('host'),
  service('service'),
  hostgroup('hostgroup'),
  servicegroup('servicegroup');

  const DowntimeType(this.value);
  final String value;
}

enum RecurrenceType {
  fixed('fixed'),
  flexible('flexible');

  const RecurrenceType(this.value);
  final String value;
}
