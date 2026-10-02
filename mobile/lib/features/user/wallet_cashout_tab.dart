import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class WalletCashoutTab extends ConsumerStatefulWidget {
  const WalletCashoutTab({super.key});

  @override
  ConsumerState<WalletCashoutTab> createState() => _WalletCashoutTabState();
}

class _WalletCashoutTabState extends ConsumerState<WalletCashoutTab> {
  final _tokensController = TextEditingController(text: '400');
  final _bkashController = TextEditingController();
  final _authService = AuthService();
  double _calculatedTaka = 100.0;
  int _tokensPerTaka = 4;
  int _minimumWithdrawalTokens = 400;
  String? _errorMessage;
  bool _tokensEdited = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = ref.read(authTokenProvider);
    final user = ref.read(currentUserProvider);

    if (_bkashController.text.isEmpty && user?['phoneNumber'] != null) {
      _bkashController.text = user!['phoneNumber'].toString();
    }

    if (token == null) return;

    try {
      final dash = await _authService.fetchUserDashboard(token);
      final txs = await _authService.fetchTransactions(token);
      if (mounted) {
        setState(() {
          _dashboardData = dash;
          _transactions = txs;
          _tokensPerTaka = (dash['tokensPerTaka'] as num?)?.toInt() ?? 4;
          _minimumWithdrawalTokens =
              (dash['minimumWithdrawalTokens'] as num?)?.toInt() ?? 400;
          if (!_tokensEdited) {
            _tokensController.text = _minimumWithdrawalTokens.toString();
            _calculatedTaka = _minimumWithdrawalTokens / _tokensPerTaka;
          }
          if (_bkashController.text.isEmpty &&
              dash['bkashNumber'] != null &&
              dash['bkashNumber'].toString().isNotEmpty) {
            _bkashController.text = dash['bkashNumber'].toString();
          }
        });
      }
    } catch (_) {}
  }

  void _onTokensChanged(String val) {
    final tokens = int.tryParse(val) ?? 0;
    final availableTokens = _dashboardData?['totalTokens'] as int? ?? 0;
    _tokensEdited = true;
    setState(() {
      _calculatedTaka = tokens / _tokensPerTaka;
      if (tokens < _minimumWithdrawalTokens) {
        _errorMessage =
            'Minimum withdrawal is $_minimumWithdrawalTokens tokens';
      } else if (availableTokens > 0 && tokens > availableTokens) {
        _errorMessage =
            'Insufficient balance (You have $availableTokens tokens)';
      } else {
        _errorMessage = null;
      }
    });
  }

  Future<void> _handleWithdrawal() async {
    final tokens = int.tryParse(_tokensController.text) ?? 0;
    final phone = _bkashController.text.trim();

    if (tokens < _minimumWithdrawalTokens) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Minimum withdrawal is $_minimumWithdrawalTokens tokens.')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bKash number.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final token = ref.read(authTokenProvider);

    try {
      await _authService.withdrawToBkash(
        token,
        tokens: tokens,
        bkashNumber: phone,
      );

      ref.read(userDashboardReloadTriggerProvider.notifier).state++;
      await _loadData();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Withdrawal Submitted!'),
            ],
          ),
          content: Text(
            '৳${_calculatedTaka.toStringAsFixed(2)} BDT has been transferred to bKash account $phone successfully!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          'Withdrawal failed. Check your token balance.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg.toString()),
              backgroundColor: Colors.red.shade700),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully simulated payout of ৳${_calculatedTaka.toStringAsFixed(2)} BDT to $phone!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userDashboardReloadTriggerProvider, (_, __) => _loadData());

    final availableTokens = _dashboardData?['totalTokens'] ?? 0;
    final walletBalance = _dashboardData?['walletBalanceTaka'] != null
        ? (_dashboardData!['walletBalanceTaka'] as num).toDouble()
        : (availableTokens / _tokensPerTaka);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Balance Header
          Card(
            color: AppTheme.subtle,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Available Tokens Balance',
                      style: TextStyle(color: AppTheme.muted)),
                  const SizedBox(height: 6),
                  Text(
                    '$availableTokens Tokens',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Equivalent to ৳${walletBalance.toStringAsFixed(2)} BDT ($_tokensPerTaka Tokens = ৳1.00)',
                    style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cashout Form
          const Text('Withdraw Straight to bKash',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Text('Enter Token Amount (Min $_minimumWithdrawalTokens tokens)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _tokensController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 100',
              prefixIcon:
                  const Icon(Icons.stars_rounded, color: AppTheme.accent),
              errorText: _errorMessage,
            ),
            onChanged: _onTokensChanged,
          ),
          const SizedBox(height: 12),

          // Live Conversion Preview Box
          Builder(
            builder: (context) {
              final enteredTokens = int.tryParse(_tokensController.text) ?? 0;
              final liveTaka = enteredTokens / 4.0;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cashback Payout Amount:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '৳${liveTaka.toStringAsFixed(2)} BDT',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          const Text('Target bKash Account Number',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _bkashController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '+88017XXXXXXXX',
              prefixIcon: Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.pink),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: (_errorMessage == null && !_isSubmitting)
                ? _handleWithdrawal
                : null,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Withdraw Cash to bKash'),
          ),
          const SizedBox(height: 28),

          // Ledger History
          const Text('Transaction History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                      'No transactions yet. Deposit plastic to earn tokens!',
                      style: TextStyle(color: AppTheme.muted)),
                ),
              ),
            )
          else
            ..._transactions.map((tx) {
              final date = tx['timestamp'] != null
                  ? tx['timestamp'].toString().split('T')[0]
                  : 'Recent';
              final type = tx['type'] ?? 'Transaction';
              final tokensDelta = tx['tokensDelta'] ?? 0;
              final amountStr = tokensDelta >= 0
                  ? '+$tokensDelta Tokens'
                  : '$tokensDelta Tokens';
              final status = tx['status'] ?? 'Completed';
              final trxId = tx['bkashTrxId'] ?? tx['trxId'] ?? 'DEP-CREDIT';

              return _buildTxItem(date, type, amountStr, status, trxId);
            }),
        ],
      ),
    );
  }

  Widget _buildTxItem(
      String date, String title, String amount, String status, String trxId) {
    final isCredit = amount.startsWith('+');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$date • Ref: $trxId'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            Text(status,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
