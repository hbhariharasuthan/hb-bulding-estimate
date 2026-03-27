import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/di/locator.dart';
import '../../../core/utils/picked_upload.dart';
import '../../../core/utils/web_plan_picker.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/module_page_header.dart';
import '../../../shared/widgets/page_container.dart';
import '../models/plan_status.dart';
import '../repositories/plan_repository.dart';

class PlanPreprocessPage extends StatefulWidget {
  const PlanPreprocessPage({super.key});

  @override
  State<PlanPreprocessPage> createState() => _PlanPreprocessPageState();
}

class _PlanPreprocessPageState extends State<PlanPreprocessPage> {
  final _repo = getPlanRepository();
  final _planNameCtrl = TextEditingController();
  final _pixelLengthCtrl = TextEditingController();
  final _dpiCtrl = TextEditingController(text: '96');

  PickedUpload? _pickedFile;
  PlanStatus? _plan;
  bool _uploading = false;
  bool _processing = false;
  bool _loadingScaleOptions = false;
  bool _applyingScale = false;
  bool _savingCalibration = false;
  bool _runningDetection = false;
  bool _estimatingFloor = false;
  bool _loadingElements = false;
  bool _loadingPages = false;
  Timer? _polling;
  List<ManualScaleOption> _scaleOptions = const [];
  String? _selectedScaleKey;
  String _selectedOutputUnit = 'm';
  String _viewerVariant = 'soft';
  ManualScaleResult? _scaleResult;
  List<PlanPageMeta> _pages = const [];
  int _selectedPageIndex = 0;
  PlanCalibration? _savedCalibration;
  List<DetectedElement> _detectedElements = const [];
  FloorMetricsResult? _floorMetrics;
  Offset? _measurePointA;
  Offset? _measurePointB;
  bool _manualFloorMode = false;
  List<Offset> _manualFloorPoints = const [];

  @override
  void initState() {
    super.initState();
    _loadScaleOptions();
  }

