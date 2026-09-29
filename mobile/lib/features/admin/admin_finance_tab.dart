import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class AdminFinanceTab extends ConsumerStatefulWidget {
  const AdminFinanceTab({super.key});

  @override
  ConsumerState<AdminFinanceTab> createState() => _AdminFinanceTabState();
}

class _AdminFinanceTabState extends ConsumerState<AdminFinanceTab> {
  int _tokensPerKg = 100;
  int _tokensPerTaka = 4;
  bool _isSaving = false;

  void _showEditRuleDialog() {
    final tokensController = TextEditingController(text: _tokensPerKg.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Platform Reward Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the number of tokens issued per 1 kg of verified plastic deposited by citizens:',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tokensController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tokens per kg',
                hintText: '100',
                prefixIcon: Icon(Icons.stars_rounded, color: AppTheme.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmRateChange(int.tryParse(tokensController.text) ?? 100);
            },
            child: const Text('Save Rule'),
          ),
        ],
      ),
    );
  }

  void _confirmRateChange(int newRate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Confirm Economics Rule Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Changing the reward rate to $newRate tokens/kg will affect all subsequent plastic deposits across Dhaka smart booths. This action is permanently recorded in the platform audit log.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSaving = true);
              try {
                final api = ref.read(apiServiceProvider);
                await api.updateEconomicsRule('tokens-per-kg', newRate.toString());
                if (mounted) {
                  setState(() {
                    _tokensPerKg = newRate;
                    _isSaving = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated reward rate to $newRate tokens/kg in system config.'),
                      backgroundColor: const Color(0xFF2E6027),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update config: $e'),
                      backgroundColor: AppTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm & Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Finance & Economics Rules', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 14),

          // Active Economics Rule Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.currency_exchange_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text('Active Token Reward Formula', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                        child: const Text('ACTIVE RULE', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('1 kg Verified Plastic = $_tokensPerKg Tokens (1 Token / 10g)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text('Cashback Rate: $_tokensPerTaka Tokens = ৳1.00 BDT (Effective ৳${(_tokensPerKg / _tokensPerTaka).toStringAsFixed(2)}/kg)', style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _showEditRuleDialog,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Edit Reward Rule Formula', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Partner Vouchers & Merchant Rules', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.primary, size: 20),
              ),
              title: const Text('Create New Retail Partner Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Aarong, Shwapno, Agora, or Chaldal discounts', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voucher creation dialog active in production module.'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
