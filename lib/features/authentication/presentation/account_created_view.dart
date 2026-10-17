import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';

/// Account Created Celebration / Email Verification View
/// Referensi: docs/4. Authentication/43 Akun dibuat.png & docs/4. Authentication/41 Periksa email.png
class AccountCreatedView extends ConsumerStatefulWidget {
  final bool needsVerification;
  final String? email;

  const AccountCreatedView({
    super.key,
    this.needsVerification = false,
    this.email,
  });

  @override
  ConsumerState<AccountCreatedView> createState() => _AccountCreatedViewState();
}

class _AccountCreatedViewState extends ConsumerState<AccountCreatedView> {
  int _secondsRemaining = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  Future<void> _handleResend() async {
    final email = widget.email?.trim() ?? '';
    if (email.isEmpty) return;

    _startTimer();
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final success = await supabase.resendSignUpConfirmation(email);
      if (!mounted) return;
      if (success) {
        CardlyToast.showSuccess(
          context,
          'Tautan verifikasi baru telah dikirim ke $email.',
        );
      } else {
        CardlyToast.showError(
          context,
          'Gagal mengirim ulang email. Coba beberapa saat lagi.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      CardlyToast.showError(context, 'Terjadi kendala: $e');
    }
  }

  String get _formattedTime {
    final s = _secondsRemaining.toString().padLeft(2, '0');
    return '00:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayEmail = widget.email ?? 'email Anda';

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: () => widget.needsVerification
              ? context.go('/login')
              : context.go('/shell'),
        ),
        title: Text(
          widget.needsVerification ? 'Verifikasi Email' : 'Selesai',
          style: AppTypography.pageHeading.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Ikon Lingkaran Lime Besar
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
                child: Icon(
                  widget.needsVerification
                      ? Icons.mark_email_read_rounded
                      : Icons.check_rounded,
                  size: 48.0,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(height: 32.0),

              // Heading & Subtitle
              Text(
                widget.needsVerification
                    ? 'Periksa kotak masuk email.'
                    : 'Akun berhasil dibuat.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.needsVerification
                      ? 'Tautan verifikasi telah dikirim ke $displayEmail. Silakan klik tautan pada email untuk mengaktifkan akun dan otomatis kembali ke aplikasi Cardly.'
                      : 'Selanjutnya, amankan ruang pribadi Anda dengan kunci aplikasi atau biometrik.',
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

              if (widget.needsVerification) ...[
                // Tombol Beralih ke Masuk
                CardlyPrimaryButton(
                  text: 'Sudah Verifikasi? Masuk',
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 12.0),
                if (_secondsRemaining > 0)
                  Container(
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
                        color:
                            isDark ? AppColors.mediumGray : AppColors.muted,
                      ),
                    ),
                  )
                else
                  CardlySecondaryButton(
                    text: 'Kirim ulang email',
                    onPressed: _handleResend,
                  ),
              ] else ...[
                // Tombol Atur Keamanan untuk akun yang langsung terverifikasi
                CardlyPrimaryButton(
                  text: 'Atur keamanan',
                  onPressed: () => context.push('/biometric-setup'),
                ),
              ],

              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
