import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single configured [FlutterSecureStorage] instance for all user data.
abstract final class SecureStorageProvider {
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}
