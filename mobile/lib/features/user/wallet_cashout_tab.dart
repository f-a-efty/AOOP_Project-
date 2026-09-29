import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class WalletCashoutTab extends ConsumerStatefulWidget {
  const WalletCashoutTab({super.key});

  @override
  ConsumerState<WalletCashoutTab> createState() => _WalletCashoutTabState();
}

class _WalletCashoutTabState extends ConsumerState<WalletCashoutTab> {
  final _tokensController = TextEditingController(text: '400');
  final _bkashController = TextEditingController();
  double _calculatedTaka = 100.0;
  String? _errorMessage;
  bool _isLoading = false;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
  }

  Future<void> _fetchUserBalance() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getUserDashboard();
      if (mounted) {
        setState(() {
          _userData = data;
          if (_bkashController.text.isEmpty) {
            _bkashController.text = data['phoneNumber']?.toString() ?? '';
          }
        });
      }
    } catch (_) {}
  }

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

  Future<void> _handleWithdraw() async {
    final tokens = int.tryParse(_tokensController.text.trim()) ?? 0;
    final bkashNum = _bkashController.text.trim();
    final availableTokens = int.tryParse(_userData['totalTokens']?.toString() ?? '0') ?? 0;

    if (tokens < 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal is 400 tokens (৳100.00 BDT)'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    if (tokens > availableTokens) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient balance. You currently have $availableTokens tokens.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    if (bkashNum.isEmpty || bkashNum.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 11-digit bKash account number'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.withdrawToBkash(tokens, bkashNum);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 26),
                SizedBox(width: 8),
                Text('Withdrawal Successful!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payout of ৳${_calculatedTaka.toStringAsFixed(2)} BDT has been dispatched to your bKash wallet ($bkashNum).', style: const TextStyle(fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Deducted:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      Text('$tokens Tokens', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        _fetchUserBalance();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTokens = _userData['totalTokens']?.toString() ?? '...';
    final balanceTaka = _userData['walletBalanceTaka']?.toString() ?? '...';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet & Payouts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 14),

          // Current Balance Header Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E6027), Color(0xFF438A3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E6027).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Token Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text('$availableTokens Tokens', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('≈ ৳$balanceTaka BDT (4 Tokens = ৳1.00)', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cashout Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Instant bKash Cashback', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  const Text('Convert eco-tokens directly to mobile financial account', style: TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                  const SizedBox(height: 18),

                  const Text('Enter Token Amount (Multiple of 4)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 14),

                  // Symmetrical Conversion Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.subtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Cashback Payout:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        Text('৳${_calculatedTaka.toStringAsFixed(2)} BDT', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Target bKash Account Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bkashController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '+88017XXXXXXXX',
                      prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Balanced Submit Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleWithdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.send_to_mobile_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Withdraw to bKash', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
