import 'package:flutter/foundation.dart';

import '../../../core/network/auth_token_ref.dart';
import '../../../core/storage/token_storage.dart';
import '../models/login_result.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository repository,
    required TokenStorage storage,
    required AuthTokenRef tokenRef,
  })  : _repository = repository,
        _storage = storage,
        _tokenRef = tokenRef;

  final AuthRepository _repository;
  final TokenStorage _storage;
  final AuthTokenRef _tokenRef;

  bool _ready = false;
  bool get ready => _ready;

  String? _token;
  String? get token => _token;

  bool get isAuthenticated =>
      _token != null && _token!.isNotEmpty;

  /// Load persisted token (call once at startup).
  Future<void> bootstrap() async {
    _token = await _storage.readToken();
    _tokenRef.value = _token;
    _ready = true;
    notifyListeners();
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _repository.loginWithCustomApi(
      email: email,
      password: password,
    );

    if (result.success && result.hasToken && result.accessToken != null) {
      _token = result.accessToken;
      _tokenRef.value = _token;
      await _storage.saveToken(_token!);
      notifyListeners();
    }

    return result;
  }

  Future<void> logout() async {
    _token = null;
    _tokenRef.value = null;
    await _storage.clear();
    notifyListeners();
  }
}
