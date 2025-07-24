import 'dart:io';

void main() async {
  print('Testing DNS resolution functionality...');

  // Test valid domain
  try {
    final addresses = await InternetAddress.lookup('google.com');
    print('google.com resolved to: ${addresses.first.address}');
  } catch (e) {
    print('Failed to resolve google.com: $e');
  }

  // Test invalid domain
  try {
    final addresses =
        await InternetAddress.lookup('this-domain-does-not-exist.com');
    print('Invalid domain resolved to: ${addresses.first.address}');
  } catch (e) {
    print('Failed to resolve invalid domain (expected): $e');
  }

  // Test IP address validation
  final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
  print('192.168.1.1 is IP: ${ipRegex.hasMatch('192.168.1.1')}');
  print('google.com is IP: ${ipRegex.hasMatch('google.com')}');
}
