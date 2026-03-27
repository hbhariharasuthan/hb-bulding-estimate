import 'package:dio/dio.dart';

import '../models/plan_status.dart';

class ManualScaleOption {
  ManualScaleOption({
    required this.key,
    required this.label,
    required this.numerator,
    required this.denominator,
  });

  final String key;
  final String label;
  final int numerator;
  final int denominator;

  factory ManualScaleOption.fromJson(Map<String, dynamic> json) {
    return ManualScaleOption(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      numerator: (json['numerator'] as num?)?.toInt() ?? 0,
      denominator: (json['denominator'] as num?)?.toInt() ?? 0,
    );
  }
}

class ManualScaleResult {
  ManualScaleResult({
    required this.pixelLength,
    required this.scaleKey,
    required this.dpi,
    required this.outputUnit,
    required this.realLength,
    required this.scaleFactorMmPerPixel,
  });

  final double pixelLength;
  final String scaleKey;
  final int dpi;
  final String outputUnit;
  final double realLength;
  final double scaleFactorMmPerPixel;

  factory ManualScaleResult.fromJson(Map<String, dynamic> json) {
    return ManualScaleResult(
      pixelLength: (json['pixel_length'] as num?)?.toDouble() ?? 0,
      scaleKey: (json['scale_key'] as String?) ?? '',
      dpi: (json['dpi'] as num?)?.toInt() ?? 96,
      outputUnit: (json['output_unit'] as String?) ?? 'm',
      realLength: (json['real_length'] as num?)?.toDouble() ?? 0,
      scaleFactorMmPerPixel: (json['scale_factor_mm_per_pixel'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PlanImageInfo {
  PlanImageInfo({this.width, this.height, this.fileSize});

  final int? width;
  final int? height;
  final int? fileSize;

  factory PlanImageInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PlanImageInfo();
    return PlanImageInfo(
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      fileSize: (json['file_size'] as num?)?.toInt(),
    );
  }
}

class PlanPageMeta {
  PlanPageMeta({
    required this.pageNumber,
    required this.sourceImage,
    required this.processedImage,
    required this.processedSoftImage,
    required this.processedBinaryImage,
    required this.detectedUnit,
    required this.explanation,
    required this.sourceInfo,
    required this.processedInfo,
    required this.processedSoftInfo,
    required this.processedBinaryInfo,
  });

  final int pageNumber;
  final String sourceImage;
  final String processedImage;
  final String processedSoftImage;
  final String processedBinaryImage;
  final String detectedUnit;
  final String explanation;
  final PlanImageInfo sourceInfo;
  final PlanImageInfo processedInfo;
  final PlanImageInfo processedSoftInfo;
  final PlanImageInfo processedBinaryInfo;

  factory PlanPageMeta.fromJson(Map<String, dynamic> json) {
    return PlanPageMeta(
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      sourceImage: (json['source_image'] as String?) ?? '',
      processedImage: (json['processed_image'] as String?) ?? '',
      processedSoftImage: (json['processed_soft_image'] as String?) ?? '',
      processedBinaryImage: (json['processed_binary_image'] as String?) ?? '',
      detectedUnit: (json['detected_unit'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
      sourceInfo: PlanImageInfo.fromJson(json['source_info'] as Map<String, dynamic>?),
      processedInfo: PlanImageInfo.fromJson(json['processed_info'] as Map<String, dynamic>?),
      processedSoftInfo: PlanImageInfo.fromJson(json['processed_soft_info'] as Map<String, dynamic>?),
      processedBinaryInfo: PlanImageInfo.fromJson(
        json['processed_binary_info'] as Map<String, dynamic>?,
      ),
    );
  }
}

class PlanCalibration {
  PlanCalibration({
    required this.calibrationId,
    required this.planId,
    this.pageNumber,
    this.scaleKey,
    this.dpi,
    this.pixelLength,
    this.realLength,
    this.outputUnit,
    this.mmPerPixel,
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    required this.isActive,
    this.updatedBy,
  });

  final int calibrationId;
  final int planId;
  final int? pageNumber;
  final String? scaleKey;
  final int? dpi;
  final double? pixelLength;
  final double? realLength;
  final String? outputUnit;
  final double? mmPerPixel;
  final double? x1;
  final double? y1;
  final double? x2;
  final double? y2;
  final bool isActive;
  final int? updatedBy;

  factory PlanCalibration.fromJson(Map<String, dynamic> json) {
    return PlanCalibration(
      calibrationId: (json['calibration_id'] as num?)?.toInt() ?? 0,
      planId: (json['plan_id'] as num?)?.toInt() ?? 0,
      pageNumber: (json['page_number'] as num?)?.toInt(),
      scaleKey: json['scale_key'] as String?,
      dpi: (json['dpi'] as num?)?.toInt(),
      pixelLength: (json['pixel_length'] as num?)?.toDouble(),
      realLength: (json['real_length'] as num?)?.toDouble(),
      outputUnit: json['output_unit'] as String?,
      mmPerPixel: (json['mm_per_pixel'] as num?)?.toDouble(),
      x1: (json['x1'] as num?)?.toDouble(),
      y1: (json['y1'] as num?)?.toDouble(),
      x2: (json['x2'] as num?)?.toDouble(),
      y2: (json['y2'] as num?)?.toDouble(),
      isActive: (json['is_active'] as bool?) ?? false,
      updatedBy: (json['updated_by'] as num?)?.toInt(),
    );
  }
}

class CalibrationConvertResult {
  CalibrationConvertResult({
    required this.planId,
    required this.calibrationId,
    required this.outputUnit,
    required this.mmPerPixel,
    required this.values,
  });

  final int planId;
  final int calibrationId;
  final String outputUnit;
  final double mmPerPixel;
  final List<double> values;

  factory CalibrationConvertResult.fromJson(Map<String, dynamic> json) {
    final raw = json['values'];
    final values = raw is List ? raw.whereType<num>().map((e) => e.toDouble()).toList() : const <double>[];
    return CalibrationConvertResult(
      planId: (json['plan_id'] as num?)?.toInt() ?? 0,
      calibrationId: (json['calibration_id'] as num?)?.toInt() ?? 0,
      outputUnit: (json['output_unit'] as String?) ?? 'm',
      mmPerPixel: (json['mm_per_pixel'] as num?)?.toDouble() ?? 0,
      values: values,
    );
  }
}

class DetectedElement {
  DetectedElement({
    required this.elementId,
    required this.elementType,
    this.pixelLength,
    this.length,
    this.detectedLabel,
    this.confidenceScore,
  });

  final int elementId;
  final String elementType;
  final double? pixelLength;
  final double? length;
  final String? detectedLabel;
  final double? confidenceScore;

  factory DetectedElement.fromJson(Map<String, dynamic> json) {
    return DetectedElement(
      elementId: (json['element_id'] as num?)?.toInt() ?? 0,
      elementType: (json['element_type'] as String?) ?? '',
      pixelLength: (json['pixel_length'] as num?)?.toDouble(),
      length: (json['length'] as num?)?.toDouble(),
      detectedLabel: json['detected_label'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
    );
  }
}

class FloorMetricsResult {
  FloorMetricsResult({
    required this.planId,
    required this.pageNumber,
    required this.variant,
    required this.perimeterPx,
    required this.areaPx2,
    required this.mmPerPixel,
    required this.perimeterFt,
    required this.areaSqft,
    required this.perimeterM,
    required this.areaSqm,
    required this.contourPoints,
  });

  final int planId;
  final int pageNumber;
  final String variant;
  final double perimeterPx;
  final double areaPx2;
  final double mmPerPixel;
  final double perimeterFt;
  final double areaSqft;
  final double perimeterM;
  final double areaSqm;
  final List<Map<String, double>> contourPoints;

  factory FloorMetricsResult.fromJson(Map<String, dynamic> json) {
    return FloorMetricsResult(
      planId: (json['plan_id'] as num?)?.toInt() ?? 0,
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      variant: (json['variant'] as String?) ?? 'soft',
      perimeterPx: (json['perimeter_px'] as num?)?.toDouble() ?? 0,
      areaPx2: (json['area_px2'] as num?)?.toDouble() ?? 0,
      mmPerPixel: (json['mm_per_pixel'] as num?)?.toDouble() ?? 0,
      perimeterFt: (json['perimeter_ft'] as num?)?.toDouble() ?? 0,
      areaSqft: (json['area_sqft'] as num?)?.toDouble() ?? 0,
      perimeterM: (json['perimeter_m'] as num?)?.toDouble() ?? 0,
      areaSqm: (json['area_sqm'] as num?)?.toDouble() ?? 0,
      contourPoints: ((json['contour_points'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => {
              'x': (p['x'] as num?)?.toDouble() ?? 0,
              'y': (p['y'] as num?)?.toDouble() ?? 0,
            },
          )
          .toList(),
    );
  }
}

class PlanRepository {
  PlanRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  PlanStatus _extractPlan(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response data');
    }
    final plan = data['plan'];
    if (plan is! Map<String, dynamic>) {
      throw Exception('Plan payload missing');
    }
    return PlanStatus.fromJson(plan);
  }

  Future<List<PlanStatus>> listPlans() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/plans');
    final root = response.data ?? const {};
    final data = root['data'];
    if (data is! Map<String, dynamic>) return const [];
    final rows = data['plans'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(PlanStatus.fromJson)
        .toList();
  }

  Future<PlanStatus> upload({
    required String planName,
    required MultipartFile file,
  }) async {
    final form = FormData.fromMap({
      'plan_name': planName,
      'file': file,
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/upload',
      data: form,
    );
    return _extractPlan(response.data ?? const {});
  }

  Future<PlanStatus> preprocess(int planId) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/v1/plans/$planId/preprocess');
    return _extractPlan(response.data ?? const {});
  }

  Future<PlanStatus> getById(int planId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/plans/$planId');
    return _extractPlan(response.data ?? const {});
  }

  Future<List<ManualScaleOption>> getManualScaleOptions() async {
    final response = await _dio.get<Map<String, dynamic>>('/plans/manual-scale-options');
    final root = response.data ?? const {};
    final rows = root['options'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ManualScaleOption.fromJson)
        .toList();
  }

  Future<ManualScaleResult> applyManualScale({
    required double pixelLength,
    required String scaleKey,
    required int dpi,
    required String outputUnit,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/plans/apply-manual-scale',
      data: {
        'pixel_length': pixelLength,
        'scale_key': scaleKey,
        'dpi': dpi,
        'output_unit': outputUnit,
      },
    );
    final root = response.data ?? const {};
    return ManualScaleResult.fromJson(root);
  }

  Future<List<PlanPageMeta>> getPlanPages(int planId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/plans/$planId/pages');
    final root = response.data ?? const {};
    final data = root['data'];
    if (data is! Map<String, dynamic>) return const [];
    final rows = data['pages'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(PlanPageMeta.fromJson)
        .toList();
  }

  Future<PlanCalibration?> getCalibration(int planId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/plans/$planId/calibration');
    final root = response.data ?? const {};
    final data = root['data'];
    if (data is! Map<String, dynamic>) return null;
    final calibration = data['calibration'];
    if (calibration is! Map<String, dynamic>) return null;
    return PlanCalibration.fromJson(calibration);
  }

  Future<PlanCalibration> saveCalibration({
    required int planId,
    required int? pageNumber,
    required String scaleKey,
    required int dpi,
    required double pixelLength,
    required String outputUnit,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/$planId/calibration',
      data: {
        'page_number': pageNumber,
        'scale_key': scaleKey,
        'dpi': dpi,
        'pixel_length': pixelLength,
        'output_unit': outputUnit,
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
      },
    );
    final root = response.data ?? const {};
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid calibration response');
    }
    final calibration = data['calibration'];
    if (calibration is! Map<String, dynamic>) {
      throw Exception('Calibration payload missing');
    }
    return PlanCalibration.fromJson(calibration);
  }

  Future<CalibrationConvertResult> convertUsingCalibration({
    required int planId,
    required List<double> pixelLengths,
    String? outputUnit,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/$planId/calibration/convert',
      data: {
        'pixel_lengths': pixelLengths,
        if (outputUnit != null && outputUnit.isNotEmpty) 'output_unit': outputUnit,
      },
    );
    final root = response.data ?? const {};
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid conversion response');
    }
    return CalibrationConvertResult.fromJson(data);
  }

  Future<List<DetectedElement>> runDetection({
    required int planId,
    String? outputUnit,
    String? variant,
  }) async {
    final body = <String, dynamic>{};
    if (outputUnit != null && outputUnit.isNotEmpty) body['output_unit'] = outputUnit;
    if (variant != null && variant.isNotEmpty) body['variant'] = variant;
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/$planId/detect',
      data: body,
    );
    return listElements(planId);
  }

  Future<List<DetectedElement>> listElements(int planId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/plans/$planId/elements');
    final root = response.data ?? const {};
    final data = root['data'];
    if (data is! Map<String, dynamic>) return const [];
    final rows = data['elements'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(DetectedElement.fromJson)
        .toList();
  }

  Future<FloorMetricsResult> estimateFloorMetrics({
    required int planId,
    int? pageNumber,
    String? variant,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/plans/$planId/floor-metrics',
      data: {
        if (pageNumber != null) 'page_number': pageNumber,
        if (variant != null && variant.isNotEmpty) 'variant': variant,
      },
    );
    final root = response.data ?? const {};
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid floor metrics response');
    }
    return FloorMetricsResult.fromJson(data);
  }
}

