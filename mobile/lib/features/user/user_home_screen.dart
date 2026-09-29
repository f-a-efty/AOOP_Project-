import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import 'user_dashboard_tab.dart';
import 'qr_scanner_tab.dart';
import 'wallet_cashout_tab.dart';
import 'coupons_tab.dart';
import 'impact_leaderboard_tab.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    UserDashboardTab(),
    QrScannerTab(),
    WalletCashoutTab(),
    CouponsTab(),
    ImpactLeaderboardTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo/Greenify-01-01.png', height: 38, fit: BoxFit.contain),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(userRoleProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.muted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Deposit'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer_rounded), label: 'Coupons'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Impact'),
        ],
      ),
    );
  }
}
