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
import 'widgets/password_strength_bar.dart';

/// Register View resmi Cardly berstandar Enterprise
class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  // Controller bersih tanpa dummy data untuk sistem real produksi
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _agreeTerms = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  // RFC 5322 regex email validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int _calculateStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    if (pwd.contains(RegExp(r'[A-Z]')) && pwd.contains(RegExp(r'[a-z]'))) {
      score++;
    }
    if (pwd.contains(RegExp(r'[0-9]')) &&
        pwd.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/`~]'))) {
      score++;
    }
    return score.clamp(0, 4);
  }

  Future<void> _handleRegister() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1. Validasi Nama Lengkap
    if (name.isEmpty) {
      setState(() => _nameError = 'Nama lengkap wajib diisi.');
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Nama lengkap minimal 2 karakter.');
      return;
    }

    // 2. Validasi Format Email
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

    // 3. Validasi Kata Sandi
    if (password.isEmpty) {
      setState(() => _passwordError = 'Kata sandi wajib diisi.');
      return;
    }
    if (password.length < 8) {
      setState(() => _passwordError = 'Kata sandi minimal 8 karakter.');
      return;
    }

    // 4. Validasi Syarat & Ketentuan
    if (!_agreeTerms) {
      setState(
        () => _generalError =
            'Anda wajib menyetujui Ketentuan Penggunaan dan Kebijakan Privasi.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      if (supabase.isInitialized) {
        final authRes = await supabase.signUpWithEmail(
          email: email,
          password: password,
          fullName: name,
        );

        if (!mounted) return;
        final user = authRes?.user;
        final actualName =
            (user?.userMetadata?['full_name'] as String?) ?? name;

        ref.read(userProfileProvider.notifier).login(actualName, email);
        context.push('/register/success');
        return;
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        final msg = e.message.toLowerCase();
        if (msg.contains('already registered') ||
            msg.contains('user already exists')) {
          _emailError = 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
        } else {
          _generalError = e.message;
        }
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = 'Gagal mendaftar: Periksa koneksi internet Anda.';
      });
      return;
    }

    // Fallback environment tanpa koneksi aktif
    if (!mounted) return;
    ref.read(userProfileProvider.notifier).login(name, email);
    context.push('/register/success');
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isGoogleLoading = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final result = await supabase.signInWithGoogleNativeAccount();
      if (!mounted) return;

      if (result.isSuccess && result.account != null) {
        final account = result.account!;
        final name = account.displayName ?? account.email.split('@').first;
        ref.read(userProfileProvider.notifier).login(name, account.email);
        context.push('/register/success');
        return;
      }

      if (result.isCancelled) {
        CardlyToast.showInfo(context, 'Pendaftaran dengan Google dibatalkan.');
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
              ? 'Tidak dapat menghubungkan Google Sign-In. Silakan daftar menggunakan Email & Kata Sandi.'
              : (result.errorMessage ?? 'Gagal mendaftar dengan Google.'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      CardlyToast.showError(context, 'Gagal mendaftar dengan Google: $e');
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordText = _passwordController.text;
    final strength = _calculateStrength(passwordText);

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
          'Buat Akun',
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

              // Headline & Subtitle
              Text(
                'Buat ruang pribadi Anda.',
                style: AppTypography.display.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Mulai dari hal penting. Tetap kendalikan informasi Anda.',
                style: AppTypography.body.copyWith(
                  fontSize: 14.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                ),
              ),

              const SizedBox(height: 24.0),

              // Field Nama Lengkap
              CardlyCardInput(
                controller: _nameController,
                label: 'Nama lengkap',
                hintText: 'Nama lengkap Anda',
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: 16.0),

              // Field Email
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

              // Field Kata Sandi Bersih (Tanpa Teks Internal agar Dimensi Tetap Rapi & Presisi)
              CardlyCardInput(
                controller: _passwordController,
                label: 'Kata sandi',
                hintText: '••••••••••••',
                isPassword: true,
                errorText: _passwordError,
                onChanged: (_) => setState(() {
                  if (_passwordError != null) _passwordError = null;
                }),
              ),

              const SizedBox(height: 12.0),

              // Indikator 4 Segmen Kekuatan Sandi
              PasswordStrengthBar(strength: strength),

              const SizedBox(height: 20.0),

              // Checkbox Persetujuan Ketentuan
              GestureDetector(
                onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22.0,
                      height: 22.0,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: isDark ? AppColors.white : AppColors.ink,
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
                            setState(() => _agreeTerms = v ?? true),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Saya menyetujui Ketentuan penggunaan dan telah membaca Informasi privasi.',
                        style: AppTypography.compactBody.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.muted,
                          fontSize: 13.0,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_generalError != null) ...[
                const SizedBox(height: 14.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: isDark
                                ? Colors.red.shade200
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28.0),

              // Tombol Buat Akun
              CardlyPrimaryButton(
                text: 'Buat Akun',
                isLoading: _isLoading,
                onPressed: _handleRegister,
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
                      'atau daftar dengan',
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

              // Tombol Google OAuth
              GoogleSignInButton(
                text: 'Daftar dengan Google',
                isLoading: _isGoogleLoading,
                onPressed: _handleGoogleSignUp,
              ),

              const SizedBox(height: 24.0),

              // Tautan Masuk jika sudah punya akun
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: RichText(
                    text: TextSpan(
                      text: 'Sudah memiliki akun? ',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                        fontSize: 14.0,
                      ),
                      children: [
                        TextSpan(
                          text: 'Masuk',
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

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
