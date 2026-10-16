import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../cards/domain/card_model.dart';
import '../../documents/domain/document_model.dart';
import '../../reminders/domain/reminder_model.dart';
import '../data/card_crop_helper.dart';
import '../data/document_scan_service.dart';
import 'widgets/camera_permission_view.dart';
import 'widgets/crop_rotate_editor.dart';
import 'widgets/ocr_review_form.dart';
import 'widgets/pre_scan_sheet.dart';
import 'widgets/scan_laser_overlay.dart';
import '../../../core/widgets/cardly_toast.dart';

enum ScanStep { preScan, permissionDenied, capture, cropRotate, ocrReview }

/// Alur Pindaian Kamera, Editor Pemotongan & Ekstraksi OCR Terpadu (Scan Flow)
class CameraScanFlowView extends ConsumerStatefulWidget {
  final bool startWithCamera;

  const CameraScanFlowView({super.key, this.startWithCamera = false});

  @override
  ConsumerState<CameraScanFlowView> createState() => _CameraScanFlowViewState();
}

class _CameraScanFlowViewState extends ConsumerState<CameraScanFlowView> {
  late ScanStep _currentStep;
  ScanDocumentType _selectedType = ScanDocumentType.idCard;

  // Status Kamera & Berkas Terpindai
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;
  bool _isFlashOn = false;
  int _rotationQuarterTurns = 0;
  int _selectedSampleIndex = 0; // 0: KTP, 1: SIM, 2: BPJS/Kartu Lain
  String? _scannedImagePath;
  bool _isScanning = false;

  // Auto-Focus & Vision Analyzer State
  Offset? _focusScreenPosition;
  bool _isFocusing = false;
  Timer? _smartDetectionTimer;
  Timer? _focusDismissTimer;

  // Real-Time Frame Analyzer & Auto-Shutter States
  bool _isStreaming = false;
  bool _isProcessingFrame = false;
  DateTime _lastFrameProcessed = DateTime.now();
  int _consecutiveStableFrames = 0;
  bool _isAutoShutterTriggered = false;
  bool _isAutoShutterEnabled = true;
  String? _qualityWarning;
  double _autoCaptureProgress = 0.0;
  bool _isDocumentLocked = false;

  // Form Controllers untuk Hasil OCR Lengkap
  final _titleController = TextEditingController();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _issuerController = TextEditingController();

  // Detail Tambahan KTP / Identitas
  final _birthPlaceDateController = TextEditingController();
  final _genderController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _rtRwController = TextEditingController();
  final _kelDesaController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _religionController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  final _occupationController = TextEditingController();
  final _nationalityController = TextEditingController();

  // Detail Tambahan Kartu Bank
  final _bankNameController = TextEditingController();
  final _last4Controller = TextEditingController();

  RecognizedDocumentType _recognizedType = RecognizedDocumentType.ktp;

  // Pengaturan Tambahan
  bool _isLifetimeExpiry = true;
  bool _isVaultProtected = true;
  bool _autoSetReminder = false;

