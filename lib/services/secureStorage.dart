import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = FlutterSecureStorage();
  encrypt.Key? _key;
  final _iv = encrypt.IV.fromLength(16);

  Future<void> init() async {
    try {
      // Check if a key already exists
      String? existingKey = await _storage.read(key: 'encryption_key');
      if (existingKey == null) {
        await generateAndStoreKey();
      }
    } catch (e) {
      print('Error initializing secure storage: $e');
      // Re-throw to allow the caller to handle the error
      throw Exception('Failed to initialize secure storage: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      // Clear all data from secure storage
      await _storage.deleteAll();
    } catch (e) {
      print('Error clearing secure storage: $e');
      // Re-throw to allow the caller to handle the error
      throw Exception('Failed to clear secure storage: $e');
    }
  }

  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('Error deleting secure data for key $key: $e');
      // Re-throw to allow the caller to handle the error
      throw Exception('Failed to delete secure data: $e');
    }
  }

  Future<void> writeSecureData(String key, String value) async {
    try {
      var encryptedValue = await _encrypt(value);
      await _storage.write(key: key, value: encryptedValue);
    } catch (e) {
      print('Error writing secure data for key $key: $e');
      // Re-throw to allow the caller to handle the error
      throw Exception('Failed to write secure data: $e');
    }
  }

  Future<String?> readSecureData(String key) async {
    try {
      var encryptedValue = await _storage.read(key: key);
      if (encryptedValue != null) {
        return _decrypt(encryptedValue);
      }
      return null;
    } catch (e) {
      print('Error reading secure data for key $key: $e');
      // Return null instead of throwing to make the API more resilient
      return null;
    }
  }

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

  Future<void> generateAndStoreKey() async {
    try {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      final key = base64Url.encode(values);

      await _storage.write(key: 'encryption_key', value: key);
    } catch (e) {
      print('Error generating and storing encryption key: $e');
      // Re-throw to allow the caller to handle the error
      throw Exception('Failed to generate encryption key: $e');
    }
  }
}
