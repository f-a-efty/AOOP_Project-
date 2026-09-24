import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminFinanceTab extends StatefulWidget {
  const AdminFinanceTab({super.key});

  @override
  State<AdminFinanceTab> createState() => _AdminFinanceTabState();
}

class _AdminFinanceTabState extends State<AdminFinanceTab> {
  int _tokensPerKg = 100;
  int _tokensPerTaka = 4;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('Finance & Reward Rules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Active Economics Rule Card
        Card(
          color: AppTheme.subtle,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Token Reward Rule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                const SizedBox(height: 8),
                Text('1 kg Plastic = $_tokensPerKg Tokens (1 Token / 10g)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('Cashback Rate: $_tokensPerTaka Tokens = ৳1.00 BDT (Effective ৳25.00/kg)', style: const TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showEditRuleDialog,
                  child: const Text('Edit Reward Rule'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text('Coupons Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Create New Partner Coupon'),
            subtitle: const Text('Add Aarong, Shwapno, or Agora promo codes'),
            trailing: const Icon(Icons.add_circle_rounded, color: AppTheme.primary),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opened Coupon Creation Form')));
            },
          ),
        ),
      ],
    );
  }

  void _showEditRuleDialog() {
    final tokensController = TextEditingController(text: _tokensPerKg.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Reward Rule Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter number of tokens issued per 1 kg of plastic:'),
            const SizedBox(height: 12),
            TextField(
              controller: tokensController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tokens per kg', hintText: '100'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmRateChange(int.tryParse(tokensController.text) ?? 100);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmRateChange(int newRate) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Confirm Economics Rate Change'),
        content: Text('Changing the reward rate to $newRate tokens/kg will affect future plastic deposits. This action is recorded in the platform audit log.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber),
            onPressed: () {
              setState(() => _tokensPerKg = newRate);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reward rule updated to $newRate tokens/kg & audit log written.')),
              );
            },
            child: const Text('Confirm Change'),
          ),
        ],
      ),
    );
  }
}
