import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../features/vault/presentation/app_lock_gate.dart';
import 'app_router.dart';
import 'providers.dart';

class CardlyApp extends ConsumerStatefulWidget {
  const CardlyApp({super.key});

  @override
  ConsumerState<CardlyApp> createState() => _CardlyAppState();
}

class _CardlyAppState extends ConsumerState<CardlyApp> {
  StreamSubscription<AuthState>? _authSubscription;
  late final AppLifecycleListener _lifecycleListener;
  DateTime? _lastBackgroundTimestamp;

  @override
  void initState() {
    super.initState();
    _setupSupabaseAuthListener();
    _setupLifecycleListener();
  }

  void _setupLifecycleListener() {
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        _lastBackgroundTimestamp = DateTime.now();
      },
      onResume: () {
        // Jika kembali dari aktivitas kamera sistem / Google Scanner / Image Picker,
        // jangan kunci sesi agar data hasil scan tidak hilang.
        final isExternal = ref.read(isExternalOperationInProgressProvider);
        if (isExternal) {
          ref.read(isExternalOperationInProgressProvider.notifier).state =
              false;
          _lastBackgroundTimestamp = null;
          return;
        }

        final last = _lastBackgroundTimestamp;
        if (last == null) return;
        final elapsedSeconds = DateTime.now().difference(last).inSeconds;
        _lastBackgroundTimestamp = null;

        final secSettings = ref.read(securitySettingsProvider);
        int threshold = 0;
        switch (secSettings.autoLockOption) {
          case 'Segera':
            threshold = 0;
            break;
          case '30 Detik':
            threshold = 30;
            break;
          case '1 Menit':
            threshold = 60;
            break;
          case '5 Menit':
            threshold = 300;
            break;
          default:
            return;
        }

        if (elapsedSeconds >= threshold) {
          ref.read(vaultLockedProvider.notifier).lock();
          ref.read(appLockedProvider.notifier).lock();
        }
      },
    );
  }

  void _setupSupabaseAuthListener() {
    final supabase = SupabaseService.instance;
    final stream = supabase.authStateChanges;
    if (stream != null) {
      _authSubscription = stream.listen((data) {
        final event = data.event;
        final session = data.session;
        if (event == AuthChangeEvent.signedIn && session != null) {
          final user = session.user;
          final email = user.email ?? '';
          final fullName =
              (user.userMetadata?['full_name'] as String?) ??
              (user.userMetadata?['name'] as String?) ??
              (email.isNotEmpty ? email.split('@').first : 'Pengguna Cardly');

          ref.read(userProfileProvider.notifier).login(fullName, email);
          ref.read(appLockedProvider.notifier).unlock();

          // Jika user masuk melalui alur OAuth (Google dll), arahkan ke beranda
          try {
            appRouter.go('/shell');
          } catch (_) {}
        } else if (event == AuthChangeEvent.signedOut) {
          ref.read(userProfileProvider.notifier).logout();
          ref.read(appLockedProvider.notifier).unlock();
        }
      });
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Cardly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return AppLockGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
