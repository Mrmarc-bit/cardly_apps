import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';

/// Account Created Celebration View (docs/4. Authentication/43 Akun dibuat.png & Gelap)
class AccountCreatedView extends StatelessWidget {
  const AccountCreatedView({super.key});

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
          onPressed: () => context.go('/shell'),
        ),
        title: Text(
          'Selesai',
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

              // Heading & Subtitle
              Text(
                'Akun berhasil dibuat.',
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
                  'Selanjutnya, amankan ruang pribadi Anda dengan kunci aplikasi atau biometrik.',
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

              // Tombol Atur Keamanan
              CardlyPrimaryButton(
                text: 'Atur keamanan',
                onPressed: () => context.push('/biometric-setup'),
              ),

              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
