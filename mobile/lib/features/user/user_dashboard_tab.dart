import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class UserDashboardTab extends StatelessWidget {
  const UserDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Rakibul Islam', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('🌿 Green Friend Tier', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.eco_rounded, size: 64, color: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Balance Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Tokens', '450 Tokens', '100 Tokens = 1 kg', Icons.stars_rounded, AppTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('Wallet Balance', '৳112.50 BDT', '4 Tokens = ৳1.00', Icons.account_balance_wallet_rounded, AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Plastic Recycled', '4.500 kg', 'Disposed safely', Icons.recycling_rounded, AppTheme.skyBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard('CO2 Prevented', '6.75 kg', '1.5 kg CO2 / plastic kg', Icons.cloud_done_rounded, AppTheme.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Action Banner
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.subtle, child: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary)),
              title: const Text('Deposit Plastic at Smart Booth', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Scan dynamic QR code on booth scale'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtext, IconData icon, Color iconColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                Icon(icon, color: iconColor, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text(subtext, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
