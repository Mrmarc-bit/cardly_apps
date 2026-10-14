import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import 'widgets/cardly_brand_header.dart';
import 'widgets/cardly_card_input.dart';
import 'widgets/password_strength_bar.dart';

/// Reset Password View resmi Cardly (docs/4. Authentication/09 Atur ulang kata sandi.png & Gelap)
class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculateStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    if (pwd.length < 6) return 1;
    if (pwd.length < 10) return 2;
    if (pwd.length < 12) return 3;
    return 4;
  }

  void _handleSavePassword() {
    setState(() => _error = null);
    final pwd = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (pwd.length < 8) {
      setState(
        () =>
            _error = 'Kata sandi minimal 8 karakter (disarankan 12 karakter).',
      );
      return;
    }
    if (pwd != confirm) {
      setState(() => _error = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.go('/reset-password/success');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strength = _calculateStrength(_passwordController.text);

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
          'Atur ulang',
          style: AppTypography.pageHeading.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Logo Lockup
              const CardlyBrandLogo(iconSize: 32.0, fontSize: 24.0),

              const SizedBox(height: 24.0),

              // Heading & Subtitle
              Text(
                'Kata sandi baru.',
                style: AppTypography.display.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Pilih kata sandi yang unik untuk akun Cardly Anda.',
                style: AppTypography.body.copyWith(
                  fontSize: 14.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                ),
              ),

              const SizedBox(height: 28.0),

              // Inputs Card
              CardlyCardInput(
                controller: _passwordController,
                label: 'Kata sandi baru',
                hintText: '••••••••••••',
                isPassword: true,
                internalHelperText: 'Minimal 12 karakter. Hindari kata sandi yang digunakan ulang.',
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12.0),

              // 4 Bar Password Strength
              PasswordStrengthBar(strength: strength),

              const SizedBox(height: 16.0),

              CardlyCardInput(
                controller: _confirmPasswordController,
                label: 'Konfirmasi kata sandi',
                hintText: '••••••••••••',
                isPassword: true,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12.0),
                Text(
                  _error!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 32.0),

              // Tombol Simpan Kata Sandi
              CardlyPrimaryButton(
                text: 'Simpan kata sandi',
                isLoading: _isLoading,
                onPressed: _handleSavePassword,
              ),

              const SizedBox(height: 24.0),

              // Kembali ke Masuk
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Kembali ke Masuk',
                    style: AppTypography.bodySemiBold.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
