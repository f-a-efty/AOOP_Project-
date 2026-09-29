import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CompanyAlertsTab extends StatelessWidget {
  const CompanyAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('Operational Alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildAlertCard('Booth Full Alert', 'BTH-DH-003 at Uttara Sector 3 Park has reached 100% capacity (100 kg). Dispatch pickup.', AppTheme.errorRed),
        _buildAlertCard('Almost Full Alert', 'BTH-DH-002 at Mirpur 10 has reached 82% capacity.', AppTheme.warningAmber),
        _buildAlertCard('Pickup Completed', 'Pickup REQ-DH-8010 completed for BTH-DH-001 (98.5 kg cleared).', AppTheme.primary),
      ],
    );
  }

  Widget _buildAlertCard(String title, String message, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.notifications_active_rounded, color: color)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(message),
      ),
    );
  }
}
