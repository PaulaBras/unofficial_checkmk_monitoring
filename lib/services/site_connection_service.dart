import 'dart:convert';
import 'dart:math';
import '../models/site_connection.dart';
import 'secureStorage.dart';

class SiteConnectionService {
  final SecureStorage _secureStorage;
  final String _connectionsKey = 'site_connections';
  final String _activeConnectionKey = 'active_connection_id';
  
  SiteConnectionService(this._secureStorage);
  
  // Get all connections
  Future<List<SiteConnection>> getAllConnections() async {
    final String? connectionsJson = await _secureStorage.readSecureData(_connectionsKey);
    if (connectionsJson == null || connectionsJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> connectionsList = jsonDecode(connectionsJson);
      return connectionsList
          .map((json) => SiteConnection.fromJson(json))
          .toList();
    } catch (e) {
      // Error loading connections
      return [];
    }
  }
  
  // Save all connections
  Future<void> saveAllConnections(List<SiteConnection> connections) async {
    final String connectionsJson = jsonEncode(
      connections.map((connection) => connection.toJson()).toList()
    );
    await _secureStorage.writeSecureData(_connectionsKey, connectionsJson);
  }
  
  // Add a new connection
  Future<SiteConnection> addConnection(SiteConnection connection) async {
    final connections = await getAllConnections();
    
    // Generate a unique ID if not provided
    if (connection.id.isEmpty) {
      connection = connection.copyWith(id: _generateUuid());
    }
    
    connections.add(connection);
    await saveAllConnections(connections);
    
    // If this is the first connection, set it as active
    if (connections.length == 1) {
      await setActiveConnection(connection.id);
    }
    
    return connection;
  }
  
  // Update an existing connection
  Future<void> updateConnection(SiteConnection updatedConnection) async {
    final connections = await getAllConnections();
    final index = connections.indexWhere((c) => c.id == updatedConnection.id);
    
    if (index != -1) {
      connections[index] = updatedConnection;
      await saveAllConnections(connections);
    }
  }
  
  // Delete a connection
  Future<void> deleteConnection(String connectionId) async {
    final connections = await getAllConnections();
    final activeId = await getActiveConnectionId();
    
    connections.removeWhere((c) => c.id == connectionId);
    await saveAllConnections(connections);
    
    // If we deleted the active connection, set a new active connection if available
    if (connectionId == activeId && connections.isNotEmpty) {
      await setActiveConnection(connections.first.id);
    } else if (connections.isEmpty) {
      await _secureStorage.deleteSecureData(_activeConnectionKey);
    }
  }
  
  // Get a connection by ID
  Future<SiteConnection?> getConnection(String connectionId) async {
    final connections = await getAllConnections();
    return connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );
  }
  
  // Set the active connection
  Future<void> setActiveConnection(String connectionId) async {
    await _secureStorage.writeSecureData(_activeConnectionKey, connectionId);
  }
  
  // Get the active connection ID
  Future<String?> getActiveConnectionId() async {
    return await _secureStorage.readSecureData(_activeConnectionKey);
  }
  
  // Get the active connection
  Future<SiteConnection?> getActiveConnection() async {
    final activeId = await getActiveConnectionId();
    if (activeId == null) {
      return null;
    }
    
    try {
      return await getConnection(activeId);
    } catch (e) {
      return null;
    }
  }
  
  // Generate a simple UUID
  String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    
    return values.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }
  
  // Migrate legacy connection to the new format
  Future<void> migrateLegacyConnection() async {
    // Check if we already have connections
    final connections = await getAllConnections();
    if (connections.isNotEmpty) {
      return; // Already migrated
    }
    
    // Check if we have legacy connection data
    final protocol = await _secureStorage.readSecureData('protocol');
    final server = await _secureStorage.readSecureData('server');
    final username = await _secureStorage.readSecureData('username');
    final password = await _secureStorage.readSecureData('password');
    
    // If we have legacy data, migrate it
    if (server != null && server.isNotEmpty && 
        username != null && username.isNotEmpty) {
      
      final site = await _secureStorage.readSecureData('site') ?? '';
      final ignoreCertificate = (await _secureStorage.readSecureData('ignoreCertificate'))?.toLowerCase() == 'true';
      final enableNotifications = (await _secureStorage.readSecureData('enableNotifications'))?.toLowerCase() == 'true';
      
      // Create service state notification settings
      final Map<String, bool> serviceStateNotifications = {};
      for (var state in ['green', 'warning', 'critical', 'unknown']) {
        String? savedSetting = await _secureStorage.readSecureData('notify_$state');
        serviceStateNotifications[state] = savedSetting?.toLowerCase() != 'false';
      }
      
      // Create and save the connection
      final connection = SiteConnection(
        id: _generateUuid(),
        name: 'Default Connection',
        protocol: protocol ?? 'https',
        server: server,
        site: site,
        username: username,
        password: password ?? '',
        ignoreCertificate: ignoreCertificate,
        enableNotifications: enableNotifications,
        serviceStateNotifications: serviceStateNotifications,
      );
      
      await addConnection(connection);
    }
  }
}
