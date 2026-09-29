import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class CouponsTab extends ConsumerStatefulWidget {
  const CouponsTab({super.key});

  @override
  ConsumerState<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends ConsumerState<CouponsTab> {
  final _authService = AuthService();
  bool _isLoading = false;
  List<dynamic> _coupons = [];
  Map<String, dynamic>? _dashboardData;
  final Set<int> _redeemingIds = {};

  @override
  void initState() {
    super.initState();
    _loadCouponsAndUser();
  }

  Future<void> _loadCouponsAndUser() async {
    final token = ref.read(authTokenProvider);
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final couponsList = await _authService.fetchCoupons(token);
      final dash = await _authService.fetchUserDashboard(token);
      if (mounted) {
        setState(() {
          _coupons = couponsList;
          _dashboardData = dash;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRedeem(int couponId, String brand, String title, int cost,
      String promoCode) async {
    final token = ref.read(authTokenProvider);
    final userTokens = _dashboardData?['totalTokens'] as int? ?? 0;

    if (userTokens < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Insufficient tokens! Requires $cost tokens, but you have $userTokens tokens.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _redeemingIds.add(couponId));

    try {
      await _authService.redeemCoupon(token, couponId);

      // Trigger reload across all screens (Home, Wallet, Impact)
      ref.read(userDashboardReloadTriggerProvider.notifier).state++;
      await _loadCouponsAndUser();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.confirmation_number_rounded,
                  color: AppTheme.primary, size: 28),
              SizedBox(width: 8),
              Text('Voucher Redeemed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎉 Successfully redeemed $brand voucher for $cost tokens!'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.subtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryLight),
                ),
                child: Column(
                  children: [
                    const Text('PROMO CODE:',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.muted,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(
                      promoCode,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Use Now'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Redemption failed.';
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
              content: const Text('Could not complete voucher redemption.'),
              backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _redeemingIds.remove(couponId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
        userDashboardReloadTriggerProvider, (_, __) => _loadCouponsAndUser());

    final userTokens = _dashboardData?['totalTokens'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadCouponsAndUser,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Partner Brand Vouchers',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Spend earned Tokens on exclusive discounts',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
              Chip(
                backgroundColor: AppTheme.subtle,
                avatar: const Icon(Icons.stars_rounded,
                    color: AppTheme.accent, size: 18),
                label: Text('$userTokens Tokens',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading && _coupons.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_coupons.isEmpty) ...[
            // Fallback default coupons if DB returns empty
            _buildLocalCouponCard(
                1,
                'Aarong Lifestyle',
                '15% Off All Fashion & Crafts',
                200,
                'AARONG-GREEN-15',
                Colors.purple),
            _buildLocalCouponCard(
                2,
                'Shwapno Superstore',
                '৳100 Discount on Groceries',
                150,
                'SHWAPNO-ECO-100',
                Colors.red),
            _buildLocalCouponCard(
                3,
                'Agora Superstore',
                '20% Off Eco Reusable Line',
                300,
                'AGORA-PLASTIC-20',
                Colors.orange),
          ] else ...[
            ..._coupons.map((c) {
              final id = c['couponId'] as int? ?? c['id'] as int? ?? 1;
              final brand = c['brandName'] ?? 'Brand Partner';
              final title = c['termsAndConditions'] ??
                  c['promoCode'] ??
                  'Discount Voucher';
              final cost = c['tokenCost'] as int? ?? 150;
              final code = c['promoCode'] ?? 'ECO-DISCOUNT';
              final discount = c['discountPercentage'] != null
                  ? '${c['discountPercentage']}% Off'
                  : 'Discount Voucher';

              return _buildCouponCard(id, brand, '$discount - $title', cost,
                  code, AppTheme.primary);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalCouponCard(int id, String brand, String title, int cost,
      String code, Color brandColor) {
    return _buildCouponCard(id, brand, title, cost, code, brandColor);
  }

  Widget _buildCouponCard(int id, String brand, String title, int cost,
      String code, Color brandColor) {
    final userTokens = _dashboardData?['totalTokens'] as int? ?? 0;
    final isRedeeming = _redeemingIds.contains(id);
    final canAfford = userTokens >= cost;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: brandColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(brand,
                      style: TextStyle(
                          color: brandColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: canAfford ? AppTheme.subtle : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$cost Tokens',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canAfford ? AppTheme.primary : Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Promo Code: $code',
                style: const TextStyle(
                    color: AppTheme.muted, fontFamily: 'monospace')),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canAfford ? AppTheme.primary : Colors.grey.shade400,
                ),
                onPressed: isRedeeming
                    ? null
                    : () => _handleRedeem(id, brand, title, cost, code),
                child: isRedeeming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(canAfford
                        ? 'Redeem Voucher ($cost Tokens)'
                        : 'Insufficient Tokens ($cost Needed)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
