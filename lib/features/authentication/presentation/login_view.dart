import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../../app/providers.dart';
import 'widgets/cardly_brand_header.dart';
import 'widgets/cardly_card_input.dart';
import 'widgets/google_sign_in_button.dart';

/// Login View resmi Cardly berstandar Enterprise
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  // Field kosong tanpa dummy data untuk sistem real produksi
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;

  // RFC 5322 regex email validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1. Validasi Ketat Field Email
    if (email.isEmpty) {
      setState(() => _emailError = 'Email wajib diisi.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(
        () =>
            _emailError = 'Format email tidak valid (contoh: nama@domain.com).',
      );
      return;
    }

    // 2. Validasi Ketat Field Kata Sandi
    if (password.isEmpty) {
      setState(() => _passwordError = 'Kata sandi wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      if (supabase.isInitialized) {
        final authRes = await supabase.signInWithEmail(
          email: email,
          password: password,
        );

        if (!mounted) return;
        final user = authRes?.user;
        final fullName =
            (user?.userMetadata?['full_name'] as String?) ??
            email.split('@').first;

        ref.read(userProfileProvider.notifier).login(fullName, email);
        context.go('/shell');
        return;
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        final msg = e.message.toLowerCase();
        if (msg.contains('invalid') || msg.contains('credentials')) {
          _passwordError = 'Email atau kata sandi tidak cocok. Silakan periksa kembali atau buat akun baru.';
        } else if (msg.contains('not confirmed')) {
          _emailError = 'Email belum diverifikasi. Silakan periksa kotak masuk email Anda.';
        } else {
          _passwordError = e.message;
        }
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _passwordError = 'Koneksi ke server gagal. Pastikan perangkat terhubung ke internet.';
      });
      return;
    }

    // Fallback environment tanpa jaringan aktif
    if (!mounted) return;
    ref.read(userProfileProvider.notifier).login(email.split('@').first, email);
    context.go('/shell');
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final result = await supabase.signInWithGoogleNativeAccount();
      if (!mounted) return;

      if (result.isSuccess && result.account != null) {
        final account = result.account!;
        final name = account.displayName ?? account.email.split('@').first;
        ref.read(userProfileProvider.notifier).login(name, account.email);
        context.go('/shell');
        return;
      }

      if (result.isCancelled) {
        CardlyToast.showInfo(context, 'Masuk dengan Google dibatalkan.');
        return;
      }

      // Hybrid Resilient Fallback: Jika native SDK mengalami kendala,
      // beralih secara mulus ke Supabase OAuth In-App Browser Sheet
      CardlyToast.showInfo(context, 'Menghubungkan akun Google...');
      final webSuccess = await supabase.signInWithGoogle();
      if (!webSuccess && mounted) {
        CardlyToast.showError(
          context,
          result.isDevSha1Missing
              ? 'Tidak dapat menghubungkan akun Google. Silakan masuk menggunakan Email & Kata Sandi.'
              : (result.errorMessage ?? 'Gagal masuk dengan Google.'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      CardlyToast.showError(context, 'Gagal masuk dengan Google: $e');
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        title: Text(
          'Masuk',
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
              // Logo Brand Lockup
              const CardlyBrandLogo(iconSize: 32.0, fontSize: 24.0),

              const SizedBox(height: 24.0),

              // Heading & Subheading
              Text(
                'Selamat datang kembali.',
                style: AppTypography.display.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Masuk untuk melanjutkan mengatur kartu dan dokumen.',
                style: AppTypography.body.copyWith(
                  fontSize: 14.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                ),
              ),

              const SizedBox(height: 28.0),

              // Inputs Card bergaya Enclosed Card Input
              CardlyCardInput(
                controller: _emailController,
                label: 'Email',
                hintText: 'nama@email.com',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: 16.0),
              CardlyCardInput(
                controller: _passwordController,
                label: 'Kata sandi',
                hintText: '••••••••••••',
                isPassword: true,
                errorText: _passwordError,
                onSubmitted: (_) => _handleLogin(),
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),

              const SizedBox(height: 16.0),

              // Ingat Saya & Lupa Kata Sandi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: isDark
                                ? AppColors.white
                                : AppColors.ink,
                            checkColor: AppColors.lime,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.elevatedDark
                                  : AppColors.softGray,
                              width: 1.5,
                            ),
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? true),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Ingat saya',
                          style: AppTypography.compactBody.copyWith(
                            color: isDark ? AppColors.white : AppColors.ink,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/forgot-password'),
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Lupa kata sandi?',
                      style: AppTypography.compactBodyMedium.copyWith(
                        color: isDark ? AppColors.white : AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28.0),

              // Tombol Masuk Utama
              CardlyPrimaryButton(
                text: 'Masuk',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),

              const SizedBox(height: 20.0),

              // Garis Pembatas "atau"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.darkBorder : AppColors.softGray,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'atau lanjutkan dengan',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.darkBorder : AppColors.softGray,
                      height: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20.0),

              // Tombol Google OAuth Sign-In Resmi
              GoogleSignInButton(
                isLoading: _isGoogleLoading,
                onPressed: _handleGoogleSignIn,
              ),

              const SizedBox(height: 24.0),

              // Tautan Buat Akun
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/register'),
                  behavior: HitTestBehavior.opaque,
                  child: RichText(
                    text: TextSpan(
                      text: 'Belum punya akun? ',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                        fontSize: 14.0,
                      ),
                      children: [
                        TextSpan(
                          text: 'Buat Akun',
                          style: AppTypography.bodySemiBold.copyWith(
                            color: isDark ? AppColors.white : AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
