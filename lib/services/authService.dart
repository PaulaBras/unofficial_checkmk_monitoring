import 'package:ptp_4_monitoring_app/services/secureStorage.dart';

import '../models/credentials.dart';

class AuthenticationService {
  final SecureStorage secureStorage;

  AuthenticationService(this.secureStorage);

  Future<bool> login(String server, String username, String password,
      String site, bool ignoreCertificate) async {
    // Implement your login logic here
    // If login is successful, return true
    // If login fails, return false

    // For now, let's assume the login is always successful
    return true;
  }

  Future<void> saveCredentials(String server, String username, String password,
      String site, bool ignoreCertificate) async {
    await secureStorage.writeSecureData('server', server);
    await secureStorage.writeSecureData('username', username);
    await secureStorage.writeSecureData('password', password);
    await secureStorage.writeSecureData('site', site);
    await secureStorage.writeSecureData(
        'ignoreCertificate', ignoreCertificate.toString());
  }

  Future<Credentials?> loadCredentials() async {
    String server = await secureStorage.readSecureData('server') ?? '';
    String username = await secureStorage.readSecureData('username') ?? '';
    String password = await secureStorage.readSecureData('password') ?? '';
    String site = await secureStorage.readSecureData('site') ?? '';
    bool ignoreCertificate =
        (await secureStorage.readSecureData('ignoreCertificate'))
                ?.toLowerCase() ==
            'true';

    if (server.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        site.isNotEmpty) {
      return Credentials(server, username, password, site, ignoreCertificate);
    } else {
      return null;
    }
  }
}
