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

  Future<bool> login(String username, String password, {String site = ''}) async {
    try {
      // Use the provided site name or empty string if not provided
      final sitePath = site.isNotEmpty ? site : '';
      
      final response = await apiRequest.Request(
        '/objects/site_connection/$sitePath/actions/login/invoke',
        method: 'POST',
        body: {
          'username': username,
          'password': password,
        },
        timeoutSeconds: 15, // Shorter timeout for login
      );

      // Check if the response is null, which indicates an error
      if (response == null) {
        print('Login failed: ${apiRequest.getErrorMessage() ?? "Unknown error"}');
        return false;
      }
      
      // Login successful
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
        site: activeConnection.site
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
