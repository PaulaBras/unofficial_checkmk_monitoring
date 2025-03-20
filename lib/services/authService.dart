import '../models/credentials.dart';
import '../models/site_connection.dart';
import '/services/secureStorage.dart';
import 'apiRequest.dart';
import 'site_connection_service.dart';

class AuthenticationService {
  final SecureStorage secureStorage;
  final ApiRequest apiRequest;
  late SiteConnectionService _connectionService;

  AuthenticationService(this.secureStorage, this.apiRequest) {
    _connectionService = SiteConnectionService(secureStorage);
  }

  Future<bool> login(String username, String password) async {
    try {
      // Instead of using a dedicated login endpoint with POST,
      // we'll use a simple GET request to verify credentials.
      // We'll use a lightweight endpoint that should be available in all CheckMK installations.
      final response = await apiRequest.Request(
        'domain-types/host_config/collections/all',
        method: 'GET',
        // No body needed as authentication is handled via Basic Auth headers
      );

      // Check if the response is null, which indicates an error
      if (response == null) {
        print('Login failed: ${apiRequest.getErrorMessage() ?? "Unknown error"}');
        return false;
      }
      
      // If we got a response, the credentials are valid
      return true;
    } catch (e) {
      print('Login exception: $e');
      return false;
    }
  }

  // Login with active connection
  Future<bool> loginWithActiveConnection() async {
    try {
      final activeConnection = await _connectionService.getActiveConnection();
      if (activeConnection == null) {
        print('No active connection found');
        return false;
      }
      
      // Try to login with the active connection, including the site name
      final result = await login(
        activeConnection.username, 
        activeConnection.password,
      );
      
      if (!result) {
        print('Login with active connection failed');
      }
      
      return result;
    } catch (e) {
      print('Login with active connection exception: $e');
      return false;
    }
  }

  // This method is kept for backward compatibility
  Future<void> saveCredentials(String protocol, String server, String username,
      String password, String site, bool ignoreCertificate) async {
    // Create a new connection
    final connection = SiteConnection(
      id: '',
      name: 'Default Connection',
      protocol: protocol,
      server: server,
      site: site,
      username: username,
      password: password,
      ignoreCertificate: ignoreCertificate,
    );
    
    // Add the connection
    await _connectionService.addConnection(connection);
  }

  // This method is kept for backward compatibility
  Future<Credentials?> loadCredentials() async {
    try {
      final activeConnection = await _connectionService.getActiveConnection();
      if (activeConnection == null) {
        print('No active connection found when loading credentials');
        return null;
      }
      
      // Validate that we have the minimum required fields
      if (activeConnection.protocol.isEmpty || 
          activeConnection.server.isEmpty || 
          activeConnection.username.isEmpty) {
        print('Active connection is missing required fields');
        return null;
      }
      
      return Credentials(
        activeConnection.protocol,
        activeConnection.server,
        activeConnection.username,
        activeConnection.password,
        activeConnection.site,
        activeConnection.ignoreCertificate,
      );
    } catch (e) {
      print('Load credentials exception: $e');
      return null;
    }
  }

  Future<void> logout(Function navigateToHomeScreen) async {
    // We don't clear all data anymore, just log out the current user
    // This allows us to keep the connection settings
    navigateToHomeScreen();
  }
  
  // Clear all data and connections
  Future<void> clearAllData(Function navigateToHomeScreen) async {
    await secureStorage.clearAll();
    navigateToHomeScreen();
  }
}
