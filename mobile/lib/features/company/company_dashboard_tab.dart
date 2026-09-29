import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CompanyDashboardTab extends StatelessWidget {
  const CompanyDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Welcome back,', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                  Text('ABC Recycling Ltd.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 4, backgroundColor: Colors.green),
                    SizedBox(width: 6),
                    Text('Live Hub', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Stat Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Assigned Booths', '6', 'Dhaka Central Region', Icons.store_rounded, AppTheme.primary),
              _buildStatCard('Total Plastic', '324.5 kg', 'Lifetime Recovered', Icons.recycling_rounded, AppTheme.accent),
              _buildStatCard('Pickup Required', '2', 'High Priority', Icons.warning_amber_rounded, AppTheme.warningAmber),
              _buildStatCard('This Month', '112.0 kg', '+14% vs Last Month', Icons.trending_up_rounded, AppTheme.skyBlue),
            ],
          ),
          const SizedBox(height: 24),

          // Booth Status Overview
          const Text('Booth Fill Status Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount('Available', '3', Colors.green),
                _buildStatusCount('Almost Full', '1', AppTheme.warningAmber),
                _buildStatusCount('Full', '1', AppTheme.errorRed),
                _buildStatusCount('Maintenance', '1', Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pickup Required List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Pickup Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('2 Booths', style: TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPickupRequiredCard(context, 'BTH-DH-003', 'Uttara Sector 3 Park', 100.0, 100.0, 'Full', AppTheme.errorRed),
          _buildPickupRequiredCard(context, 'BTH-DH-002', 'Mirpur 10 Bus Stand', 82.0, 100.0, 'Almost Full', AppTheme.warningAmber),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCount(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      ],
    );
  }

  Widget _buildPickupRequiredCard(BuildContext context, String code, String area, double current, double total, String status, Color statusColor) {
    final pct = (current / total);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(area, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Capacity Usage:', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                Text('${current.toStringAsFixed(0)} kg / ${total.toStringAsFixed(0)} kg (${(pct * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: pct, backgroundColor: AppTheme.subtle, color: statusColor, minHeight: 8),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pickup Request dispatched for $code.')),
                  );
                },
                child: const Text('Request Pickup Dispatch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
