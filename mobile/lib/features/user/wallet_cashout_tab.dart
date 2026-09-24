import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WalletCashoutTab extends StatefulWidget {
  const WalletCashoutTab({super.key});

  @override
  State<WalletCashoutTab> createState() => _WalletCashoutTabState();
}

class _WalletCashoutTabState extends State<WalletCashoutTab> {
  final _tokensController = TextEditingController(text: '400');
  final _bkashController = TextEditingController(text: '+8801711111111');
  double _calculatedTaka = 100.0;
  String? _errorMessage;

  void _onTokensChanged(String val) {
    final tokens = int.tryParse(val) ?? 0;
    setState(() {
      _calculatedTaka = tokens / 4.0;
      if (tokens < 400) {
        _errorMessage = 'Minimum withdrawal is 400 tokens (৳100.00 BDT)';
      } else if (tokens % 4 != 0) {
        _errorMessage = 'Tokens amount must be a multiple of 4';
      } else {
        _errorMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Balance Header
          Card(
            color: AppTheme.subtle,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Available Tokens Balance', style: TextStyle(color: AppTheme.muted)),
                  const SizedBox(height: 6),
                  const Text('450 Tokens', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 4),
                  Text('Equivalent to ৳112.50 BDT (4 Tokens = ৳1.00)', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cashout Form
          const Text('Withdraw Straight to bKash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          const Text('Enter Token Amount (Multiple of 4)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _tokensController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 400',
              prefixIcon: const Icon(Icons.stars_rounded, color: AppTheme.accent),
              errorText: _errorMessage,
            ),
            onChanged: _onTokensChanged,
          ),
          const SizedBox(height: 12),

          // Live Conversion Preview Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cashback Payout Amount:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '৳${_calculatedTaka.toStringAsFixed(2)} BDT',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('Target bKash Account Number', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _bkashController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '+88017XXXXXXXX',
              prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.pink),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _errorMessage == null ? _handleWithdrawal : null,
            child: const Text('Withdraw Cash to bKash'),
          ),
          const SizedBox(height: 24),

          // Ledger History
          const Text('Withdrawal History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTxItem('2026-09-24', '400 Tokens', '৳100.00 BDT', 'Completed', 'BKASH_MOCK_TX_88102'),
          _buildTxItem('2026-09-20', '100 Tokens Credit', '1.000 kg Plastic', 'Credit', 'DEP-10482'),
        ],
      ),
    );
  }

  Widget _buildTxItem(String date, String title, String amount, String status, String trxId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$date • TrxId: $trxId'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            Text(status, style: const TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  void _handleWithdrawal() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully withdrawn ৳${_calculatedTaka.toStringAsFixed(2)} BDT to ${_bkashController.text}!')),
    );
  }
}
