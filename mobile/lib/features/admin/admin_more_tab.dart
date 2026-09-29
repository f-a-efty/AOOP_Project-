import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminMoreTab extends StatelessWidget {
  const AdminMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('System Administration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildAdminRow(context, 'Loyalty Tier Rules', 'Eco Buddy (0-50kg), Green Friend (50-150kg)...', Icons.military_tech_rounded),
        _buildAdminRow(context, 'Green Campaigns', 'Manage Dhaka Clean 2026 & Eco Challenges', Icons.campaign_rounded),
        _buildAdminRow(context, 'Reports & Analytics', 'Export platform CSV reports & impact metrics', Icons.assessment_rounded),
        _buildAdminRow(context, 'Audit Logs', 'View administrative action timeline', Icons.policy_rounded),
        _buildAdminRow(context, 'System Settings', 'API keys & gateway configurations', Icons.settings_rounded),
      ],
    );
  }

  Widget _buildAdminRow(BuildContext context, String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppTheme.subtle, child: Icon(icon, color: AppTheme.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opened $title module')),
          );
        },
      ),
    );
  }
}
