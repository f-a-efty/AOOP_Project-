import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/eco_background_wrapper.dart';
import '../../core/widgets/modern_eco_nav_bar.dart';
import '../../main.dart';
import 'company_dashboard_tab.dart';
import 'smart_booths_tab.dart';
import 'pickup_requests_tab.dart';
import 'collection_history_tab.dart';
import 'company_alerts_tab.dart';

class CompanyHomeScreen extends ConsumerStatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  ConsumerState<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends ConsumerState<CompanyHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      CompanyDashboardTab(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const SmartBoothsTab(),
      const PickupRequestsTab(),
      const CollectionHistoryTab(),
      const CompanyAlertsTab(),
    ];

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
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7DD3FC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.recycling_rounded, size: 14, color: Color(0xFF0369A1)),
                SizedBox(width: 4),
                Text('Recycler Hub', style: TextStyle(color: Color(0xFF0369A1), fontSize: 11.5, fontWeight: FontWeight.bold)),
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
          children: tabs,
        ),
      ),
      bottomNavigationBar: ModernEcoNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          ModernNavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          ModernNavBarItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Booths & Map'),
          ModernNavBarItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded, label: 'Pickups'),
          ModernNavBarItem(icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: 'History'),
          ModernNavBarItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts'),
        ],
      ),
    );
  }
}
