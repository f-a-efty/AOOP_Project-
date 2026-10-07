import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/eco_background_wrapper.dart';
import '../../core/widgets/modern_eco_nav_bar.dart';
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

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      UserDashboardTab(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const QrScannerTab(),
      const WalletCashoutTab(),
      const CouponsTab(),
      const ImpactLeaderboardTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        title: Image.asset('assets/logo/Greenify-01-01.png', height: 75, fit: BoxFit.contain),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.eco_rounded, size: 14, color: Color(0xFF166534)),
                SizedBox(width: 4),
                Text('Citizen', style: TextStyle(color: Color(0xFF166534), fontSize: 11.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.muted),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(userRoleProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: EcoBackgroundWrapper(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: ModernEcoNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          ref.read(userDashboardReloadTriggerProvider.notifier).state++;
        },
        items: const [
          ModernNavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          ModernNavBarItem(icon: Icons.qr_code_scanner_rounded, activeIcon: Icons.qr_code_scanner_rounded, label: 'Deposit'),
          ModernNavBarItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
          ModernNavBarItem(icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer_rounded, label: 'Coupons'),
          ModernNavBarItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard_rounded, label: 'Impact'),
        ],
      ),
    );
  }
}
