import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  // Brokie Brokie
  final _storage = FlutterSecureStorage();

  Future<void> writeSecureData(String key, String value) async {
    var encryptedValue = _encrypt(value);
    await _storage.write(key: key, value: encryptedValue);
  }

  Future<String?> readSecureData(String key) async {
    var encryptedValue = await _storage.read(key: key);
    if (encryptedValue != null) {
      return _decrypt(encryptedValue);
    }
    return null;
  }

  String _encrypt(String value) {
    // Implement your encryption method here
    // For the sake of this example, we'll just return the value as is
    return value;
  }

  String _decrypt(String value) {
    // Implement your decryption method here
    // For the sake of this example, we'll just return the value as is
    return value;
  }
}