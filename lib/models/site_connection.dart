import 'dart:convert';

class SiteConnection {
  String id;
  String name;
  String protocol;
  String server;
  String site;
  String username;
  String password;
  bool ignoreCertificate;
  bool enableNotifications;
  Map<String, bool> serviceStateNotifications;
  String authType; // 'basic' or 'saml'

  SiteConnection({
    required this.id,
    this.name = 'Default Connection',
    required this.protocol,
    required this.server,
    this.site = '',
    required this.username,
    required this.password,
    this.ignoreCertificate = false,
    this.enableNotifications = false,
    this.authType = 'basic',
    Map<String, bool>? serviceStateNotifications,
  }) : serviceStateNotifications = serviceStateNotifications ?? {
          'green': true,
          'warning': true,
          'critical': true,
          'unknown': true,
        };

  // Create a copy of the connection with updated fields
  SiteConnection copyWith({
    String? id,
    String? name,
    String? protocol,
    String? server,
    String? site,
    String? username,
    String? password,
    bool? ignoreCertificate,
    bool? enableNotifications,
    Map<String, bool>? serviceStateNotifications,
  }) {
    return SiteConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      server: server ?? this.server,
      site: site ?? this.site,
      username: username ?? this.username,
      password: password ?? this.password,
      ignoreCertificate: ignoreCertificate ?? this.ignoreCertificate,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      authType: authType ?? this.authType,
      serviceStateNotifications: serviceStateNotifications ?? Map.from(this.serviceStateNotifications),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'protocol': protocol,
      'server': server,
      'site': site,
      'username': username,
      'password': password,
      'ignoreCertificate': ignoreCertificate,
      'enableNotifications': enableNotifications,
      'authType': authType,
      'serviceStateNotifications': serviceStateNotifications,
    };
  }

  // Create from JSON
  factory SiteConnection.fromJson(Map<String, dynamic> json) {
    return SiteConnection(
      id: json['id'],
      name: json['name'],
      protocol: json['protocol'],
      server: json['server'],
      site: json['site'] ?? '',
      username: json['username'],
      password: json['password'],
      ignoreCertificate: json['ignoreCertificate'] ?? false,
      enableNotifications: json['enableNotifications'] ?? false,
      authType: json['authType'] ?? 'basic',
      serviceStateNotifications: Map<String, bool>.from(json['serviceStateNotifications'] ?? {
        'green': true,
        'warning': true,
        'critical': true,
        'unknown': true,
      }),
    );
  }

  // Convert to string for storage
  String toStorageString() {
    return jsonEncode(toJson());
  }

  // Create from storage string
  factory SiteConnection.fromStorageString(String storageString) {
    return SiteConnection.fromJson(jsonDecode(storageString));
  }
}