  @override
  void dispose() {
    _polling?.cancel();
    _planNameCtrl.dispose();
    _pixelLengthCtrl.dispose();
    _dpiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadScaleOptions() async {
    setState(() => _loadingScaleOptions = true);
    try {
      final options = await _repo.getManualScaleOptions();
      if (!mounted) return;
      setState(() {
        _scaleOptions = options;
        _selectedScaleKey = options.isNotEmpty ? options.first.key : null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load manual scale options')),
      );
    } finally {
      if (mounted) setState(() => _loadingScaleOptions = false);
    }
  }

  Future<void> _pickFile() async {
    final file = await pickPlanFileForWeb();
    if (file == null) return;
    if (!mounted) return;
    setState(() => _pickedFile = file);
  }

  Future<void> _upload() async {
    if (_pickedFile == null) return;
    final defaultName = _pickedFile!.name.split('.').first.trim();
    final entered = _planNameCtrl.text.trim();
    final planName = entered.isNotEmpty ? entered : (defaultName.isEmpty ? 'New Plan' : defaultName);

    setState(() => _uploading = true);
    try {
      final file = MultipartFile.fromBytes(_pickedFile!.bytes, filename: _pickedFile!.name);
      final uploaded = await _repo.upload(planName: planName, file: file);
      if (!mounted) return;
      setState(() {
        _plan = uploaded;
        _scaleResult = null;
        _savedCalibration = null;
        _pages = const [];
        _detectedElements = const [];
        _floorMetrics = null;
        _selectedPageIndex = 0;
        _measurePointA = null;
        _measurePointB = null;
        _manualFloorMode = false;
        _manualFloorPoints = const [];
        if ((uploaded.dpi ?? 0) > 0) {
          _dpiCtrl.text = uploaded.dpi!.round().toString();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _startProcessing() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _processing = true);
    try {
      final updated = await _repo.preprocess(plan.planId);
      if (!mounted) return;
      setState(() {
        _plan = updated;
        if ((updated.dpi ?? 0) > 0) {
          _dpiCtrl.text = updated.dpi!.round().toString();
        }
      });
      await _loadPlanPages(updated.planId);
      await _loadCalibration(updated.planId);
      await _loadElements(updated.planId);
      _startPolling(plan.planId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start processing failed: $e')),
      );
    }
  }

  void _startPolling(int planId) {
    _polling?.cancel();
    _polling = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final latest = await _repo.getById(planId);
        if (!mounted) return;
        setState(() {
          _plan = latest;
          if ((latest.dpi ?? 0) > 0) {
            _dpiCtrl.text = latest.dpi!.round().toString();
          }
        });
        if (latest.isTerminal) {
          _polling?.cancel();
          setState(() => _processing = false);
          _loadPlanPages(planId);
          _loadCalibration(planId);
          _loadElements(planId);
        }
      } catch (_) {
        // Keep polling unless terminal state is reached.
      }
    });
  }

  Future<void> _loadPlanPages(int planId) async {
    setState(() => _loadingPages = true);
    try {
      final pages = await _repo.getPlanPages(planId);
      if (!mounted) return;
      setState(() {
        _pages = pages;
        if (_selectedPageIndex >= pages.length) {
          _selectedPageIndex = 0;
        }
        _measurePointA = null;
        _measurePointB = null;
        _manualFloorMode = false;
        _manualFloorPoints = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _pages = const []);
    } finally {
      if (mounted) setState(() => _loadingPages = false);
    }
  }

  Future<void> _loadCalibration(int planId) async {
    try {
      final calibration = await _repo.getCalibration(planId);
      if (!mounted || calibration == null) return;
      setState(() {
        _savedCalibration = calibration;
        if (calibration.scaleKey != null && calibration.scaleKey!.isNotEmpty) {
          _selectedScaleKey = calibration.scaleKey;
        }
        if ((calibration.dpi ?? 0) > 0) {
          _dpiCtrl.text = calibration.dpi!.toString();
        }
        if ((calibration.pixelLength ?? 0) > 0) {
          _pixelLengthCtrl.text = calibration.pixelLength!.toStringAsFixed(2);
        }
        if (calibration.outputUnit != null && calibration.outputUnit!.isNotEmpty) {
          _selectedOutputUnit = calibration.outputUnit!;
        }
        if ((calibration.realLength ?? 0) > 0 && (calibration.mmPerPixel ?? 0) > 0) {
          _scaleResult = ManualScaleResult(
            pixelLength: calibration.pixelLength ?? 0,
            scaleKey: calibration.scaleKey ?? '',
            dpi: calibration.dpi ?? 96,
            outputUnit: calibration.outputUnit ?? 'm',
            realLength: calibration.realLength ?? 0,
            scaleFactorMmPerPixel: calibration.mmPerPixel ?? 0,
          );
        }
      });
    } catch (_) {
      // Ignore auto-load failures; manual flow remains usable.
    }
  }

  Future<void> _loadElements(int planId) async {
    setState(() => _loadingElements = true);
    try {
      final rows = await _repo.listElements(planId);
      if (!mounted) return;
      setState(() => _detectedElements = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _detectedElements = const []);
    } finally {
      if (mounted) setState(() => _loadingElements = false);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '-';
    if (bytes < 1024) return '${bytes} B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Rect _fitContainRect({
    required Size boxSize,
    required int imageWidth,
    required int imageHeight,
  }) {
    final scale = math.min(
      boxSize.width / imageWidth,
      boxSize.height / imageHeight,
    );
    final drawW = imageWidth * scale;
    final drawH = imageHeight * scale;
    final dx = (boxSize.width - drawW) / 2;
    final dy = (boxSize.height - drawH) / 2;
    return Rect.fromLTWH(dx, dy, drawW, drawH);
  }

  void _onProcessedTap({
    required TapDownDetails details,
    required Size boxSize,
    required PlanPageMeta page,
  }) {
    final info = _variantImageInfo(page);
    final imgW = info.width;
    final imgH = info.height;
    if (imgW == null || imgH == null || imgW <= 0 || imgH <= 0) return;

    final rect = _fitContainRect(boxSize: boxSize, imageWidth: imgW, imageHeight: imgH);
    final local = details.localPosition;
    if (!rect.contains(local)) return;

    final nx = ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final ny = ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0);
    final imagePoint = Offset(nx * imgW, ny * imgH);

    if (_manualFloorMode) {
      setState(() {
        _manualFloorPoints = [..._manualFloorPoints, imagePoint];
      });
      return;
    }

    setState(() {
      if (_measurePointA == null || (_measurePointA != null && _measurePointB != null)) {
        _measurePointA = imagePoint;
        _measurePointB = null;
      } else {
        _measurePointB = imagePoint;
        final px = (_measurePointB! - _measurePointA!).distance;
        _pixelLengthCtrl.text = px.toStringAsFixed(2);
      }
    });
  }

  String _variantImagePath(PlanPageMeta page) {
    if (_viewerVariant == 'source') return page.sourceImage;
    if (_viewerVariant == 'binary') {
      return page.processedBinaryImage.isNotEmpty ? page.processedBinaryImage : page.processedImage;
    }
    if (_viewerVariant == 'ocr') return page.processedImage;
    return page.processedSoftImage.isNotEmpty ? page.processedSoftImage : page.processedImage;
  }

  PlanImageInfo _variantImageInfo(PlanPageMeta page) {
    if (_viewerVariant == 'source') return page.sourceInfo;
    if (_viewerVariant == 'binary') {
      return (page.processedBinaryInfo.width ?? 0) > 0 ? page.processedBinaryInfo : page.processedInfo;
    }
    if (_viewerVariant == 'ocr') return page.processedInfo;
    return (page.processedSoftInfo.width ?? 0) > 0 ? page.processedSoftInfo : page.processedInfo;
  }

  List<Offset> _overlayContourPointsForCurrentImage() {
    final metrics = _floorMetrics;
    final selected = _pages.isNotEmpty ? _pages[_selectedPageIndex] : null;
    final info = selected == null ? null : _variantImageInfo(selected);
    if (metrics == null || selected == null || info == null) return const [];
    if (metrics.pageNumber != selected.pageNumber) return const [];
    if (metrics.variant != _viewerVariant) return const [];
    final w = info.width ?? 0;
    final h = info.height ?? 0;
    if (w <= 0 || h <= 0) return const [];
    return metrics.contourPoints
        .map(
          (p) => Offset(
            ((p['x'] ?? 0) / w).clamp(0.0, 1.0),
            ((p['y'] ?? 0) / h).clamp(0.0, 1.0),
          ),
        )
        .toList();
  }

  void _applyManualFloorPolygon() {
    final cal = _savedCalibration;
    final selected = _pages.isNotEmpty ? _pages[_selectedPageIndex] : null;
    if (cal == null || selected == null || (cal.mmPerPixel ?? 0) <= 0 || _manualFloorPoints.length < 3) {
      return;
    }
    final mmPerPixel = cal.mmPerPixel!;

    double perimeterPx = 0;
    for (var i = 0; i < _manualFloorPoints.length; i++) {
      final a = _manualFloorPoints[i];
      final b = _manualFloorPoints[(i + 1) % _manualFloorPoints.length];
      perimeterPx += (b - a).distance;
    }

    double twiceArea = 0;
    for (var i = 0; i < _manualFloorPoints.length; i++) {
      final a = _manualFloorPoints[i];
      final b = _manualFloorPoints[(i + 1) % _manualFloorPoints.length];
      twiceArea += (a.dx * b.dy) - (b.dx * a.dy);
    }
    final areaPx2 = (twiceArea.abs()) / 2.0;

    final perimeterMm = perimeterPx * mmPerPixel;
    final areaMm2 = areaPx2 * (mmPerPixel * mmPerPixel);
    const mmPerFoot = 304.8;
    final perimeterFt = perimeterMm / mmPerFoot;
    final areaSqft = areaMm2 / (mmPerFoot * mmPerFoot);
    final perimeterM = perimeterMm / 1000.0;
    final areaSqm = areaMm2 / 1_000_000.0;

    final info = _variantImageInfo(selected);
    final w = (info.width ?? 0).toDouble();
    final h = (info.height ?? 0).toDouble();
    final contour = (w > 0 && h > 0)
        ? _manualFloorPoints
              .map((p) => {'x': p.dx, 'y': p.dy})
              .toList()
        : <Map<String, double>>[];

    setState(() {
      _floorMetrics = FloorMetricsResult(
        planId: _plan?.planId ?? 0,
        pageNumber: selected.pageNumber,
        variant: _viewerVariant,
        perimeterPx: perimeterPx,
        areaPx2: areaPx2,
        mmPerPixel: mmPerPixel,
        perimeterFt: perimeterFt,
        areaSqft: areaSqft,
        perimeterM: perimeterM,
        areaSqm: areaSqm,
        contourPoints: contour,
      );
    });
  }

  Widget _buildMeasurementPoint({
    required Offset imagePoint,
    required Rect drawRect,
    required int imageWidth,
    required int imageHeight,
    required Color color,
    required String label,
  }) {
    final dx = drawRect.left + (imagePoint.dx / imageWidth) * drawRect.width;
    final dy = drawRect.top + (imagePoint.dy / imageHeight) * drawRect.height;
    return Positioned(
      left: dx - 8,
      top: dy - 8,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _applyManualScale() async {
    final scaleKey = _selectedScaleKey;
    if (scaleKey == null || scaleKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a scale first')),
      );
      return;
    }

    final pixelLength = double.tryParse(_pixelLengthCtrl.text.trim());
    if (pixelLength == null || pixelLength <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid pixel length')),
      );
      return;
    }

    final dpi = int.tryParse(_dpiCtrl.text.trim());
    if (dpi == null || dpi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid DPI')),
      );
      return;
    }

    setState(() => _applyingScale = true);
    try {
      final result = await _repo.applyManualScale(
        pixelLength: pixelLength,
        scaleKey: scaleKey,
        dpi: dpi,
        outputUnit: _selectedOutputUnit,
      );
      if (!mounted) return;
      setState(() => _scaleResult = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apply scale failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _applyingScale = false);
    }
  }

  Future<void> _saveCalibration() async {
    final plan = _plan;
    final scaleKey = _selectedScaleKey;
    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload/select a plan first')),
      );
      return;
    }
    if (scaleKey == null || scaleKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a scale first')),
      );
      return;
    }
    final pixelLength = double.tryParse(_pixelLengthCtrl.text.trim());
    final dpi = int.tryParse(_dpiCtrl.text.trim());
    if (pixelLength == null || pixelLength <= 0 || dpi == null || dpi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apply scale with valid inputs before saving')),
      );
      return;
    }
    setState(() => _savingCalibration = true);
    try {
      final pageNumber = _pages.isNotEmpty ? _pages[_selectedPageIndex].pageNumber : null;
      final saved = await _repo.saveCalibration(
        planId: plan.planId,
        pageNumber: pageNumber,
        scaleKey: scaleKey,
        dpi: dpi,
        pixelLength: pixelLength,
        outputUnit: _selectedOutputUnit,
        x1: _measurePointA?.dx,
        y1: _measurePointA?.dy,
        x2: _measurePointB?.dx,
        y2: _measurePointB?.dy,
      );
      if (!mounted) return;
      setState(() {
        _savedCalibration = saved;
        _scaleResult = ManualScaleResult(
          pixelLength: saved.pixelLength ?? pixelLength,
          scaleKey: saved.scaleKey ?? scaleKey,
          dpi: saved.dpi ?? dpi,
          outputUnit: saved.outputUnit ?? _selectedOutputUnit,
          realLength: saved.realLength ?? (_scaleResult?.realLength ?? 0),
          scaleFactorMmPerPixel: saved.mmPerPixel ?? (_scaleResult?.scaleFactorMmPerPixel ?? 0),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibration saved to database')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save calibration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingCalibration = false);
    }
  }

  Future<void> _runDetection() async {
    final plan = _plan;
    if (plan == null) return;
    if (_savedCalibration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save calibration first, then run detection.')),
      );
      return;
    }
    setState(() => _runningDetection = true);
    try {
      final rows = await _repo.runDetection(
        planId: plan.planId,
        outputUnit: _selectedOutputUnit,
        variant: _viewerVariant,
      );
      if (!mounted) return;
      setState(() => _detectedElements = rows);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detection completed: ${rows.length} element(s)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Run detection failed: ${_friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _runningDetection = false);
    }
  }

  Future<void> _estimateFloorArea() async {
    final plan = _plan;
    if (plan == null) return;
    if (_savedCalibration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save calibration first, then estimate floor area.')),
      );
      return;
    }
    setState(() => _estimatingFloor = true);
    try {
      final pageNumber = _pages.isNotEmpty ? _pages[_selectedPageIndex].pageNumber : null;
      final metrics = await _repo.estimateFloorMetrics(
        planId: plan.planId,
        pageNumber: pageNumber,
        variant: _viewerVariant,
      );
      if (!mounted) return;
      setState(() => _floorMetrics = metrics);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floor metrics estimated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Floor metrics failed: ${_friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _estimatingFloor = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        final detail = data['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }
      }
      final code = error.response?.statusCode;
      if (code != null) return 'HTTP $code';
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final progress = ((plan?.processingProgress ?? 0) / 100).clamp(0.0, 1.0);
    final hasPages = _pages.isNotEmpty;
    final selectedPage = hasPages ? _pages[_selectedPageIndex] : null;
    final selectedImagePath = selectedPage == null ? '' : _variantImagePath(selectedPage);
    final selectedImageInfo = selectedPage == null ? PlanImageInfo() : _variantImageInfo(selectedPage);
    final normalizedContour = _overlayContourPointsForCurrentImage();

    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PageContainer(
              maxWidth: 1300,
              child: ListView(
                children: [
                  const ModulePageHeader(
                    title: 'Plan Preprocessing',
                    breadcrumbs: ['MASTER', 'PLAN PREPROCESS'],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _planNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name',
                      hintText: 'Optional (auto from file name)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _pickedFile == null ? 'Choose PDF/Image/CAD' : _pickedFile!.name,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _uploading ? null : _upload,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(_uploading ? 'Uploading...' : 'Upload Plan'),
                      ),
                      FilledButton.icon(
                        onPressed: (plan == null || _processing) ? null : _startProcessing,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_processing ? 'Processing...' : 'Start Processing'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (plan != null) ...[
                    Text(
                      'Plan #${plan.planId}: ${plan.planName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text('Status: ${plan.status}'),
                        Text('Progress: ${plan.processingProgress}%'),
                        Text('Page: ${plan.currentPage ?? 0}/${plan.totalPages ?? 0}'),
                        Text('DPI: ${(plan.dpi ?? 0).toStringAsFixed(0)}'),
                        Text('Detected Unit: ${plan.detectedUnits ?? '-'}'),
                      ],
                    ),
                    if ((plan.errorMessage ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${plan.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Manual Scale',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (_loadingScaleOptions)
                    const LinearProgressIndicator()
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            value: _selectedScaleKey,
                            decoration: const InputDecoration(labelText: 'Scale'),
                            items: _scaleOptions
                                .map(
                                  (o) => DropdownMenuItem<String>(
                                    value: o.key,
                                    child: Text(o.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _selectedScaleKey = v),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _pixelLengthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Pixel Length',
                              hintText: 'Required, e.g. 250',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _dpiCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'DPI'),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            value: _selectedOutputUnit,
                            decoration: const InputDecoration(labelText: 'Output Unit'),
                            items: const [
                              DropdownMenuItem(value: 'm', child: Text('m')),
                              DropdownMenuItem(value: 'cm', child: Text('cm')),
                              DropdownMenuItem(value: 'mm', child: Text('mm')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _selectedOutputUnit = v);
                            },
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _applyingScale ? null : _applyManualScale,
                          icon: const Icon(Icons.straighten),
                          label: Text(_applyingScale ? 'Applying...' : 'Apply Scale'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _savingCalibration ? null : _saveCalibration,
                          icon: const Icon(Icons.save),
                          label: Text(
                            _savingCalibration ? 'Saving...' : 'Save Calibration',
                          ),
                        ),
                      ],
                    ),
                  if (_scaleResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text('Scale: ${_scaleResult!.scaleKey}'),
                          Text('DPI: ${_scaleResult!.dpi}'),
                          Text(
                            'Real length: ${_scaleResult!.realLength.toStringAsFixed(3)} ${_scaleResult!.outputUnit}',
                          ),
                          Text(
                            'mm/px: ${_scaleResult!.scaleFactorMmPerPixel.toStringAsFixed(4)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_savedCalibration != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Saved calibration: plan ${_savedCalibration!.planId}'
                      '${_savedCalibration!.pageNumber != null ? ' page ${_savedCalibration!.pageNumber}' : ''}'
                      ', mm/px ${(_savedCalibration!.mmPerPixel ?? 0).toStringAsFixed(4)}',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Page Viewer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: (plan == null || _runningDetection) ? null : _runDetection,
                        icon: const Icon(Icons.auto_fix_high),
                        label: Text(_runningDetection ? 'Running Detection...' : 'Run Detection'),
                      ),
                      FilledButton.icon(
                        onPressed: (plan == null || _estimatingFloor) ? null : _estimateFloorArea,
                        icon: const Icon(Icons.square_foot),
                        label: Text(_estimatingFloor ? 'Estimating Area...' : 'Estimate Floor Area'),
                      ),
                      OutlinedButton.icon(
                        onPressed: (plan == null || _savedCalibration == null)
                            ? null
                            : () => setState(() {
                                _manualFloorMode = !_manualFloorMode;
                                _manualFloorPoints = const [];
                              }),
                        icon: const Icon(Icons.polyline),
                        label: Text(_manualFloorMode ? 'Manual Floor: ON' : 'Manual Polygon Floor'),
                      ),
                      if (_manualFloorMode)
                        FilledButton.icon(
                          onPressed: _manualFloorPoints.length >= 3 ? _applyManualFloorPolygon : null,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Compute Manual Area'),
                        ),
                      if (_manualFloorMode)
                        OutlinedButton.icon(
                          onPressed: _manualFloorPoints.isEmpty
                              ? null
                              : () => setState(() {
                                  _manualFloorPoints = _manualFloorPoints.sublist(
                                    0,
                                    _manualFloorPoints.length - 1,
                                  );
                                }),
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo Last Point'),
                        ),
                      if (_manualFloorMode)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _manualFloorPoints = const []),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Floor Points'),
                        ),
                      OutlinedButton.icon(
                        onPressed: (plan == null || _loadingElements)
                            ? null
                            : () => _loadElements(plan.planId),
                        icon: const Icon(Icons.refresh),
                        label: Text(_loadingElements ? 'Refreshing...' : 'Refresh Elements'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (plan == null)
                    const Text('Upload and process a plan to view pages.')
                  else if (_loadingPages)
                    const LinearProgressIndicator()
                  else if (!hasPages)
                    const Text('No processed pages found yet.')
                  else
                    Container(
                      height: 460,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 210,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(10),
                              itemCount: _pages.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final page = _pages[index];
                                final selected = index == _selectedPageIndex;
                                return InkWell(
                                  onTap: () => setState(() {
                                    _selectedPageIndex = index;
                                    _measurePointA = null;
                                    _measurePointB = null;
                                  }),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: selected ? Colors.blue.shade50 : Colors.white,
                                      border: Border.all(
                                        color: selected ? Colors.blue : Colors.blueGrey.shade100,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Page ${page.pageNumber}'),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            ApiConfig.buildUri(page.sourceImage).toString(),
                                            height: 110,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 110,
                                              color: Colors.grey.shade200,
                                              alignment: Alignment.center,
                                              child: const Text('Preview unavailable'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: selectedPage == null
                                ? const Center(child: Text('Select a page'))
                                : Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 10,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  const Text('Viewer'),
                                                  DropdownButton<String>(
                                                    value: _viewerVariant,
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 'soft',
                                                        child: Text('Soft (recommended)'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'binary',
                                                        child: Text('Binary'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'ocr',
                                                        child: Text('OCR-enhanced'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'source',
                                                        child: Text('Source'),
                                                      ),
                                                    ],
                                                    onChanged: (v) {
                                                      if (v == null) return;
                                                      setState(() {
                                                        _viewerVariant = v;
                                                        _measurePointA = null;
                                                        _measurePointB = null;
                                                      });
                                                    },
                                                  ),
                                                  const Text('(click two points to measure)'),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      final box = Size(
                                                        constraints.maxWidth,
                                                        constraints.maxHeight,
                                                      );
                                                      final imgW = selectedImageInfo.width;
                                                      final imgH = selectedImageInfo.height;
                                                      final canMeasure =
                                                          imgW != null &&
                                                          imgH != null &&
                                                          imgW > 0 &&
                                                          imgH > 0;
                                                      final manualNormalized =
                                                          canMeasure && _manualFloorPoints.isNotEmpty
                                                          ? _manualFloorPoints
                                                                .map(
                                                                  (p) => Offset(
                                                                    (p.dx / imgW).clamp(0.0, 1.0),
                                                                    (p.dy / imgH).clamp(0.0, 1.0),
                                                                  ),
                                                                )
                                                                .toList()
                                                          : const <Offset>[];
                                                      final drawRect = canMeasure
                                                          ? _fitContainRect(
                                                              boxSize: box,
                                                              imageWidth: imgW,
                                                              imageHeight: imgH,
                                                            )
                                                          : Rect.zero;
                                                      return GestureDetector(
                                                        onTapDown: canMeasure
                                                            ? (d) => _onProcessedTap(
                                                                details: d,
                                                                boxSize: box,
                                                                page: selectedPage,
                                                              )
                                                            : null,
                                                        child: Stack(
                                                          children: [
                                                            Positioned.fill(
                                                              child: Image.network(
                                                                ApiConfig.buildUri(selectedImagePath).toString(),
                                                                fit: BoxFit.contain,
                                                              ),
                                                            ),
                                                            if (canMeasure && normalizedContour.length >= 3)
                                                              Positioned.fill(
                                                                child: IgnorePointer(
                                                                  child: CustomPaint(
                                                                    painter: _FloorOverlayPainter(
                                                                      normalizedPoints: normalizedContour,
                                                                      drawRect: drawRect,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            if (canMeasure && _manualFloorMode && manualNormalized.length >= 2)
                                                              Positioned.fill(
                                                                child: IgnorePointer(
                                                                  child: CustomPaint(
                                                                    painter: _FloorOverlayPainter(
                                                                      normalizedPoints: manualNormalized,
                                                                      drawRect: drawRect,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            if (canMeasure && _manualFloorMode)
                                                              ..._manualFloorPoints.asMap().entries.map(
                                                                (entry) => _buildMeasurementPoint(
                                                                  imagePoint: entry.value,
                                                                  drawRect: drawRect,
                                                                  imageWidth: imgW,
                                                                  imageHeight: imgH,
                                                                  color: Colors.orange,
                                                                  label: '${entry.key + 1}',
                                                                ),
                                                              ),
                                                            if (canMeasure && _measurePointA != null)
                                                              _buildMeasurementPoint(
                                                                imagePoint: _measurePointA!,
                                                                drawRect: drawRect,
                                                                imageWidth: imgW,
                                                                imageHeight: imgH,
                                                                color: Colors.blue,
                                                                label: '1',
                                                              ),
                                                            if (canMeasure && _measurePointB != null)
                                                              _buildMeasurementPoint(
                                                                imagePoint: _measurePointB!,
                                                                drawRect: drawRect,
                                                                imageWidth: imgW,
                                                                imageHeight: imgH,
                                                                color: Colors.red,
                                                                label: '2',
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Size: ${selectedImageInfo.width ?? '-'}x${selectedImageInfo.height ?? '-'}  ${_formatSize(selectedImageInfo.fileSize)}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 6,
                                          children: [
                                            Text(
                                              _manualFloorMode
                                                  ? (_manualFloorPoints.length < 3
                                                        ? 'Manual floor mode: click at least 3 boundary points'
                                                        : 'Points: ${_manualFloorPoints.length}. Click "Compute Manual Area"')
                                                  : _measurePointA == null
                                                  ? 'Click point 1 on processed image'
                                                  : (_measurePointB == null
                                                        ? 'Click point 2 to auto-fill Pixel Length'
                                                        : 'Pixel Length filled. Click image to start new measurement'),
                                            ),
                                            if (_measurePointA != null && _measurePointB != null)
                                              OutlinedButton(
                                                onPressed: () => setState(() {
                                                  _measurePointA = null;
                                                  _measurePointB = null;
                                                }),
                                                child: const Text('Clear Measurement'),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Detected Unit: ${selectedPage.detectedUnit.isEmpty ? '-' : selectedPage.detectedUnit}',
                                        ),
                                        if (selectedPage.explanation.isNotEmpty)
                                          Text('Notes: ${selectedPage.explanation}'),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Floor Metrics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_floorMetrics == null)
                    const Text('Run "Estimate Floor Area" to calculate perimeter and area.')
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text('Page: ${_floorMetrics!.pageNumber}'),
                          Text('Variant: ${_floorMetrics!.variant}'),
                          Text('Perimeter: ${_floorMetrics!.perimeterFt.toStringAsFixed(2)} ft'),
                          Text('Area: ${_floorMetrics!.areaSqft.toStringAsFixed(2)} sq ft'),
                          Text('Perimeter: ${_floorMetrics!.perimeterM.toStringAsFixed(2)} m'),
                          Text('Area: ${_floorMetrics!.areaSqm.toStringAsFixed(2)} sq m'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Detected Elements',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_loadingElements)
                    const LinearProgressIndicator()
                  else if (_detectedElements.isEmpty)
                    const Text('No detected elements yet. Click Run Detection.')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Px Length')),
                          DataColumn(label: Text('Length')),
                          DataColumn(label: Text('Label')),
                          DataColumn(label: Text('Confidence')),
                        ],
                        rows: _detectedElements
                            .map(
                              (e) => DataRow(
                                cells: [
                                  DataCell(Text('${e.elementId}')),
                                  DataCell(Text(e.elementType)),
                                  DataCell(Text(
                                    e.pixelLength == null ? '-' : e.pixelLength!.toStringAsFixed(2),
                                  )),
                                  DataCell(Text(
                                    e.length == null
                                        ? '-'
                                        : '${e.length!.toStringAsFixed(3)} ${_selectedOutputUnit}',
                                  )),
                                  DataCell(Text(e.detectedLabel ?? '-')),
                                  DataCell(Text(
                                    e.confidenceScore == null
                                        ? '-'
                                        : e.confidenceScore!.toStringAsFixed(2),
                                  )),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

class _FloorOverlayPainter extends CustomPainter {
  _FloorOverlayPainter({
    required this.normalizedPoints,
    required this.drawRect,
  });

  final List<Offset> normalizedPoints;
  final Rect drawRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPoints.length < 3) return;
    final path = ui.Path();
    for (var i = 0; i < normalizedPoints.length; i++) {
      final np = normalizedPoints[i];
      final x = drawRect.left + np.dx * drawRect.width;
      final y = drawRect.top + np.dy * drawRect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fill = Paint()
      ..color = Colors.green.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _FloorOverlayPainter oldDelegate) {
    return oldDelegate.normalizedPoints != normalizedPoints || oldDelegate.drawRect != drawRect;
  }
}

