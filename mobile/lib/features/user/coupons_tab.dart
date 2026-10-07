import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class CouponsTab extends ConsumerStatefulWidget {
  const CouponsTab({super.key});

  @override
  ConsumerState<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends ConsumerState<CouponsTab> {
  bool _isLoading = false;
  List<dynamic> _coupons = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
    _fetchUserBalance();
  }

  Future<void> _fetchUserBalance() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getUserDashboard();
      if (mounted) {
        ref.read(userDashboardStateProvider.notifier).state = data;
      }
    } catch (_) {}
  }

  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getCoupons();
      if (mounted) {
        setState(() {
          _coupons = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load brand vouchers.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _redeemCoupon(int couponId, String brand, String code, int cost) async {
    final sharedData = ref.read(userDashboardStateProvider);
    final availableTokens = (sharedData?['totalTokens'] as num?)?.toInt() ?? 0;
    if (availableTokens < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient tokens. You have $availableTokens tokens, but this voucher requires $cost tokens.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      await api.redeemCoupon(couponId);

      // Trigger global synchronization across Home, Wallet, and all user tabs
      ref.read(userDashboardReloadTriggerProvider.notifier).state++;
      await _fetchUserBalance();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 26),
                SizedBox(width: 8),
                Text('Voucher Redeemed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your $brand discount voucher has been unlocked using $cost tokens.', style: const TextStyle(fontSize: 13.5)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.subtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      const Text('Show Code at Checkout:', style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.5, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Save to Wallet'),
              ),
            ],
          ),
        );
        _fetchCoupons();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to redeem voucher: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userDashboardReloadTriggerProvider, (_, __) {
      _fetchCoupons();
      _fetchUserBalance();
    });
    final sharedData = ref.watch(userDashboardStateProvider);
    final totalTokens = (sharedData?['totalTokens'] as num?)?.toInt() ?? 0;
    final balanceTaka = sharedData?['walletBalanceTaka']?.toString() ?? (totalTokens / 4.0).toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Partner Vouchers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                tooltip: 'Refresh vouchers',
                onPressed: () {
                  _fetchCoupons();
                  _fetchUserBalance();
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Spend earned tokens on exclusive retail vouchers', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 12),

          // Synced Available Balance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.stars_rounded, color: Color(0xFF166534), size: 20),
                    SizedBox(width: 8),
                    Text('Available Balance:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF166534), fontSize: 13)),
                  ],
                ),
                Text('$totalTokens Tokens (≈ ৳$balanceTaka)', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF166534), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 36),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchCoupons, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchCoupons,
                        color: AppTheme.primary,
                        child: ListView.separated(
                          itemCount: _coupons.isNotEmpty ? _coupons.length : _fallbackCoupons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final c = _coupons.isNotEmpty ? (_coupons[index] as Map<String, dynamic>) : _fallbackCoupons[index];
                            final id = int.tryParse(c['couponId']?.toString() ?? '0') ?? (index + 1);
                            final brand = c['brandName']?.toString() ?? 'Retail Brand';
                            final code = c['promoCode']?.toString() ?? 'ECO-DISCOUNT';
                            final discount = c['discountPercentage']?.toString() ?? '15';
                            final cost = int.tryParse(c['tokenCost']?.toString() ?? '200') ?? 200;
                            final terms = c['termsAndConditions']?.toString() ?? 'Valid for participating outlets.';

                            Color brandColor = AppTheme.primary;
                            if (brand.contains('Aarong')) brandColor = Colors.purple.shade700;
                            if (brand.contains('Shwapno')) brandColor = Colors.red.shade700;
                            if (brand.contains('Agora')) brandColor = Colors.orange.shade800;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: brandColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(brand, style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(20)),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.stars_rounded, size: 14, color: AppTheme.accent),
                                              const SizedBox(width: 4),
                                              Text('$cost Tokens', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text('$discount% Discount Voucher', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                    const SizedBox(height: 4),
                                    Text(terms, style: const TextStyle(color: AppTheme.muted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 16),

                                    // Balanced Redeem Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed: () => _redeemCoupon(id, brand, code, cost),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.local_offer_outlined, size: 16, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Redeem Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _fallbackCoupons = [
    {'couponId': 1, 'brandName': 'Aarong Lifestyle', 'promoCode': 'AARONG-GREEN-15', 'discountPercentage': 15, 'tokenCost': 200, 'termsAndConditions': 'Valid on lifestyle & sustainable line. Min purchase ৳1000.'},
    {'couponId': 2, 'brandName': 'Shwapno Superstore', 'promoCode': 'SHWAPNO-ECO-100', 'discountPercentage': 10, 'tokenCost': 150, 'termsAndConditions': 'Valid for fresh produce and groceries at any Shwapno outlet.'},
    {'couponId': 3, 'brandName': 'Agora Superstore', 'promoCode': 'AGORA-PLASTIC-20', 'discountPercentage': 20, 'tokenCost': 300, 'termsAndConditions': 'Valid for reusable bag & sustainable product lines.'},
  ];
}
