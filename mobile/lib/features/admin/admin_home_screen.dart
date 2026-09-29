import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/eco_background_wrapper.dart';
import '../../core/widgets/modern_eco_nav_bar.dart';
import '../../main.dart';
import 'admin_dashboard_tab.dart';
import 'admin_users_tab.dart';
import 'admin_operations_tab.dart';
import 'admin_finance_tab.dart';
import 'admin_more_tab.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentIndex = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPendingCount();
  }

  Future<void> _checkPendingCount() async {
    try {
      final api = ref.read(apiServiceProvider);
      final pending = await api.getPendingCompanies();
      if (mounted) {
        setState(() {
          _pendingCount = pending.length;
        });
      }
    } catch (_) {}
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
    _checkPendingCount();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      AdminDashboardTab(onNavigateToTab: _onNavigate),
      const AdminUsersTab(),
      const AdminOperationsTab(),
      const AdminFinanceTab(),
      const AdminMoreTab(),
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
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8B4FE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFF7E22CE)),
                SizedBox(width: 4),
                Text('Admin Control', style: TextStyle(color: Color(0xFF7E22CE), fontSize: 11.5, fontWeight: FontWeight.bold)),
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
        onTap: _onNavigate,
        items: [
          const ModernNavBarItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
          const ModernNavBarItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_alt_rounded, label: 'Users'),
          ModernNavBarItem(
            icon: Icons.build_outlined,
            activeIcon: Icons.build_rounded,
            label: 'Operations',
            badgeCount: _pendingCount > 0 ? _pendingCount : null,
            badgeColor: AppTheme.warningAmber,
          ),
          const ModernNavBarItem(icon: Icons.attach_money_rounded, activeIcon: Icons.attach_money_rounded, label: 'Finance'),
          const ModernNavBarItem(icon: Icons.more_horiz_rounded, activeIcon: Icons.more_horiz_rounded, label: 'More'),
        ],
      ),
    );
  }
}
