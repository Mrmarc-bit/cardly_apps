import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cardly_buttons.dart';

/// Check Email View resmi Cardly (docs/4. Authentication/41 Periksa email.png & Gelap)
class CheckEmailView extends StatefulWidget {
  final String? email;

  const CheckEmailView({super.key, this.email});

  @override
  State<CheckEmailView> createState() => _CheckEmailViewState();
}

class _CheckEmailViewState extends State<CheckEmailView> {
  int _secondsRemaining = 45;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 45);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final s = _secondsRemaining.toString().padLeft(2, '0');
    return '00:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayEmail = widget.email ?? 'maruf@example.com';

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Periksa email',
          style: AppTypography.pageHeading.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Ikon Lingkaran Lime Besar dengan Centang Hitam
              Container(
                width: 88.0,
                height: 88.0,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16.0,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48.0,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(height: 32.0),

              // Headline & Keterangan
              Text(
                'Tautan sudah diminta.',
                style: AppTypography.display.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Jika $displayEmail terdaftar, petunjuk akan dikirim. Periksa kotak masuk dan spam.',
                  style: AppTypography.body.copyWith(
                    fontSize: 14.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.muted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),

              // Tombol Kembali ke Masuk
              CardlyPrimaryButton(
                text: 'Kembali ke Masuk',
                onPressed: () => context.go('/login'),
              ),

              const SizedBox(height: 12.0),

              // Tombol Hitung Mundur / Kirim Ulang Interaktif
              _secondsRemaining > 0
                  ? Container(
                      height: 52.0,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.elevatedDark
                            : AppColors.softGray,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        'Kirim ulang dalam $_formattedTime',
                        style: AppTypography.bodySemiBold.copyWith(
                          fontSize: 14.0,
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.muted,
                        ),
                      ),
                    )
                  : CardlySecondaryButton(
                      text: 'Kirim ulang email',
                      onPressed: _startTimer,
                    ),

              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }
}
