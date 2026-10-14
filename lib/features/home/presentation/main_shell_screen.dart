import 'package:flutter/material.dart';

import '../../../core/widgets/cardly_bottom_nav_bar.dart';
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
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _views),
      bottomNavigationBar: CardlyBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
