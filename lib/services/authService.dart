import '../models/credentials.dart';
import '/services/secureStorage.dart';
import 'apiRequest.dart';

class AuthenticationService {
  final SecureStorage secureStorage;
  final ApiRequest apiRequest;

  AuthenticationService(this.secureStorage, this.apiRequest);

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
      print('Login failed: $e');
      return false;
    }
  }

  Future<void> saveCredentials(String protocol, String server, String username,
      String password, String site, bool ignoreCertificate) async {
    await secureStorage.writeSecureData('protocol', protocol);
    await secureStorage.writeSecureData('server', server);
    await secureStorage.writeSecureData('username', username);
    await secureStorage.writeSecureData('password', password);
    await secureStorage.writeSecureData('site', site);
    await secureStorage.writeSecureData(
        'ignoreCertificate', ignoreCertificate.toString());
  }

  Future<Credentials?> loadCredentials() async {
    String protocol = await secureStorage.readSecureData('protocol') ?? '';
    String server = await secureStorage.readSecureData('server') ?? '';
    String username = await secureStorage.readSecureData('username') ?? '';
    String password = await secureStorage.readSecureData('password') ?? '';
    String site = await secureStorage.readSecureData('site') ?? '';
    bool ignoreCertificate =
        (await secureStorage.readSecureData('ignoreCertificate'))
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

  Future<void> logout(Function navigateToHomeScreen) async {
    await secureStorage.clearAll(); // Clear all data from secure storage
    navigateToHomeScreen();
  }
}
