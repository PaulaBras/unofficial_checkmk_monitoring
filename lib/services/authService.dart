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
      await apiRequest.Request(
        '/objects/site_connection/prod/actions/login/invoke',
        method: 'POST',
        body: {
          'username': username,
          'password': password,
        },
      );

      // You can add additional checks here based on the response
      return true;
    } catch (e) {
      // Login failed
      return false;
    }
  }

  // Login with active connection
  Future<bool> loginWithActiveConnection() async {
    try {
      final activeConnection = await _connectionService.getActiveConnection();
      if (activeConnection == null) {
        return false;
      }
      
      return await login(activeConnection.username, activeConnection.password);
    } catch (e) {
      // Login with active connection failed
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
      // Load credentials failed
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
