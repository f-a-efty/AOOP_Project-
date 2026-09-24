import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PickupRequestsTab extends StatelessWidget {
  const PickupRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Figma Vehicle Assignment Future Release Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.subtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryLight),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: AppTheme.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Automated Vehicle Assignment - Feature active in Phase 2 module.',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Active Pickup Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildPickupCard(context, 'REQ-DH-8012', 'BTH-DH-003 • Uttara Sector 3', '100.0 kg (Full)', 'HIGH', 'Pending', AppTheme.errorRed),
        _buildPickupCard(context, 'REQ-DH-8013', 'BTH-DH-002 • Mirpur 10', '82.0 kg (Almost Full)', 'NORMAL', 'Accepted', AppTheme.warningAmber),
      ],
    );
  }

  Widget _buildPickupCard(BuildContext context, String code, String booth, String payload, String priority, String status, Color statusColor) {
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
            const SizedBox(height: 6),
            Text(booth, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 4),
            Text('Payload: $payload', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Accepted pickup request.')),
                      );
                    },
                    child: const Text('Accept Request'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vehicle DHAKA-METRO-HA-11-2041 assigned.')),
                      );
                    },
                    child: const Text('Assign Vehicle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
