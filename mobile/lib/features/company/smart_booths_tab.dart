import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SmartBoothsTab extends StatelessWidget {
  const SmartBoothsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Smart Booths', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(12)),
              child: const Text('6 Assigned', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBoothListItem('BTH-DH-001', 'Dhanmondi Lake Park', 25.5, 100.0, 'Available', Colors.green),
        _buildBoothListItem('BTH-DH-002', 'Mirpur 10 Roundabout', 82.0, 100.0, 'Almost Full', AppTheme.warningAmber),
        _buildBoothListItem('BTH-DH-003', 'Uttara Sector 3 Park', 100.0, 100.0, 'Full', AppTheme.errorRed),
        _buildBoothListItem('BTH-DH-004', 'Gulshan 2 DCC Plaza', 12.0, 150.0, 'Available', Colors.green),
        _buildBoothListItem('BTH-DH-005', 'Banani Chairman Bari', 0.0, 100.0, 'Empty', Colors.grey),
      ],
    );
  }

  Widget _buildBoothListItem(String code, String location, double current, double total, String status, Color statusColor) {
    final pct = (current / total);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(Icons.smart_toy_rounded, color: statusColor)),
        title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: pct, backgroundColor: AppTheme.subtle, color: statusColor, minHeight: 6),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
            Text('${current.toStringAsFixed(0)}/$total kg', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
