import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ImpactLeaderboardTab extends StatelessWidget {
  const ImpactLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('Community Recycling Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Top Dhaka Eco-Citizens saving plastic from landfills', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 16),
        _buildLeaderboardItem(1, 'Tania Sultana', '48.50 kg', 'Nature Hero', true),
        _buildLeaderboardItem(2, 'Rakibul Islam (You)', '4.50 kg', 'Green Friend', false),
        _buildLeaderboardItem(3, 'Mahmud Hasan', '3.20 kg', 'Eco Buddy', false),
        _buildLeaderboardItem(4, 'Sabbir Ahmed', '2.80 kg', 'Eco Buddy', false),
      ],
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, String weight, String level, bool isTop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTop ? AppTheme.accent : AppTheme.subtle,
          child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: isTop ? AppTheme.textDark : AppTheme.primary)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(level),
        trailing: Text(weight, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
      ),
    );
  }
}
