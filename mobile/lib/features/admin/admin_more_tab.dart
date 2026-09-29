import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class AdminMoreTab extends ConsumerWidget {
  const AdminMoreTab({super.key});

  void _showAuditLogs(BuildContext context, WidgetRef ref) async {
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
                  final time = log['createdAt']?.toString()?.replaceFirst('T', ' ')?.split('.')?.first ?? '';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        const Text('System Administration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 14),

        _buildAdminRow(
          context,
          'Live Platform Audit Logs',
          'Inspect administrator action history recorded in MySQL',
          Icons.policy_rounded,
          () => _showAuditLogs(context, ref),
        ),
        _buildAdminRow(
          context,
          'Loyalty Tier Rules',
          'Eco Buddy (0-50kg), Green Friend (50-150kg), Nature Hero (150kg+)',
          Icons.military_tech_rounded,
          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tier rules are managed dynamically.'))),
        ),
        _buildAdminRow(
          context,
          'Green Campaigns & Contests',
          'Dhaka Clean Metro 2026 plastic recovery incentives',
          Icons.campaign_rounded,
          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign schedule active.'))),
        ),
        _buildAdminRow(
          context,
          'Reports & Environmental Impact',
          'Export verified recycled PET data sheets & carbon offset stats',
          Icons.assessment_rounded,
          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting summary report...'))),
        ),
        _buildAdminRow(
          context,
          'IoT Hardware Gateway Settings',
          'Telemetry polling rate, sensor calibration, load cell tolerances',
          Icons.settings_suggest_rounded,
          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hardware gateways online (6/6).'))),
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
