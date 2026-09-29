import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class UserDashboardTab extends ConsumerStatefulWidget {
  const UserDashboardTab({super.key});

  @override
  ConsumerState<UserDashboardTab> createState() => _UserDashboardTabState();
}

class _UserDashboardTabState extends ConsumerState<UserDashboardTab> {
  final _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider);

    if (token == null) {
      // If offline/demo mode, use user state if available
      setState(() {
        _dashboardData = {
          'fullName': user?['fullName'] ?? 'Citizen',
          'totalTokens': 0,
          'walletBalanceTaka': 0.0,
          'loyaltyLevel': 'Eco Buddy',
          'totalPlasticKg': 0.0,
          'co2PreventedKg': 0.0,
        };
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await _authService.fetchUserDashboard(token);
      if (mounted) {
        setState(() {
          _dashboardData = data;
        });
      }
    } catch (e) {
      // Fallback to cached user info
      if (mounted) {
        setState(() {
          _dashboardData ??= {
            'fullName': user?['fullName'] ?? 'Citizen',
            'totalTokens': 0,
            'walletBalanceTaka': 0.0,
            'loyaltyLevel': 'Eco Buddy',
            'totalPlasticKg': 0.0,
            'co2PreventedKg': 0.0,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for manual deposit updates or external refresh triggers
    ref.listen(userDashboardReloadTriggerProvider, (_, __) {
      _loadDashboard();
    });

    final currentUser = ref.watch(currentUserProvider);
    final name =
        _dashboardData?['fullName'] ?? currentUser?['fullName'] ?? 'Citizen';
    final loyalty = _dashboardData?['loyaltyLevel'] ?? 'Eco Buddy';
    final totalTokens = _dashboardData?['totalTokens'] ?? 0;
    final walletBalance = _dashboardData?['walletBalanceTaka'] != null
        ? (_dashboardData!['walletBalanceTaka'] as num).toDouble()
        : (totalTokens / 4.0);
    final plasticKg = _dashboardData?['totalPlasticKg'] != null
        ? (_dashboardData!['totalPlasticKg'] as num).toDouble()
        : 0.0;
    final co2Kg = _dashboardData?['co2PreventedKg'] != null
        ? (_dashboardData!['co2PreventedKg'] as num).toDouble()
        : (plasticKg * 1.5);

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back,',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🌿 $loyalty Tier',
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.eco_rounded,
                      size: 64, color: Colors.white24),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading && _dashboardData == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Balance Grid (Real Data from MySQL Database)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Tokens',
                      '$totalTokens Tokens',
                      '100 Tokens = 1 kg',
                      Icons.stars_rounded,
                      AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Wallet Balance',
                      '৳${walletBalance.toStringAsFixed(2)} BDT',
                      '4 Tokens = ৳1.00',
                      Icons.account_balance_wallet_rounded,
                      AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Plastic Recycled',
                      '${plasticKg.toStringAsFixed(3)} kg',
                      'Disposed safely',
                      Icons.recycling_rounded,
                      AppTheme.skyBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'CO2 Prevented',
                      '${co2Kg.toStringAsFixed(2)} kg',
                      '1.5 kg CO2 / plastic kg',
                      Icons.cloud_done_rounded,
                      AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Deposit Instruction Banner
              const Text('Recycling Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.subtle,
                    child: Icon(Icons.add_circle_outline_rounded,
                        color: AppTheme.primary),
                  ),
                  title: const Text('Deposit Plastic Now',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Go to "Deposit" tab to manually enter weight or scan QR'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppTheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtext,
      IconData icon, Color iconColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Icon(icon, color: iconColor, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text(subtext,
                style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
