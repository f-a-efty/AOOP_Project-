import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminOperationsTab extends StatefulWidget {
  const AdminOperationsTab({super.key});

  @override
  State<AdminOperationsTab> createState() => _AdminOperationsTabState();
}

class _AdminOperationsTabState extends State<AdminOperationsTab> {
  int _segmentIndex = 0; // 0: Booths, 1: Collections, 2: Companies Approval Queue

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Operations Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Segmented Control
          Row(
            children: [
              _buildSegmentBtn(0, 'Booths'),
              _buildSegmentBtn(1, 'Collections'),
              _buildSegmentBtn(2, 'Company Queue'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSegmentContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(int index, String label) {
    final isSelected = _segmentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segmentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.subtle,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentContent() {
    if (_segmentIndex == 0) {
      return ListView(
        children: [
          _buildBoothCard('BTH-DH-001', 'Dhanmondi Lake Park', 'ABC Recycling Ltd.', '25.5 / 100 kg', 'Available'),
          _buildBoothCard('BTH-DH-003', 'Uttara Sector 3 Park', 'ABC Recycling Ltd.', '100 / 100 kg', 'Full'),
        ],
      );
    } else if (_segmentIndex == 1) {
      return ListView(
        children: const [
          ListTile(title: Text('Plastic Collection Log'), subtitle: Text('Total platform plastic: 4,892 kg')),
        ],
      );
    } else {
      return ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bengal Eco Solutions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Reg: REC-2024-4112 • Permit #7712-2024\nContact: sabbir@bengaleco.com'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company application rejected.')));
                          },
                          child: const Text('Reject Application', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company approved & activated.')));
                          },
                          child: const Text('Approve Partnership'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBoothCard(String code, String location, String company, String weight, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$location\nAssigned: $company • Weight: $weight'),
        isThreeLine: true,
        trailing: Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
      ),
    );
  }
}
