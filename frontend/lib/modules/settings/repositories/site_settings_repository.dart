import 'package:dio/dio.dart';

import '../models/site_settings.dart';

class SiteSettingsRepository {
  SiteSettingsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  SiteSettings _extractSettings(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid site settings response');
    }
    final row = data['site_settings'];
    if (row is! Map<String, dynamic>) {
      throw Exception('Invalid site settings payload');
    }
    return SiteSettings.fromJson(row);
  }

  Future<SiteSettings?> fetch() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/site-settings');
    final root = response.data;
    if (root == null) return null;
    final data = root['data'];
    if (data is! Map<String, dynamic>) return null;
    final row = data['site_settings'];
    if (row is! Map<String, dynamic>) return null;
    return SiteSettings.fromJson(row);
  }

  Future<SiteSettings> save({
    int? id,
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
    FormData buildFormData() => FormData.fromMap({
          'site_name': siteName ?? '',
          'site_admin_email': siteAdminEmail ?? '',
          'site_admin_contact_number': siteAdminContactNumber ?? '',
          'razorpay_key': razorpayKey ?? '',
          'razorpay_secret': razorpaySecret ?? '',
          'site_logo': siteLogo,
          'login_background': loginBackground,
          'remove_site_logo': removeSiteLogo,
          'remove_login_background': removeLoginBackground,
        });
    try {
      int? targetId = id;
      if (targetId == null) {
        final existing = await fetch();
        targetId = existing?.id;
      }

      final response = targetId == null
          ? await _dio.post<Map<String, dynamic>>('/api/v1/site-settings', data: buildFormData())
          : await _dio.put<Map<String, dynamic>>('/api/v1/site-settings/$targetId', data: buildFormData());
      return _extractSettings(response.data ?? const {});
    } on DioException catch (e) {
      // Existing row + stale/null id in client -> retry as update.
      if (id == null && e.response?.statusCode == 409) {
        final existing = await fetch();
        if (existing == null) rethrow;
        final updateResponse = await _dio.put<Map<String, dynamic>>(
          '/api/v1/site-settings/${existing.id}',
          data: buildFormData(),
        );
        return _extractSettings(updateResponse.data ?? const {});
      }
      rethrow;
    }
  }
}
