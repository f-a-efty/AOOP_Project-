import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  String _selectedRange = '30d';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Good morning, Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              CircleAvatar(backgroundColor: AppTheme.subtle, child: Icon(Icons.notifications_rounded, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 20),

          // Swipeable / Grid Metrics
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildMetricTile('Registered Users', '1,248', '+12% this month', Icons.people_alt_rounded, AppTheme.primary),
              _buildMetricTile('Plastic Collected', '4,892 kg', '100% sorted PET', Icons.recycling_rounded, AppTheme.accent),
              _buildMetricTile('Tokens Issued', '489,200', '100 Tokens / kg', Icons.stars_rounded, AppTheme.warningAmber),
              _buildMetricTile('Cashback Paid', '৳122,300', 'Direct to bKash', Icons.account_balance_wallet_rounded, AppTheme.skyBlue),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Segment Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Plastic Collection Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: ['7d', '30d', '6m', '1y'].map((range) {
                  final isSel = _selectedRange == range;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primary : AppTheme.subtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(range.toUpperCase(), style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppTheme.muted, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chart Container
          Container(
            height: 140,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: const Center(
              child: Text('📈 Collection Analytics Chart (fl_chart visualization)', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Activity Feed
          const Text('Recent Platform Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActivityItem('New Company Registration', 'Bengal Eco Solutions submitted application', '10 mins ago'),
          _buildActivityItem('Pickup Completed', 'REQ-DH-8010 completed by ABC Recycling (98.5 kg)', '45 mins ago'),
          _buildActivityItem('Cashback Withdrawn', 'User Rakibul Islam withdrew 400 Tokens (৳100 BDT)', '2 hours ago'),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, String sub, IconData icon, Color color) {
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
                Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String desc, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppTheme.subtle, child: Icon(Icons.bolt_rounded, color: AppTheme.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      ),
    );
  }
}
