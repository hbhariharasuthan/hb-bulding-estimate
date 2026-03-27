class PlanStatus {
  PlanStatus({
    required this.planId,
    required this.planName,
    required this.filePath,
    required this.fileType,
    required this.status,
    required this.processingProgress,
    this.totalPages,
    this.currentPage,
    this.dpi,
    this.detectedUnits,
    this.errorMessage,
  });

  final int planId;
  final String planName;
  final String filePath;
  final String fileType;
  final String status;
  final int processingProgress;
  final int? totalPages;
  final int? currentPage;
  final double? dpi;
  final String? detectedUnits;
  final String? errorMessage;

  bool get isTerminal => status == 'completed' || status == 'failed';

  factory PlanStatus.fromJson(Map<String, dynamic> json) {
    return PlanStatus(
      planId: (json['plan_id'] as num?)?.toInt() ?? 0,
      planName: (json['plan_name'] as String?) ?? '',
      filePath: (json['file_path'] as String?) ?? '',
      fileType: (json['file_type'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      processingProgress: (json['processing_progress'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt(),
      currentPage: (json['current_page'] as num?)?.toInt(),
      dpi: (json['dpi'] as num?)?.toDouble(),
      detectedUnits: json['detected_units'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}

