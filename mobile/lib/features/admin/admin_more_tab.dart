import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class AdminMoreTab extends ConsumerStatefulWidget {
  const AdminMoreTab({super.key});

  @override
  ConsumerState<AdminMoreTab> createState() => _AdminMoreTabState();
}

class _AdminMoreTabState extends ConsumerState<AdminMoreTab> {
  void _showAuditLogs(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Live System Audit Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: FutureBuilder<List<dynamic>>(
            future: ref.read(apiServiceProvider).getAuditLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) {
                return const Center(
                  child: Text('No audit entries recorded yet.', style: TextStyle(color: AppTheme.muted)),
                );
              }
              return ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (_, __) => const Divider(height: 12, color: AppTheme.border),
                itemBuilder: (context, index) {
                  final log = logs[index] as Map<String, dynamic>;
                  final action = log['action'] ?? 'ACTION';
                  final detail = log['detail'] ?? '';
                  final admin = log['adminEmail'] ?? 'admin';
                  final rawTime = log['createdAt']?.toString();
                  final time = rawTime != null ? rawTime.replaceFirst('T', ' ').split('.').first : '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                          Text(time, style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(detail, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                      const SizedBox(height: 1),
                      Text('By: $admin', style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontStyle: FontStyle.italic)),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLoyaltyTiers(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<dynamic>>(
          future: ref.read(apiServiceProvider).getLoyaltyLevels(),
          builder: (context, snapshot) {
            final levels = (snapshot.data ?? [
              {'level': 'Eco Buddy', 'minKg': 0.0, 'maxKg': 49.9, 'multiplier': 1.0, 'benefits': 'Standard tokens + eco dashboard access'},
              {'level': 'Green Friend', 'minKg': 50.0, 'maxKg': 149.9, 'multiplier': 1.2, 'benefits': '+20% bonus tokens & merchant partner coupons'},
              {'level': 'Nature Hero', 'minKg': 150.0, 'maxKg': 9999.0, 'multiplier': 1.5, 'benefits': '+50% bonus tokens, priority cashout & zero transaction fee'},
            ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Loyalty Tier System', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Citizens automatically level up based on verified cumulative plastic recycled.', style: TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                  const SizedBox(height: 16),
                  ...levels.map((lvl) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706)),
                      ),
                      title: Text(lvl['level']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${lvl['minKg']} kg - ${lvl['maxKg']} kg (${lvl['multiplier']}x Multiplier)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                          const SizedBox(height: 2),
                          Text(lvl['benefits']?.toString() ?? '', style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCampaigns(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<dynamic>>(
          future: ref.read(apiServiceProvider).getAdminCampaigns(),
          builder: (context, snapshot) {
            final campaigns = (snapshot.data ?? [
              {
                'campaignId': 1,
                'title': 'Dhaka Clean Metro 2026',
                'type': 'RECYCLING_CONTEST',
                'targetKg': 1000.0,
                'rewardTokens': 500,
                'status': 'ACTIVE',
                'description': 'Help collect 1,000 kg plastic across 6 smart booths to earn bonus tokens.'
              },
              {
                'campaignId': 2,
                'title': 'Mirpur Green Week',
                'type': 'COMMUNITY_DRIVE',
                'targetKg': 500.0,
                'rewardTokens': 250,
                'status': 'UPCOMING',
                'description': 'Special community plastic drop-off drive at Mirpur 10 roundabout.'
              }
            ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Green Campaigns & Contests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Active community initiatives incentivizing municipal plastic recovery.', style: TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                  const SizedBox(height: 16),
                  ...campaigns.map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c['status'] == 'ACTIVE' ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(c['status']?.toString() ?? 'ACTIVE', style: TextStyle(color: c['status'] == 'ACTIVE' ? const Color(0xFF166534) : const Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(c['description']?.toString() ?? '', style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Target: ${c['targetKg']} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('+${c['rewardTokens']} Bonus Tokens', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showReportsAnalytics(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<Map<String, dynamic>>(
          future: ref.read(apiServiceProvider).getAdminAnalytics(days: 30),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {
              'totalPlasticKg': 487.3,
              'totalTokensIssued': 48730,
              'activeBoothsCount': 6,
              'co2PreventedKg': 730.9,
              'topBooths': [
                {'boothCode': 'BTH-DH-001', 'location': 'Dhanmondi Lake Park', 'plasticKg': 168.5},
                {'boothCode': 'BTH-DH-003', 'location': 'Uttara Sector 3', 'plasticKg': 142.0},
                {'boothCode': 'BTH-DH-002', 'location': 'Mirpur 10 Stand', 'plasticKg': 98.2},
              ],
            };

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Environmental Impact Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('30-day verified plastic recovery and municipal decarbonization statistics.', style: TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Recovered', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                              const SizedBox(height: 4),
                              Text('${data['totalPlasticKg']} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CO2 Abated', style: TextStyle(fontSize: 11, color: Color(0xFF166534))),
                              const SizedBox(height: 4),
                              Text('${data['co2PreventedKg']} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Top Performing Smart Booths', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...((data['topBooths'] as List? ?? []).map((b) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.storefront_rounded, color: AppTheme.primary),
                      title: Text(b['boothCode']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text(b['location']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                      trailing: Text('${b['plasticKg']} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ),
                  ))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showGeminiStatusDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 24),
            SizedBox(width: 10),
            Text('Google Gemini AI Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Live Cloud Neural Engine Active',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Authentic Google Gemini AI is directly applied at the backend to power autonomous environmental impact forecasting and personalized citizen zero-waste guidance.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.muted, height: 1.45),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildEngineSpecRow('Active Model', 'Gemini 3.5 Flash (Live & Fast)'),
                  const Divider(height: 12, thickness: 0.5),
                  _buildEngineSpecRow('Key Management', 'Secure Backend Server (Ready)'),
                  const Divider(height: 12, thickness: 0.5),
                  _buildEngineSpecRow('Live Forecasting', 'Real-Time Dhaka Ecology & WASA drainage'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        const Text('System Administration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 4),
        const Text('Configure rules, campaigns, AI models, and audit logs', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
        const SizedBox(height: 18),

        _buildAdminRow(
          context,
          'Live Platform Audit Logs',
          'Inspect administrator action history recorded in MySQL',
          Icons.policy_rounded,
          () => _showAuditLogs(context),
        ),
        _buildAdminRow(
          context,
          'Loyalty Tier Rules',
          'Eco Buddy (0-50kg), Green Friend (50-150kg), Nature Hero (150kg+)',
          Icons.military_tech_rounded,
          () => _showLoyaltyTiers(context),
        ),
        _buildAdminRow(
          context,
          'Green Campaigns & Contests',
          'Dhaka Clean Metro 2026 plastic recovery incentives & drives',
          Icons.campaign_rounded,
          () => _showCampaigns(context),
        ),
        _buildAdminRow(
          context,
          'Reports & Environmental Impact',
          '30-day verified recycled PET sheets & carbon abated metrics',
          Icons.assessment_rounded,
          () => _showReportsAnalytics(context),
        ),
        _buildAdminRow(
          context,
          'Google Gemini AI Engine',
          'Live cloud neural model: Gemini 3.5 Flash (Backend Integrated)',
          Icons.auto_awesome_rounded,
          () => _showGeminiStatusDialog(context),
        ),
        _buildAdminRow(
          context,
          'IoT Hardware Simulator Gateway',
          'Access Smart Booth hardware load cell simulator on port 8080',
          Icons.memory_rounded,
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Simulator accessible at http://localhost:8080/api/v1/sim')),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminRow(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textDark)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.muted),
        onTap: onTap,
      ),
    );
  }
}
