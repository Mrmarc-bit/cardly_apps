import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_bottom_sheet.dart';
import '../../../core/widgets/cardly_toast.dart';
import 'widgets/cardly_pin_pad.dart';

enum PinScreenMode { create, verify, change }

/// Layar & Bottom Sheet resmi Cardly untuk Pembuatan, Verifikasi, dan Perubahan PIN 6-Digit.
class PinScreen extends ConsumerStatefulWidget {
  final PinScreenMode mode;
  final String? customTitle;
  final String? customSubtitle;
  final bool isModal;

  const PinScreen({
    super.key,
    this.mode = PinScreenMode.verify,
    this.customTitle,
    this.customSubtitle,
    this.isModal = false,
  });

  /// Helper untuk menampilkan PIN Pad dalam bentuk Modal Bottom Sheet
  static Future<bool?> showAsBottomSheet(
    BuildContext context, {
    PinScreenMode mode = PinScreenMode.verify,
    String? title,
    String? subtitle,
  }) {
    return CardlyBottomSheet.show<bool>(
      context: context,
      child: PinScreen(
        mode: mode,
        customTitle: title,
        customSubtitle: subtitle,
        isModal: true,
      ),
    );
  }

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _currentPin = '';
  String _firstEnteredPin = '';
  int _step = 0; // Untuk alur multi-langkah create atau change
  bool _hasError = false;
  String _errorMessage = '';
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _checkInitialPinStatus();
  }

  Future<void> _checkInitialPinStatus() async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final hasPin = await secureStorage.hasAppPin();
      if (!hasPin && widget.mode == PinScreenMode.verify) {
        // Jika belum ada PIN sama sekali tetapi diminta verify, alihkan ke mode create
        if (mounted) {
          setState(() {
            _step = 0;
          });
        }
      }
    } catch (_) {
      // Abaikan jika plugin secure storage belum diinisialisasi
    }
  }

  String _getTitle() {
    if (widget.customTitle != null && _step == 0) return widget.customTitle!;
    switch (widget.mode) {
      case PinScreenMode.create:
        return _step == 0 ? 'Buat PIN 6-Digit' : 'Konfirmasi PIN Anda';
      case PinScreenMode.verify:
        return 'Masukkan PIN Brankas';
      case PinScreenMode.change:
        if (_step == 0) return 'Masukkan PIN Lama';
        if (_step == 1) return 'Buat PIN Baru';
        return 'Konfirmasi PIN Baru';
    }
  }

  String _getSubtitle() {
    if (_hasError && _errorMessage.isNotEmpty) return _errorMessage;
    if (widget.customSubtitle != null && _step == 0) {
      return widget.customSubtitle!;
    }
    switch (widget.mode) {
      case PinScreenMode.create:
        return _step == 0
            ? 'Atur 6 digit angka untuk mengamankan brankas dokumen Anda.'
            : 'Masukkan kembali 6 digit PIN untuk memastikan kecocokan.';
      case PinScreenMode.verify:
        return 'Masukkan 6 digit kode keamanan untuk membuka ruang pribadi.';
      case PinScreenMode.change:
        if (_step == 0) {
          return 'Masukkan PIN 6-digit saat ini untuk verifikasi.';
        }
        if (_step == 1) {
          return 'Masukkan 6 digit angka PIN baru Anda.';
        }
        return 'Masukkan kembali PIN baru untuk memastikan kecocokan.';
    }
  }

  void _onPinChanged(String newPin) {
    setState(() {
      _currentPin = newPin;
      _hasError = false;
      _errorMessage = '';
    });
  }

  Future<void> _handlePinCompleted() async {
    final secureStorage = ref.read(secureStorageServiceProvider);

    if (widget.mode == PinScreenMode.create) {
      if (_step == 0) {
        // Simpan input pertama dan minta konfirmasi
        setState(() {
          _firstEnteredPin = _currentPin;
          _currentPin = '';
          _step = 1;
        });
      } else {
        // Periksa apakah konfirmasi cocok
        if (_currentPin == _firstEnteredPin) {
          await secureStorage.saveAppPin(_currentPin);
          if (!mounted) return;
          CardlyToast.showSuccess(context, 'PIN keamanan berhasil dibuat!');
          _complete(true);
        } else {
          _triggerError('PIN konfirmasi tidak cocok. Silakan coba lagi.');
          setState(() {
            _step = 0;
            _firstEnteredPin = '';
          });
        }
      }
    } else if (widget.mode == PinScreenMode.verify) {
      // Verifikasi PIN yang tersimpan
      final isValid = await secureStorage.verifyAppPin(_currentPin);
      if (isValid) {
        _complete(true);
      } else {
        _failedAttempts++;
        _triggerError(
          _failedAttempts >= 3
              ? 'PIN salah $_failedAttempts kali. Harap periksa kembali.'
              : 'PIN salah. Silakan coba lagi.',
        );
      }
    } else if (widget.mode == PinScreenMode.change) {
      if (_step == 0) {
        // Cek PIN lama
        final isOldValid = await secureStorage.verifyAppPin(_currentPin);
        if (isOldValid) {
          setState(() {
            _currentPin = '';
            _step = 1;
          });
        } else {
          _triggerError('PIN lama salah. Coba lagi.');
        }
      } else if (_step == 1) {
        // Simpan input PIN baru
        setState(() {
          _firstEnteredPin = _currentPin;
          _currentPin = '';
          _step = 2;
        });
      } else {
        // Konfirmasi PIN baru
        if (_currentPin == _firstEnteredPin) {
          await secureStorage.saveAppPin(_currentPin);
          if (!mounted) return;
          CardlyToast.showSuccess(context, 'PIN Brankas berhasil diperbarui!');
          _complete(true);
        } else {
          _triggerError('Konfirmasi PIN baru tidak cocok.');
          setState(() {
            _step = 1;
            _firstEnteredPin = '';
          });
        }
      }
    }
  }

  void _triggerError(String msg) {
    setState(() {
      _hasError = true;
      _errorMessage = msg;
      _currentPin = '';
    });
  }

  void _complete(bool success) {
    if (widget.isModal) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop(success);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(success);
      }
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(success);
      } else {
        try {
          if (context.canPop()) {
            context.pop(success);
          } else {
            context.go('/shell');
          }
        } catch (_) {
          // No GoRouter in test context
        }
      }
    }
  }

  void _handleBiometricAuth() async {
    final biometricService = ref.read(biometricServiceProvider);
    final authRes = await biometricService.authenticateDetailed(
      localizedReason:
          'Pindai sidik jari atau Face ID Anda untuk membuka Cardly.',
    );
    if (!mounted) return;
    if (authRes.success) {
      HapticFeedback.mediumImpact();
      _complete(true);
    } else {
      HapticFeedback.vibrate();
      CardlyToast.showError(
        context,
        authRes.errorMessage ?? 'Verifikasi biometrik tidak cocok.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.watch(userProfileProvider);
    final canUseBiometric =
        widget.mode == PinScreenMode.verify && userProfile.isBiometricActive;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: widget.isModal ? 4.0 : 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon Gembok / Perisai Keamanan dengan Aksen Lime
          Container(
            width: widget.isModal ? 48.0 : 56.0,
            height: widget.isModal ? 48.0 : 56.0,
            decoration: BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.lime.withValues(alpha: 0.4),
                  blurRadius: 14.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Icon(
              Icons.lock_rounded,
              size: widget.isModal ? 24.0 : 28.0,
              color: AppColors.ink,
            ),
          ),

          SizedBox(height: widget.isModal ? 12.0 : 20.0),

          // Judul Utama
          Text(
            _getTitle(),
            style: AppTypography.pageHeading.copyWith(
              fontSize: widget.isModal ? 20.0 : 22.0,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.ink,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6.0),

          // Subtitle / Feedback Error
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _getSubtitle(),
              key: ValueKey(_getSubtitle()),
              style: AppTypography.body.copyWith(
                fontSize: 13.0,
                color: _hasError
                    ? AppColors.error
                    : (isDark ? AppColors.textSecondaryDark : AppColors.muted),
                fontWeight: _hasError ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: widget.isModal ? 18.0 : 28.0),

          // Komponen PIN Pad Interaktif
          CardlyPinPad(
            currentPin: _currentPin,
            hasError: _hasError,
            isBiometricAvailable: canUseBiometric,
            onPinChanged: _onPinChanged,
            onBiometricPressed: _handleBiometricAuth,
            onCompleted: _handlePinCompleted,
          ),

          SizedBox(height: widget.isModal ? 8.0 : 16.0),
        ],
      ),
    );

    if (widget.isModal) {
      return SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: () => _complete(false),
        ),
        title: Text(
          widget.mode == PinScreenMode.create
              ? 'Atur PIN'
              : (widget.mode == PinScreenMode.change
                    ? 'Ubah PIN'
                    : 'Verifikasi'),
          style: AppTypography.pageHeading.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: content,
          ),
        ),
      ),
    );
  }
}
