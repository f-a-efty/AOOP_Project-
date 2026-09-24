import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CollectionHistoryTab extends StatelessWidget {
  const CollectionHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Collection History Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting collection log CSV report...')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildHistoryCard('2026-09-23', 'BTH-DH-001', 'Dhanmondi Lake Park', '98.50 kg', 'PET 100% Sorted'),
        _buildHistoryCard('2026-09-18', 'BTH-DH-004', 'Gulshan 2 DCC Market', '142.00 kg', 'PET/HDPE Mixed'),
      ],
    );
  }

  Widget _buildHistoryCard(String date, String boothCode, String location, String weight, String grade) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('$boothCode • $weight', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$location\nGrade: $grade • Date: $date'),
        isThreeLine: true,
        trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
      ),
    );
  }
}
