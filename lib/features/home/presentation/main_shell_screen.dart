import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/cardly_bottom_nav_bar.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../cards/presentation/card_list_view.dart';
import '../../documents/presentation/document_list_view.dart';
import '../../profile_settings/presentation/profile_dashboard_view.dart';
import '../../vault/presentation/vault_gate_view.dart';
import 'home_dashboard_view.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;
  late final PageController _pageController;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressTime;

  List<Widget> get _views => [
    HomeDashboardView(onSwitchTab: _onTabSelected),
    const CardListView(),
    const DocumentListView(),
    const VaultGateView(),
    const ProfileDashboardView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _tabHistory.clear();
    _tabHistory.add(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index, {bool isBack = false}) {
    if (_currentIndex != index) {
      if (!isBack) {
        _tabHistory.remove(index);
        _tabHistory.add(index);
      }
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. Jika pengguna telah berpindah-pindah tab, tombol back kembali ke tab sebelumnya
        if (_tabHistory.length > 1) {
          _tabHistory.removeLast();
          final prevIndex = _tabHistory.last;
          _onTabSelected(prevIndex, isBack: true);
          return;
        } else if (_currentIndex != 0) {
          _tabHistory.clear();
          _tabHistory.add(0);
          _onTabSelected(0, isBack: true);
          return;
        }

        // 2. Berada di tab utama (Beranda): Konfirmasi keluar aplikasi
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          CardlyToast.showInfo(
            context,
            'Tekan sekali lagi untuk keluar dari Cardly',
          );
          return;
        }

        // 3. Saat keluar aplikasi, jika proteksi disetel ke "Segera", kunci sesi aplikasi
        final sec = ref.read(securitySettingsProvider);
        if (sec.autoLockOption == 'Segera') {
          ref.read(appLockedProvider.notifier).lock();
          ref.read(vaultLockedProvider.notifier).lock();
        }
        // Arahkan kembali ke splash screen agar saat aplikasi dibuka kembali, splash tampil pertama kali
        try {
          context.go('/splash');
        } catch (_) {}
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _views,
        ),
        bottomNavigationBar: CardlyBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}
