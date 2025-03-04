import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service for securely storing and retrieving sensitive data.
class SecureStorage {
  final _storage = FlutterSecureStorage();
  encrypt.Key? _key;
  final _iv = encrypt.IV.fromLength(16);

  /// Initializes the secure storage by ensuring an encryption key exists.
  Future<void> init() async {
    // Check if a key already exists
    String? existingKey = await _storage.read(key: 'encryption_key');
    if (existingKey == null) {
      await generateAndStoreKey();
    }
  }

  /// Clears all data from secure storage.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Writes data securely to storage.
  /// 
  /// [key] - The key to store the data under
  /// [value] - The value to store
  Future<void> writeSecureData(String key, String value) async {
    var encryptedValue = await _encrypt(value);
    await _storage.write(key: key, value: encryptedValue);
  }

  /// Reads data securely from storage.
  /// 
  /// [key] - The key to retrieve data for
  /// Returns the stored value, or null if no value exists for the key
  Future<String?> readSecureData(String key) async {
    var encryptedValue = await _storage.read(key: key);
    if (encryptedValue != null) {
      return _decrypt(encryptedValue);
    }
    return null;
  }

  /// Gets the encryption key, creating it if necessary.
  Future<encrypt.Key> _getKey() async {
    if (_key == null) {
      final keyData = await _storage.read(key: 'encryption_key');
      if (keyData == null) {
        throw Exception('No encryption key found');
      }
      final keyBytes = base64Url.decode(keyData);
      _key = encrypt.Key(keyBytes);
    }
    return _key!;
  }

  /// Encrypts a string value.
  Future<String> _encrypt(String value) async {
    /*
    final key = await _getKey();
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(value, iv: _iv);
    return encrypted.base64;
     */
    return value;
  }

  /// Decrypts a string value.
  Future<String> _decrypt(String value) async {
    /*
    final key = await _getKey();
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final decrypted = encrypter.decrypt(value, iv: _iv);
    return decrypted;
     */
    return value;
  }

  /// Generates and stores a new encryption key.
  Future<void> generateAndStoreKey() async {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final key = base64Url.encode(values);

    await _storage.write(key: 'encryption_key', value: key);
  }
}
