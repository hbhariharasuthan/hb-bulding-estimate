import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT using both [FlutterSecureStorage] and [SharedPreferences].
/// On Web, secure storage uses a web implementation; prefs provide a simple mirror.
class TokenStorage {
  TokenStorage({
    required FlutterSecureStorage secure,
    required SharedPreferences prefs,
  })  : _secure = secure,
        _prefs = prefs;

  static const _key = 'access_token';

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  Future<void> saveToken(String token) async {
    await _secure.write(key: _key, value: token);
    await _prefs.setString(_key, token);
  }

  Future<String?> readToken() async {
    final fromSecure = await _secure.read(key: _key);
    if (fromSecure != null && fromSecure.isNotEmpty) {
      return fromSecure;
    }
    final fromPrefs = _prefs.getString(_key);
    if (fromPrefs != null && fromPrefs.isNotEmpty) {
      return fromPrefs;
    }
    return null;
  }

  Future<void> clear() async {
    await _secure.delete(key: _key);
    await _prefs.remove(_key);
  }
}
