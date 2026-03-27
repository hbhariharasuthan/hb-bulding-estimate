import 'package:dio/dio.dart';

import '../models/master_item.dart';
import '../models/material_standard_item.dart';

class MasterRepository {
  MasterRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<MasterItem>> list(
    String path, {
    String? q,
    int page = 1,
    int perPage = 20,
    String statusFilter = 'all',
    String sort = 'name',
    String order = 'asc',
  }) async {
    final response = await _dio.get<List<dynamic>>(
      path,
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': page,
        'per_page': perPage,
        'status_filter': statusFilter,
        'sort': sort,
        'order': order,
      },
    );
    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MasterItem.fromJson)
        .toList();
  }

  Future<void> create(String path, String name, {required bool isActive}) async {
    await _dio.post(path, data: {'name': name, 'is_active': isActive});
  }

  Future<void> update(String path, int id, String name, {required bool isActive}) async {
    await _dio.put('$path/$id', data: {'name': name, 'is_active': isActive});
  }

  Future<void> delete(String path, int id) async {
    await _dio.delete('$path/$id');
  }

  Future<Map<String, List<MasterItem>>> fetchDropdowns() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/material-standards/material',
    );
    final data = response.data ?? const {};
    List<MasterItem> parse(dynamic rows) => (rows as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MasterItem.fromJson)
        .toList();
    return {
      'materials': parse(data['materials']),
      'properties': parse(data['properties']),
      'units': parse(data['units']),
    };
  }

  Future<List<MaterialStandardItem>> listStandards({
    String? q,
    int page = 1,
    int perPage = 20,
    String statusFilter = 'all',
    String sort = 'id',
    String order = 'asc',
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/material-standards',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': page,
        'per_page': perPage,
        'status_filter': statusFilter,
        'sort': sort,
        'order': order,
      },
    );
    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MaterialStandardItem.fromJson)
        .toList();
  }

  Future<void> createStandard({
    required int materialId,
    required int propertyId,
    required int unitId,
    required double? value,
    required bool isDefault,
    required bool isActive,
  }) async {
    await _dio.post(
      '/api/v1/material-standards',
      data: {
        'material_id': materialId,
        'property_id': propertyId,
        'unit_id': unitId,
        'value': value,
        'default': isDefault,
        'is_active': isActive,
      },
    );
  }

  Future<void> updateStandard({
    required int standardId,
    required int unitId,
    required double? value,
    required bool isDefault,
    required bool isActive,
  }) async {
    await _dio.put(
      '/api/v1/material-standards/$standardId',
      data: {
        'unit_id': unitId,
        'value': value,
        'default': isDefault,
        'is_active': isActive,
      },
    );
  }

  Future<void> deleteStandard(int standardId) async {
    await _dio.delete('/api/v1/material-standards/$standardId');
  }
}
