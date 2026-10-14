import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/cardly_bottom_nav_bar.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../cards/presentation/card_list_view.dart';
import '../../documents/presentation/document_list_view.dart';
import '../../profile_settings/presentation/profile_dashboard_view.dart';
import '../../vault/presentation/vault_gate_view.dart';
import 'home_dashboard_view.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  late final PageController _pageController;
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
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
        if (_currentIndex != 0) {
          _onTabSelected(0);
          return;
        }
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
