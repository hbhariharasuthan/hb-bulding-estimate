import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../models/site_settings.dart';
import '../repositories/site_settings_repository.dart';

class SiteSettingsProvider extends ChangeNotifier {
  SiteSettingsProvider({required SiteSettingsRepository repository})
      : _repository = repository;

  final SiteSettingsRepository _repository;

  SiteSettings? _settings;
  bool _ready = false;

  bool get ready => _ready;
  SiteSettings? get settings => _settings;

  String get siteName => _settings?.siteName?.trim().isNotEmpty == true
      ? _settings!.siteName!.trim()
      : AppConfig.appName;

  Future<void> bootstrap() async {
    try {
      _settings = await _repository.fetch();
    } catch (_) {
      _settings = null;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> save({
    String? siteName,
    String? siteAdminEmail,
    String? siteAdminContactNumber,
    String? razorpayKey,
    String? razorpaySecret,
    MultipartFile? siteLogo,
    MultipartFile? loginBackground,
    bool removeSiteLogo = false,
    bool removeLoginBackground = false,
  }) async {
    _settings = await _repository.save(
      id: _settings?.id,
      siteName: siteName,
      siteAdminEmail: siteAdminEmail,
      siteAdminContactNumber: siteAdminContactNumber,
      razorpayKey: razorpayKey,
      razorpaySecret: razorpaySecret,
      siteLogo: siteLogo,
      loginBackground: loginBackground,
      removeSiteLogo: removeSiteLogo,
      removeLoginBackground: removeLoginBackground,
    );
    notifyListeners();
  }
}
