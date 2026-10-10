import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class UserDashboardTab extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigateToTab;

  const UserDashboardTab({super.key, this.onNavigateToTab});

  @override
  ConsumerState<UserDashboardTab> createState() => _UserDashboardTabState();
}

class _UserDashboardTabState extends ConsumerState<UserDashboardTab> {
  bool _isLoading = false;
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic>? _aiAdvice;
  bool _isLoadingAdvice = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    _fetchAdvice();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getUserDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
        ref.read(userDashboardStateProvider.notifier).state = data;
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAdvice() async {
    setState(() => _isLoadingAdvice = true);
    try {
      final api = ref.read(apiServiceProvider);
      final advice = await api.getCitizenAdvice();
      if (mounted && advice.isNotEmpty) {
        setState(() {
          _aiAdvice = advice;
          _isLoadingAdvice = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingAdvice = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAdvice = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchDashboard(),
      _fetchAdvice(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userDashboardReloadTriggerProvider, (_, __) => _fetchDashboard());
    final sharedData = ref.watch(userDashboardStateProvider);
    final data = sharedData ?? _dashboardData;
    final stateUserName = ref.watch(userNameProvider) ?? 'Citizen Recycler';
    final displayName = data['fullName'] ?? stateUserName;
    final totalTokens = data['totalTokens']?.toString() ?? '0';
    final balanceTaka = data['walletBalanceTaka']?.toString() ?? '0.00';
    final totalKg = data['totalPlasticKg']?.toString() ?? '0.00';
    final co2Kg = data['co2PreventedKg']?.toString() ?? '0.00';
    final loyalty = data['loyaltyLevel'] ?? 'Eco Buddy';

    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 96.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header Card with Eco Gradient
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E6027), Color(0xFF438A3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E6027).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco_rounded, size: 14, color: AppTheme.accent),
                              const SizedBox(width: 5),
                              Text(
                                _isLoading ? 'Updating...' : loyalty,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.recycling_rounded, size: 48, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Balance & Impact Grid (Symmetrical 2x2 with centered typography)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _buildMetricCard('Total Tokens', '$totalTokens Tokens', '100 Tokens = 1 kg', Icons.stars_rounded, AppTheme.accent),
                _buildMetricCard('Wallet Balance', '৳$balanceTaka BDT', '4 Tokens = ৳1.00', Icons.account_balance_wallet_rounded, AppTheme.primary),
                _buildMetricCard('Plastic Recycled', '$totalKg kg', 'Disposed safely', Icons.restore_from_trash_rounded, AppTheme.skyBlue),
                _buildMetricCard('CO2 Prevented', '$co2Kg kg', '1.5 kg CO2 / kg', Icons.cloud_done_rounded, AppTheme.primaryLight),
              ],
            ),
            const SizedBox(height: 20),

            // Gemini AI Eco Advisor Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFDE047), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'AI Eco-Advisor',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _aiAdvice?['isLiveAi'] == true ? Icons.bolt_rounded : Icons.eco_outlined,
                              color: const Color(0xFFFDE047),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isLoadingAdvice
                                  ? 'Thinking...'
                                  : (_aiAdvice?['isLiveAi'] == true ? 'Gemini Live' : 'Eco Intelligence'),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_aiAdvice == null && _isLoadingAdvice) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Connecting to Gemini for personalized zero-waste guidance...',
                            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_aiAdvice != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _aiAdvice!['headline']?.toString() ?? 'Dhaka Green Champion',
                      style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _aiAdvice!['advice']?.toString() ?? '',
                      style: const TextStyle(color: Color(0xFFECFDF5), fontSize: 13, height: 1.4),
                    ),
                    if (_aiAdvice!['dailyTip'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFDE047), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: ${_aiAdvice!['dailyTip']}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_aiAdvice!['nextMilestone'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFDE047), size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Goal: ${_aiAdvice!['nextMilestone']}',
                                style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'AI Zero-Waste Advisor',
                      style: TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Recycle clean plastic bottles at any smart booth to generate personalized AI eco-advice and Dhaka environmental milestones.',
                      style: TextStyle(color: Color(0xFFECFDF5), fontSize: 13, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Quick Actions Banner
            const Text(
              'Quick Deposit & Cashout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary, size: 24),
                ),
                title: const Text('Smart Scale Plastic Drop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Scan dynamic QR code at any nearby booth to deposit', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.muted),
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(1);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Go to "Deposit" tab below to scan booth scale QR code.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accent, size: 24),
                ),
                title: const Text('Redeem Tokens for Cash / bKash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Withdraw wallet balance directly to bKash or get discount coupons', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.muted),
                onTap: () {
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtext, IconData icon, Color iconColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
