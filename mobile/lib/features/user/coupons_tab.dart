import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CouponsTab extends StatelessWidget {
  const CouponsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('Partner Brand Vouchers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Spend earned Tokens on exclusive discounts', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 16),
        _buildCouponCard(context, 'Aarong Lifestyle', '15% Off All Fashion & Crafts', '200 Tokens', 'AARONG-GREEN-15', Colors.purple),
        _buildCouponCard(context, 'Shwapno Superstore', '৳100 Discount on Groceries', '150 Tokens', 'SHWAPNO-ECO-100', Colors.red),
        _buildCouponCard(context, 'Agora Superstore', '20% Off Eco Reusable Line', '300 Tokens', 'AGORA-PLASTIC-20', Colors.orange),
      ],
    );
  }

  Widget _buildCouponCard(BuildContext context, String brand, String title, String cost, String code, Color brandColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: brandColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(brand, style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.subtle, borderRadius: BorderRadius.circular(20)),
                  child: Text(cost, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Promo Code: $code', style: const TextStyle(color: AppTheme.muted, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryLight),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Redeemed $brand voucher! Code: $code')),
                  );
                },
                child: const Text('Redeem Voucher'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
