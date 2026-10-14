import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import 'widgets/cardly_brand_header.dart';
import 'widgets/cardly_card_input.dart';

/// Forgot Password View resmi Cardly (docs/4. Authentication/08 Lupa kata sandi.png & Gelap)
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final TextEditingController _emailController = TextEditingController(
    text: 'maruf@example.com',
  );
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendLink() {
    setState(() => _error = null);
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Masukkan format email yang valid.');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.push('/forgot-password/sent?email=${Uri.encodeComponent(email)}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Pulihkan akun',
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
                'Lupa kata sandi?',
                style: AppTypography.display.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Masukkan email akun untuk meminta tautan pengaturan ulang.',
                style: AppTypography.body.copyWith(
                  fontSize: 14.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                ),
              ),

              const SizedBox(height: 28.0),

              // Input Card Email
              CardlyCardInput(
                controller: _emailController,
                label: 'Email',
                hintText: 'maruf@example.com',
                keyboardType: TextInputType.emailAddress,
                errorText: _error,
                onSubmitted: (_) => _handleSendLink(),
              ),

              const SizedBox(height: 32.0),

              // Tombol Kirim Tautan
              CardlyPrimaryButton(
                text: 'Kirim tautan',
                isLoading: _isLoading,
                onPressed: _handleSendLink,
              ),

              const SizedBox(height: 24.0),

              // Kembali ke Masuk
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
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
