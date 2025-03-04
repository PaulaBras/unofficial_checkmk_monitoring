import '../../models/credentials.dart';
import '../api/api_client.dart';
import '../api/api_service.dart';
import '../storage/secure_storage.dart';

/// A service for handling authentication.
class AuthService {
  final SecureStorage _secureStorage;
  final ApiService _apiService;

  /// Creates a new AuthService instance.
  AuthService(this._secureStorage, this._apiService);

  /// Attempts to log in with the provided credentials.
  /// 
  /// [username] - The username to log in with
  /// [password] - The password to log in with
  /// Returns true if login was successful, false otherwise
  Future<bool> login(String username, String password) async {
    try {
      // Use the ApiClient directly for this specific request
      final apiClient = ApiClient();
      await apiClient.request(
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
      print('Login failed: $e');
      return false;
    }
  }

  /// Saves credentials to secure storage.
  /// 
  /// [protocol] - The protocol to use (http or https)
  /// [server] - The server address
  /// [username] - The username
  /// [password] - The password
  /// [site] - The site name
  /// [ignoreCertificate] - Whether to ignore certificate errors
  Future<void> saveCredentials(
    String protocol, 
    String server, 
    String username,
    String password, 
    String site, 
    bool ignoreCertificate
  ) async {
    await _secureStorage.writeSecureData('protocol', protocol);
    await _secureStorage.writeSecureData('server', server);
    await _secureStorage.writeSecureData('username', username);
    await _secureStorage.writeSecureData('password', password);
    await _secureStorage.writeSecureData('site', site);
    await _secureStorage.writeSecureData(
        'ignoreCertificate', ignoreCertificate.toString());
  }

  /// Loads credentials from secure storage.
  /// 
  /// Returns a Credentials object if credentials are found, null otherwise
  Future<Credentials?> loadCredentials() async {
    String protocol = await _secureStorage.readSecureData('protocol') ?? '';
    String server = await _secureStorage.readSecureData('server') ?? '';
    String username = await _secureStorage.readSecureData('username') ?? '';
    String password = await _secureStorage.readSecureData('password') ?? '';
    String site = await _secureStorage.readSecureData('site') ?? '';
    bool ignoreCertificate =
        (await _secureStorage.readSecureData('ignoreCertificate'))
                ?.toLowerCase() ==
            'true';

    if (protocol.isNotEmpty &&
        server.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        site.isNotEmpty) {
      return Credentials(
          protocol, server, username, password, site, ignoreCertificate);
    } else {
      return null;
    }
  }

  /// Logs out the current user.
  /// 
  /// [onLogout] - A callback to execute after logout
  Future<void> logout(Function onLogout) async {
    await _secureStorage.clearAll(); // Clear all data from secure storage
    onLogout();
  }
}