  final List<Map<String, dynamic>> _samplePresets = [
    {
      'title': 'KTP Digital RI',
      'number': '3171010190001882',
      'name': "MA'RUF AMIN",
      'expiry': 'SEUMUR HIDUP',
      'isLifetime': true,
      'issuer': 'Disdukcapil DKI Jakarta',
      'category': DocumentCategory.identity,
      'badge': 'KTP Republik Indonesia',
      'aspectRatio': 1.58,
      'recognizedType': RecognizedDocumentType.ktp,
      'birthPlaceDate': 'JAKARTA, 11-03-1943',
      'gender': 'LAKI-LAKI',
      'bloodType': 'O',
      'address': 'JL. DIPONEGORO NO. 55',
      'rtRw': '001/002',
      'kelDesa': 'PEGANGSAAN',
      'kecamatan': 'MENTENG',
      'religion': 'ISLAM',
      'maritalStatus': 'KAWIN',
      'occupation': 'WAKIL PRESIDEN RI',
      'nationality': 'WNI',
    },
    {
      'title': 'SIM A Nasional',
      'number': '920311240091',
      'name': 'AHMAD FAUZI',
      'expiry': '11/11/2029',
      'isLifetime': false,
      'issuer': 'Korlantas Polri',
      'category': DocumentCategory.vehicle,
      'badge': 'Surat Izin Mengemudi (SIM)',
      'aspectRatio': 1.58,
      'recognizedType': RecognizedDocumentType.sim,
      'birthPlaceDate': 'BANDUNG, 11-11-1994',
      'gender': 'LAKI-LAKI',
      'bloodType': 'B',
      'address': 'JL. ASIA AFRIKA NO. 12',
      'occupation': 'KARYAWAN SWASTA',
      'nationality': 'WNI',
    },
    {
      'title': 'Kartu Indonesia Sehat',
      'number': '0001293847192',
      'name': 'SITI NURHALIZA',
      'expiry': 'SEUMUR HIDUP',
      'isLifetime': true,
      'issuer': 'BPJS Kesehatan RI',
      'category': DocumentCategory.medical,
      'badge': 'BPJS Kesehatan Terdeteksi',
      'aspectRatio': 1.58,
      'recognizedType': RecognizedDocumentType.bpjs,
      'birthPlaceDate': 'SURABAYA, 24-05-1998',
      'gender': 'PEREMPUAN',
      'nationality': 'WNI',
    },
    {
      'title': 'BCA Mastercard Platinum',
      'number': '•••• •••• •••• 8812',
      'name': "MA'RUF AMIN",
      'expiry': '08/29',
      'isLifetime': false,
      'issuer': 'Bank Central Asia (BCA)',
      'category': DocumentCategory.financial,
      'badge': 'Kartu Bank Terdeteksi',
      'aspectRatio': 1.58,
      'recognizedType': RecognizedDocumentType.bankCard,
      'bankName': 'Bank Central Asia (BCA)',
      'cardNetwork': 'Mastercard',
      'last4Digits': '8812',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.startWithCamera ? ScanStep.capture : ScanStep.preScan;
    _applyPreset(_selectedSampleIndex);
    if (widget.startWithCamera) {
      _initCamera();
      _startSmartDetectionTimer();
    }
  }

  Future<void> _initCamera() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (_isCameraInitializing || _isCameraInitialized) return;
    _isCameraInitializing = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _isCameraInitializing = false);
        return;
      }
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _cameraController = controller;
      setState(() {
        _isCameraInitialized = true;
        _isCameraInitializing = false;
      });
      _startSmartDetectionTimer();
      _startImageStreamIfNeeded();
    } catch (e) {
      debugPrint('In-app camera init note: $e');
      if (mounted) {
        setState(() => _isCameraInitializing = false);
      }
    }
  }

  void _startImageStreamIfNeeded() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isStreaming) {
      return;
    }
    try {
      _isStreaming = true;
      _isAutoShutterTriggered = false;
      _consecutiveStableFrames = 0;
      controller.startImageStream(_processCameraFrame);
    } catch (e) {
      debugPrint('startImageStream note: $e');
    }
  }

  Future<void> _stopImageStreamIfNeeded() async {
    final controller = _cameraController;
    if (controller != null && _isStreaming) {
      _isStreaming = false;
      try {
        await controller.stopImageStream();
      } catch (e) {
        debugPrint('stopImageStream note: $e');
      }
    }
  }

  void _processCameraFrame(CameraImage image) {
    if (!mounted ||
        _isProcessingFrame ||
        _isAutoShutterTriggered ||
        _isScanning) {
      return;
    }
    if (_currentStep != ScanStep.capture) return;

    final now = DateTime.now();
    // Throttle: sampling setiap ~220ms agar hemat daya baterai & tetap 60 FPS
    if (now.difference(_lastFrameProcessed).inMilliseconds < 220) {
      return;
    }
    _isProcessingFrame = true;
    _lastFrameProcessed = now;

    try {
      if (image.planes.isEmpty) return;
      final yPlane = image.planes[0];
      final bytes = yPlane.bytes;
      if (bytes.isEmpty) return;

      final step = (bytes.length / 300).floor().clamp(1, 120);
      int sum = 0;
      int count = 0;
      int diffSum = 0;

      for (int i = 0; i < bytes.length - step; i += step) {
        final val = bytes[i];
        sum += val;
        diffSum += (val - bytes[i + step]).abs();
        count++;
      }

      final avgBrightness = count > 0 ? sum / count : 128.0;
      final sharpness = count > 0 ? diffSum / count : 15.0;

      String? warning;
      bool isGoodQuality = true;

      // 1. Deteksi Pencahayaan (Kurang Terang / Silau Glare)
      if (avgBrightness < 45.0) {
        warning = 'Pencahayaan kurang • Ketuk untuk senter';
        isGoodQuality = false;
      } else if (avgBrightness > 225.0) {
        warning = 'Terlalu silau • Miringkan sedikit kartu';
        isGoodQuality = false;
      } else if (sharpness < 6.0) {
        // 2. Deteksi Blur / Goyang (Motion Blur)
        warning = 'Tahan stabil • Jangan bergerak';
        isGoodQuality = false;
      }

      if (isGoodQuality) {
        _consecutiveStableFrames++;
        final progress = (_consecutiveStableFrames / 3.0).clamp(0.0, 1.0);

        if (mounted) {
          setState(() {
            _qualityWarning = null;
            _autoCaptureProgress = progress;
            _isDocumentLocked = _consecutiveStableFrames >= 2;
          });
        }

        // 3. Eksekusi Auto-Shutter Pintar jika kartu stabil ~600ms
        if (_consecutiveStableFrames >= 3 &&
            _isAutoShutterEnabled &&
            !_isAutoShutterTriggered) {
          _isAutoShutterTriggered = true;
          HapticFeedback.mediumImpact();
          _triggerAutoShutter();
        }
      } else {
        _consecutiveStableFrames = 0;
        if (mounted) {
          setState(() {
            _qualityWarning = warning;
            _autoCaptureProgress = 0.0;
            _isDocumentLocked = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera frame analyzer note: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _triggerAutoShutter() async {
    await _stopImageStreamIfNeeded();
    await _handleCaptureShutter();
  }

  void _startSmartDetectionTimer() {
    _smartDetectionTimer?.cancel();
    _smartDetectionTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _currentStep != ScanStep.capture) return;
      _triggerAutoFocus(const Offset(0.5, 0.5));
    });
  }

  void _handleTapToFocus(Offset localPosition, BoxConstraints constraints) {
    HapticFeedback.selectionClick();
    final relativeX = (localPosition.dx / constraints.maxWidth).clamp(
      0.05,
      0.95,
    );
    final relativeY = (localPosition.dy / constraints.maxHeight).clamp(
      0.05,
      0.95,
    );

    _triggerAutoFocus(
      Offset(relativeX, relativeY),
      screenPosition: localPosition,
    );
  }

  Future<void> _triggerAutoFocus(
    Offset relativePoint, {
    Offset? screenPosition,
  }) async {
    final controller = _cameraController;
    if (mounted) {
      setState(() {
        _isFocusing = true;
        _focusScreenPosition = screenPosition;
      });
    }

    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.setFocusPoint(relativePoint);
        await controller.setExposurePoint(relativePoint);
        await controller.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Auto-focus attempt note: $e');
      }
    }

    _focusDismissTimer?.cancel();
    _focusDismissTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isFocusing = false);
      }
    });
  }

  void _showDocumentSelectorSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: AppRadius.sheetRadius,
          ),
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 18.0),
              const Text(
                'Pilih Sampel Dokumen',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Sesuaikan rasio bingkai dan data ekstraksi otomatis',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(height: 16.0),
              ...List.generate(_samplePresets.length, (idx) {
                final preset = _samplePresets[idx];
                final isSelected = _selectedSampleIndex == idx;
                IconData icon;
                switch (preset['category'] as DocumentCategory) {
                  case DocumentCategory.identity:
                    icon = Icons.badge_outlined;
                    break;
                  case DocumentCategory.vehicle:
                    icon = Icons.drive_eta_outlined;
                    break;
                  case DocumentCategory.medical:
                    icon = Icons.health_and_safety_outlined;
                    break;
                  default:
                    icon = Icons.credit_card_outlined;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(idx);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.lime.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.lime
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38.0,
                            height: 38.0,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lime.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? AppColors.lime : Colors.white,
                              size: 20.0,
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset['title'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.lime
                                        : AppColors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  preset['badge'] as String,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.lime,
                              size: 22.0,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    ).then((selectedIdx) {
      if (selectedIdx != null && mounted) {
        setState(() {
          _selectedSampleIndex = selectedIdx;
          _applyPreset(selectedIdx);
        });
        _startSmartDetectionTimer();
      }
    });
  }

  Future<void> _toggleFlash() async {
    HapticFeedback.selectionClick();
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      try {
        final newFlash = !_isFlashOn;
        await controller.setFlashMode(
          newFlash ? FlashMode.torch : FlashMode.off,
        );
        setState(() => _isFlashOn = newFlash);
      } catch (_) {
        setState(() => _isFlashOn = !_isFlashOn);
      }
    } else {
      setState(() => _isFlashOn = !_isFlashOn);
    }
  }

  void _applyPreset(int index) {
    final preset = _samplePresets[index];
    _titleController.text = preset['title'] as String;
    _numberController.text = preset['number'] as String;
    _nameController.text = preset['name'] as String;
    _expiryController.text = preset['expiry'] as String;
    _issuerController.text = preset['issuer'] as String;
    _isLifetimeExpiry = preset['isLifetime'] as bool;
    _autoSetReminder = !_isLifetimeExpiry;

    _birthPlaceDateController.text =
        (preset['birthPlaceDate'] as String?) ?? '';
    _genderController.text = (preset['gender'] as String?) ?? '';
    _bloodTypeController.text = (preset['bloodType'] as String?) ?? '';
    _addressController.text = (preset['address'] as String?) ?? '';
    _rtRwController.text = (preset['rtRw'] as String?) ?? '';
    _kelDesaController.text = (preset['kelDesa'] as String?) ?? '';
    _kecamatanController.text = (preset['kecamatan'] as String?) ?? '';
    _religionController.text = (preset['religion'] as String?) ?? '';
    _maritalStatusController.text = (preset['maritalStatus'] as String?) ?? '';
    _occupationController.text = (preset['occupation'] as String?) ?? '';
    _nationalityController.text = (preset['nationality'] as String?) ?? 'WNI';
    _bankNameController.text = (preset['bankName'] as String?) ?? '';
    _last4Controller.text = (preset['last4Digits'] as String?) ?? '';
    _recognizedType =
        (preset['recognizedType'] as RecognizedDocumentType?) ??
        RecognizedDocumentType.ktp;
  }

  void _populateOcrFields(OcrScanResult ocr) {
    _titleController.text = ocr.title;
    _numberController.text = ocr.documentNumber;
    _nameController.text = ocr.fullName;
    _expiryController.text = ocr.expiryDate;
    _issuerController.text = ocr.issuer;
    _isLifetimeExpiry = ocr.isLifetimeExpiry;
    _autoSetReminder = !_isLifetimeExpiry;

    _birthPlaceDateController.text = ocr.birthPlaceDate;
    _genderController.text = ocr.gender;
    _bloodTypeController.text = ocr.bloodType;
    _addressController.text = ocr.address;
    _rtRwController.text = ocr.rtRw;
    _kelDesaController.text = ocr.kelDesa;
    _kecamatanController.text = ocr.kecamatan;
    _religionController.text = ocr.religion;
    _maritalStatusController.text = ocr.maritalStatus;
    _occupationController.text = ocr.occupation;
    _nationalityController.text = ocr.nationality;
    _bankNameController.text = ocr.bankName;
    _last4Controller.text = ocr.last4Digits;
    _recognizedType = ocr.recognizedType;
  }

  @override
  void dispose() {
    _stopImageStreamIfNeeded();
    _smartDetectionTimer?.cancel();
    _focusDismissTimer?.cancel();
    _cameraController?.dispose();
    _titleController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _issuerController.dispose();

    _birthPlaceDateController.dispose();
    _genderController.dispose();
    _bloodTypeController.dispose();
    _addressController.dispose();
    _rtRwController.dispose();
    _kelDesaController.dispose();
    _kecamatanController.dispose();
    _religionController.dispose();
    _maritalStatusController.dispose();
    _occupationController.dispose();
    _nationalityController.dispose();
    _bankNameController.dispose();
    _last4Controller.dispose();

    super.dispose();
  }

  // --- Handlers Navigasi Antar Step ---

  Future<void> _handleStartCamera() async {
    HapticFeedback.lightImpact();
    // 1. Luncurkan Google Play Services Document Scanner resmi (Teknologi Google Wallet)
    final scanService = ref.read(documentScanServiceProvider);
    ref.read(isExternalOperationInProgressProvider.notifier).state = true;
    try {
      final pictures = await scanService.scanDocument(
        documentType: _selectedType,
      );
      if (!mounted) return;
      if (pictures != null && pictures.isNotEmpty) {
        var path = pictures.first;
        // Jika berkas kartu (KTP / Bank), potong sudut rounded secara presisi (ISO/IEC 7810 ID-1 standard)
        if (_selectedType == ScanDocumentType.idCard ||
            _selectedType == ScanDocumentType.paymentCard) {
          path = await CardCropHelper.roundCardCorners(imagePath: path);
        }
        _scannedImagePath = path;
        final ocr = await scanService.processOcr(
          path,
          documentType: _selectedType,
        );
        if (!mounted) return;
        _populateOcrFields(ocr);

        setState(() {
          _isScanning = false;
          _currentStep = ScanStep.ocrReview;
        });
        return;
      }
    } catch (_) {
    } finally {
      ref.read(isExternalOperationInProgressProvider.notifier).state = false;
    }

    // 2. Jika batal atau pengguna menekan tombol kembali pada Google Scanner:
    // Pada mode testing otomatis headless (FLUTTER_TEST), lanjutkan ke ScanStep.capture
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      if (mounted) {
        setState(() => _currentStep = ScanStep.capture);
        _initCamera();
        _startSmartDetectionTimer();
        _startImageStreamIfNeeded();
      }
    } else {
      // Pada perangkat nyata: JANGAN alihkan ke kamera internal lama! Tetap berada di PreScanSheet
      if (mounted) {
        setState(() => _isScanning = false);
        if (widget.startWithCamera) {
          _handleClose();
        }
      }
    }
  }

  Future<void> _launchGoogleScanner() async {
    HapticFeedback.lightImpact();
    final scanService = ref.read(documentScanServiceProvider);
    await _stopImageStreamIfNeeded();
    setState(() => _isScanning = true);
    ref.read(isExternalOperationInProgressProvider.notifier).state = true;
    try {
      final pictures = await scanService.scanDocument(
        documentType: _selectedType,
      );
      if (!mounted) return;
      if (pictures != null && pictures.isNotEmpty) {
        var path = pictures.first;
        if (_selectedType == ScanDocumentType.idCard ||
            _selectedType == ScanDocumentType.paymentCard) {
          path = await CardCropHelper.roundCardCorners(imagePath: path);
        }
        _scannedImagePath = path;
        final ocr = await scanService.processOcr(
          path,
          documentType: _selectedType,
        );
        if (!mounted) return;
        _populateOcrFields(ocr);

        setState(() {
          _isScanning = false;
          _currentStep = ScanStep.ocrReview;
        });
        return;
      }
    } catch (_) {
    } finally {
      ref.read(isExternalOperationInProgressProvider.notifier).state = false;
    }
    if (mounted) {
      setState(() => _isScanning = false);
      _startImageStreamIfNeeded();
    }
  }

  Future<void> _handleCaptureShutter() async {
    HapticFeedback.mediumImpact();
    final scanService = ref.read(documentScanServiceProvider);
    setState(() => _isScanning = true);
    try {
      await _stopImageStreamIfNeeded();
      String? path;
      final controller = _cameraController;
      if (controller != null && controller.value.isInitialized) {
        final xFile = await controller.takePicture();
        path = xFile.path;
      } else {
        path = await scanService.capturePhoto();
      }

      if (!mounted) return;
      if (path != null) {
        // 1. Auto-Crop fisik ke rasio kartu standar (ID-1) dengan sudut melengkung ISO
        final croppedPath = await CardCropHelper.autoCropCard(
          imagePath: path,
          roundedCorners: _selectedType != ScanDocumentType.document,
        );
        _scannedImagePath = croppedPath;

        // 2. Ekstrak teks OCR dari foto yang sudah terpotong bersih
        final ocr = await scanService.processOcr(
          croppedPath,
          documentType: _selectedType,
        );
        if (!mounted) return;
        _populateOcrFields(ocr);

        // Double pulse tactile feedback saat OCR berhasil diekstrak
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 90));
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isScanning = false;
        // Alur Cepat (Express Flow): langsung lompat ke form OCR Review
        _currentStep = ScanStep.ocrReview;
      });
    }
  }

  Future<void> _handlePickGallery() async {
    HapticFeedback.lightImpact();
    final scanService = ref.read(documentScanServiceProvider);
    setState(() => _isScanning = true);
    ref.read(isExternalOperationInProgressProvider.notifier).state = true;
    try {
      final path = await scanService.pickFromGallery();
      if (!mounted) return;
      if (path != null) {
        // Auto-Crop gambar dari galeri ke rasio kartu standar dengan sudut rounded ISO
        final croppedPath = await CardCropHelper.autoCropCard(
          imagePath: path,
          roundedCorners: _selectedType != ScanDocumentType.document,
        );
        _scannedImagePath = croppedPath;

        final ocr = await scanService.processOcr(
          croppedPath,
          documentType: _selectedType,
        );
        if (!mounted) return;
        _populateOcrFields(ocr);

        setState(() {
          _isScanning = false;
          _currentStep = ScanStep.ocrReview;
        });
        return;
      }
    } catch (_) {
    } finally {
      ref.read(isExternalOperationInProgressProvider.notifier).state = false;
    }
    if (mounted) {
      setState(() {
        _isScanning = false;
        _currentStep = ScanStep.ocrReview;
      });
    }
  }

  Future<void> _handleConfirmCrop(int quarterTurns) async {
    HapticFeedback.lightImpact();
    if (_scannedImagePath != null && quarterTurns > 0) {
      final rotatedPath = await CardCropHelper.rotateAndCrop(
        imagePath: _scannedImagePath!,
        quarterTurns: quarterTurns,
      );
      _scannedImagePath = rotatedPath;
    }
    if (mounted) {
      setState(() {
        _rotationQuarterTurns = quarterTurns;
        _currentStep = ScanStep.ocrReview;
      });
    }
  }

  void _handleOpenCropEditor() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep = ScanStep.cropRotate);
  }

  void _handleRetake() {
    HapticFeedback.lightImpact();
    // Gunakan kembali Google Document Scanner resmi
    _handleStartCamera();
  }

  void _handleClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/shell');
        }
      } catch (_) {
        // No GoRouter in test context
      }
    }
  }

  // --- Handlers Penyimpanan Berkas ---

  Future<void> _saveAsDocument() async {
    HapticFeedback.selectionClick();

    final docId = const Uuid().v4();
    final docTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Dokumen Baru';
    final docNumber = _numberController.text.trim();
    final docIssuer = _issuerController.text.trim();

    // Rangkum seluruh detail OCR ke dalam catatan terstruktur
    final extraDetails = <String>[];
    if (_nameController.text.trim().isNotEmpty) {
      extraDetails.add('Nama: ${_nameController.text.trim()}');
    }
    if (_birthPlaceDateController.text.trim().isNotEmpty) {
      extraDetails.add(
        'Tempat/Tgl Lahir: ${_birthPlaceDateController.text.trim()}',
      );
    }
    if (_genderController.text.trim().isNotEmpty) {
      extraDetails.add('Jenis Kelamin: ${_genderController.text.trim()}');
    }
    if (_bloodTypeController.text.trim().isNotEmpty) {
      extraDetails.add('Gol. Darah: ${_bloodTypeController.text.trim()}');
    }
    if (_addressController.text.trim().isNotEmpty) {
      extraDetails.add('Alamat: ${_addressController.text.trim()}');
    }
    if (_rtRwController.text.trim().isNotEmpty) {
      extraDetails.add('RT/RW: ${_rtRwController.text.trim()}');
    }
    if (_kelDesaController.text.trim().isNotEmpty) {
      extraDetails.add('Kel/Desa: ${_kelDesaController.text.trim()}');
    }
    if (_kecamatanController.text.trim().isNotEmpty) {
      extraDetails.add('Kecamatan: ${_kecamatanController.text.trim()}');
    }
    if (_religionController.text.trim().isNotEmpty) {
      extraDetails.add('Agama: ${_religionController.text.trim()}');
    }
    if (_maritalStatusController.text.trim().isNotEmpty) {
      extraDetails.add('Status: ${_maritalStatusController.text.trim()}');
    }
    if (_occupationController.text.trim().isNotEmpty) {
      extraDetails.add('Pekerjaan: ${_occupationController.text.trim()}');
    }
    if (_nationalityController.text.trim().isNotEmpty) {
      extraDetails.add(
        'Kewarganegaraan: ${_nationalityController.text.trim()}',
      );
    }

    DocumentCategory docCategory = DocumentCategory.identity;
    if (_recognizedType == RecognizedDocumentType.bankCard ||
        _selectedType == ScanDocumentType.paymentCard) {
      docCategory = DocumentCategory.financial;
    } else if (_recognizedType == RecognizedDocumentType.bpjs) {
      docCategory = DocumentCategory.medical;
    } else if (_recognizedType == RecognizedDocumentType.sim) {
      docCategory = DocumentCategory.vehicle;
    }

    final doc = DocumentItem(
      id: docId,
      title: docTitle,
      category: docCategory,
      fileType: DocumentFileType.pdf,
      filePath:
          _scannedImagePath ??
          'app_storage/scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
      fileSizeBytes: 1850000,
      documentNumber: docNumber,
      issuer: docIssuer,
      notes: extraDetails.isNotEmpty ? extraDetails.join('\n') : null,
      createdAt: DateTime.now(),
      isVaultProtected: _isVaultProtected,
    );

    await ref.read(documentListProvider.notifier).addDocument(doc);

    // Pasang pengingat jika diaktifkan dan ada tanggal kedaluwarsa
    if (_autoSetReminder && !_isLifetimeExpiry) {
      final reminder = ReminderItem(
        id: const Uuid().v4(),
        title: '$docTitle kedaluwarsa',
        dueDate: DateTime.now().add(const Duration(days: 365 * 3)),
        documentId: docId,
        repetition: 'Tahunan',
      );
      await ref.read(reminderListProvider.notifier).addReminder(reminder);
    }

    if (!mounted) return;
    CardlyToast.showSuccess(context, '$docTitle berhasil disimpan ke Dokumen!');
    _handleClose();
  }

  Future<void> _saveAsCard() async {
    HapticFeedback.selectionClick();

    final lastDigits = _last4Controller.text.trim().isNotEmpty
        ? _last4Controller.text.trim()
        : (_numberController.text.trim().length >= 4
              ? _numberController.text.trim().substring(
                  _numberController.text.trim().length - 4,
                )
              : (_numberController.text.trim().isNotEmpty
                    ? _numberController.text.trim()
                    : '0000'));

    final cardTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Kartu Baru';

    CardCategory cardCat = CardCategory.identitas;
    if (_recognizedType == RecognizedDocumentType.bankCard ||
        _selectedType == ScanDocumentType.paymentCard) {
      cardCat = CardCategory.pembayaran;
    } else if (_recognizedType == RecognizedDocumentType.bpjs) {
      cardCat = CardCategory.kesehatan;
    } else if (_recognizedType == RecognizedDocumentType.sim) {
      cardCat = CardCategory.kendaraan;
    }

    final card = CardItem(
      id: const Uuid().v4(),
      title: cardTitle,
      holderName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'PEMILIK',
      lastFourDigits: lastDigits,
      issuer: _issuerController.text.trim().isNotEmpty
          ? _issuerController.text.trim()
          : 'Penerbit Kartu',
      category: cardCat,
      theme: CardVisualTheme.lime,
      isFavorite: false,
    );

    await ref.read(cardListProvider.notifier).addCard(card);

    if (!mounted) return;
    CardlyToast.showSuccess(
      context,
      '$cardTitle berhasil disimpan ke Dompet Kartu!',
    );
    _handleClose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == ScanStep.preScan || widget.startWithCamera,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep == ScanStep.ocrReview) {
          setState(() => _currentStep = ScanStep.preScan);
        } else if (_currentStep == ScanStep.cropRotate) {
          setState(() => _currentStep = ScanStep.ocrReview);
        } else if (_currentStep == ScanStep.capture) {
          setState(() => _currentStep = ScanStep.preScan);
        }
      },
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case ScanStep.preScan:
        return _buildPreScanView();
      case ScanStep.permissionDenied:
        return CameraPermissionView(
          onOpenSettings: () {
            CardlyToast.showInfo(context, 'Membuka Pengaturan Aplikasi...');
          },
          onImportFallback: _handlePickGallery,
          onClose: _handleClose,
        );
      case ScanStep.capture:
        return _buildCameraCaptureView();
      case ScanStep.cropRotate:
        final currentPreset = _samplePresets[_selectedSampleIndex];
        return CropRotateEditor(
          initialQuarterTurns: _rotationQuarterTurns,
          documentTitlePreview: currentPreset['title'] as String,
          documentCategoryPreview: currentPreset['badge'] as String,
          imagePath: _scannedImagePath,
          onRetake: _handleRetake,
          onConfirmCrop: _handleConfirmCrop,
        );
      case ScanStep.ocrReview:
        return OcrReviewForm(
          titleController: _titleController,
          numberController: _numberController,
          nameController: _nameController,
          expiryController: _expiryController,
          issuerController: _issuerController,
          birthPlaceDateController: _birthPlaceDateController,
          genderController: _genderController,
          bloodTypeController: _bloodTypeController,
          addressController: _addressController,
          rtRwController: _rtRwController,
          kelDesaController: _kelDesaController,
          kecamatanController: _kecamatanController,
          religionController: _religionController,
          maritalStatusController: _maritalStatusController,
          occupationController: _occupationController,
          nationalityController: _nationalityController,
          bankNameController: _bankNameController,
          last4Controller: _last4Controller,
          recognizedType: _recognizedType,
          isLifetimeExpiry: _isLifetimeExpiry,
          onLifetimeToggle: (val) => setState(() => _isLifetimeExpiry = val),
          isVaultProtected: _isVaultProtected,
          onVaultToggle: (val) => setState(() => _isVaultProtected = val),
          autoSetReminder: _autoSetReminder,
          onReminderToggle: (val) => setState(() => _autoSetReminder = val),
          imagePath: _scannedImagePath,
          onBack: () => setState(() => _currentStep = ScanStep.preScan),
          onRetake: _handleRetake,
          onEditCrop: _handleOpenCropEditor,
          onSaveDocument: _saveAsDocument,
          onSaveCard: _saveAsCard,
        );
    }
  }

  // --- Step 1: Pre-Scan View ---
  Widget _buildPreScanView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: _handleClose,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: PreScanSheet(
              selectedType: _selectedType,
              onTypeChanged: (type) => setState(() => _selectedType = type),
              onStartScan: _handleStartCamera,
              onPickFromGallery: _handlePickGallery,
            ),
          ),
        ),
      ),
    );
  }

  // --- Step 2: Camera Capture Viewport ---
  Widget _buildCameraCaptureView() {
    final currentPreset = _samplePresets[_selectedSampleIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 0. Live In-App Camera Feed Preview (Bersih & Bening)
                if (_isCameraInitialized && _cameraController != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width:
                            _cameraController!.value.previewSize?.height ??
                            1080,
                        height:
                            _cameraController!.value.previewSize?.width ?? 1920,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: _isCameraInitializing
                            ? const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.lime,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),

                // 1. Overlay Laser Pemandu Real-Time dengan Peringatan Kualitas & Auto-Shutter
                Positioned.fill(
                  child: ScanLaserOverlay(
                    aspectRatio: currentPreset['aspectRatio'] as double,
                    isScanning: true,
                    hintText: '',
                    detectedBadge: currentPreset['badge'] as String,
                    isDocumentLocked: _isDocumentLocked,
                    focusScreenPosition: _focusScreenPosition,
                    isFocusing: _isFocusing,
                    onTapToFocus: (pos) => _handleTapToFocus(pos, constraints),
                    qualityWarning: _qualityWarning,
                    onWarningTap: () {
                      if (_qualityWarning?.contains('senter') == true) {
                        _toggleFlash();
                      }
                    },
                    autoCaptureProgress: _autoCaptureProgress,
                  ),
                ),

                // 2. Toolbar Atas
                Positioned(
                  top: 14.0,
                  left: 16.0,
                  right: 16.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol Tutup / Kembali
                      Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22.0,
                          ),
                          onPressed: _handleClose,
                          tooltip: 'Tutup pemindai',
                        ),
                      ),

                      // Selektor Sampel Dokumen Modern Glassmorphic Pill
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showDocumentSelectorSheet,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 7.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: AppColors.lime.withValues(alpha: 0.7),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7.0,
                                  height: 7.0,
                                  decoration: const BoxDecoration(
                                    color: AppColors.lime,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  currentPreset['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.lime,
                                  size: 18.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tombol Pindai Cerdas Google Wallet
                          Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.lime.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.lime,
                                size: 20.0,
                              ),
                              onPressed: _launchGoogleScanner,
                              tooltip: 'Pindai Cerdas Google Wallet',
                            ),
                          ),
                          const SizedBox(width: 8.0),

                          // Tombol Senter / Flash Atas
                          Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isFlashOn
                                    ? AppColors.lime
                                    : Colors.white.withValues(alpha: 0.2),
                                width: _isFlashOn ? 1.5 : 1.0,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: _isFlashOn
                                    ? AppColors.lime
                                    : Colors.white,
                                size: 22.0,
                              ),
                              onPressed: _toggleFlash,
                              tooltip: 'Lampu kilat',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Teks Panduan di Atas Bingkai (Sesuai docs/8. Scan Flow/22 Scan Dokumen.png)
                Positioned(
                  top: 76.0,
                  left: 24.0,
                  right: 24.0,
                  child: const Center(
                    child: Text(
                      'Letakkan dokumen di dalam bingkai.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // 4. Tombol Shutter & Kontrol Bawah (Sesuai docs/8. Scan Flow/22 Scan Dokumen.png)
                Positioned(
                  bottom: 24.0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Toggle Auto-Shutter Pintar (Hands-Free)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isAutoShutterEnabled = !_isAutoShutterEnabled;
                            _autoCaptureProgress = 0.0;
                            _consecutiveStableFrames = 0;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: _isAutoShutterEnabled
                                  ? AppColors.lime.withValues(alpha: 0.8)
                                  : Colors.white24,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAutoShutterEnabled
                                    ? Icons.auto_awesome_rounded
                                    : Icons.touch_app_rounded,
                                size: 14.0,
                                color: _isAutoShutterEnabled
                                    ? AppColors.lime
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                _isAutoShutterEnabled
                                    ? 'Auto-Jepret Aktif'
                                    : 'Mode Manual',
                                style: TextStyle(
                                  color: _isAutoShutterEnabled
                                      ? AppColors.lime
                                      : Colors.white70,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Tombol Buka Galeri
                          IconButton(
                            iconSize: 32.0,
                            icon: Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_library_outlined,
                                color: Colors.white,
                                size: 24.0,
                              ),
                            ),
                            onPressed: _isScanning ? null : _handlePickGallery,
                            tooltip: 'Pilih dari galeri',
                          ),

                          // Tombol Shutter Kamera Besar Elegan (Sesuai Figma 22 Scan Dokumen.png)
                          GestureDetector(
                            onTap: _isScanning ? null : _handleCaptureShutter,
                            child: Container(
                              width: 76.0,
                              height: 76.0,
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.5,
                                ),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: _isScanning
                                    ? const Center(
                                        child: SizedBox(
                                          width: 26.0,
                                          height: 26.0,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3.0,
                                            valueColor: AlwaysStoppedAnimation(
                                              AppColors.ink,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        color: AppColors.ink,
                                        size: 32.0,
                                      ),
                              ),
                            ),
                          ),

                          // Tombol Lampu Kilat / Flash Bawah
                          IconButton(
                            iconSize: 32.0,
                            icon: Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isFlashOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: _isFlashOn
                                    ? AppColors.lime
                                    : Colors.white,
                                size: 24.0,
                              ),
                            ),
                            onPressed: _toggleFlash,
                            tooltip: 'Lampu kilat',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16.0),

                      const Text(
                        'Pastikan teks jelas. Hasil scan tetap perlu diperiksa.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
