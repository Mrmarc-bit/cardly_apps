import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cardly_buttons.dart';
import 'widgets/auth_security_card.dart';

/// Biometric Unavailable View (docs/4. Authentication/62 Biometrik tidak tersedia.png & Gelap)
class BiometricUnavailableView extends ConsumerWidget {
  const BiometricUnavailableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Kunci biometrik',
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

              // Ikon Perisai Tanda Seru Kotak Rounded Lime (#C8F45A)
              Container(
                width: 88.0,
                height: 88.0,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: AppRadius.cardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16.0,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 46.0,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(height: 28.0),

              // Heading & Subtitle
              Text(
                'Biometrik tidak tersedia.',
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
                  'Perangkat ini tidak mendukung biometrik atau belum menyiapkannya. Gunakan PIN aplikasi atau lewati.',
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

              // Kartu Keamanan
              const AuthSecurityCard(
                title: 'Opsional, sesuai perangkat',
                description: 'Cardly meminta hasil autentikasi sistem, bukan menampilkan data biometrik Anda.',
                icon: Icons.shield_outlined,
              ),

              const SizedBox(height: 20.0),

              // Tombol Atur PIN aplikasi & Lewati
              CardlyPrimaryButton(
                text: 'Atur PIN aplikasi',
                onPressed: () => context.push('/pin-setup'),
              ),
              const SizedBox(height: 12.0),
              CardlySecondaryButton(
                text: 'Lewati untuk sekarang',
                onPressed: () => context.go('/shell'),
              ),

              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }
}
