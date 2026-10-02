import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class AdminFinanceTab extends ConsumerStatefulWidget {
  const AdminFinanceTab({super.key});

  @override
  ConsumerState<AdminFinanceTab> createState() => _AdminFinanceTabState();
}

class _AdminFinanceTabState extends ConsumerState<AdminFinanceTab> {
  final _api = AuthService();
  bool _loading = true;
  String? _error;
  Map<String, String> _rules = {};
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = ref.read(authTokenProvider);
      final results = await Future.wait(
          [_api.fetchEconomics(token), _api.fetchAdminCoupons(token)]);
      if (!mounted) return;
      setState(() {
        _rules = {
          for (final item in results[0])
            (item as Map)['configKey'].toString():
                (item)['configValue'].toString()
        };
        _coupons = results[1]
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load finance settings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokensPerKg = _rule('tokens_per_kg', '100');
    final tokensPerTaka = _rule('tokens_per_taka', '4');
    final minimumTaka = _rule('min_withdrawal_taka', '100');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Finance & rewards',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Reward rates and partner vouchers',
                        style: TextStyle(color: AppTheme.muted)),
                  ])),
              IconButton(
                  onPressed: _load,
                  tooltip: 'Refresh finance',
                  icon: const Icon(Icons.refresh_rounded)),
            ]),
            const SizedBox(height: 16),
            if (_error != null) _errorBanner(),
            if (_loading && _rules.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()))
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: AppTheme.subtle,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.tune_rounded,
                                  color: AppTheme.primary)),
                          const SizedBox(width: 10),
                          const Expanded(
                              child: Text('Active reward rules',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800))),
                          IconButton(
                              onPressed: _editRules,
                              tooltip: 'Edit reward rules',
                              icon: const Icon(Icons.edit_outlined)),
                        ]),
                        const SizedBox(height: 15),
                        _ruleRow('Plastic reward', '$tokensPerKg tokens / kg'),
                        _ruleRow('Cashback conversion',
                            '$tokensPerTaka tokens = ৳1'),
                        _ruleRow('Minimum withdrawal', '৳$minimumTaka'),
                      ]),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: Text('Partner coupons',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800))),
                FilledButton.icon(
                    onPressed: () => _editCoupon(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add coupon')),
              ]),
              const SizedBox(height: 10),
              if (_coupons.isEmpty)
                const _EmptyCoupons()
              else
                ..._coupons.map(_couponCard),
            ],
          ]),
    );
  }

  String _rule(String key, String fallback) => _rules[key] ?? fallback;

  Widget _ruleRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppTheme.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800))
        ]),
      );

  Widget _couponCard(Map<String, dynamic> coupon) {
    final expiry = DateTime.tryParse(coupon['expiryDate']?.toString() ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF1DC),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.confirmation_number_outlined,
                color: AppTheme.warningAmber)),
        title: Text(coupon['brandName']?.toString() ?? 'Partner',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            '${coupon['promoCode']}  ·  ${coupon['discountPercentage']}% off\n${coupon['tokenCost']} tokens  ·  ${coupon['quantityAvailable']} available${expiry == null ? '' : '  ·  expires ${DateFormat('MMM d, y').format(expiry.toLocal())}'}',
            maxLines: 2),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          tooltip: 'Coupon actions',
          onSelected: (action) => action == 'edit'
              ? _editCoupon(coupon: coupon)
              : _archiveCoupon(coupon),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit coupon')),
            PopupMenuItem(value: 'archive', child: Text('Archive coupon')),
          ],
        ),
      ),
    );
  }

  Future<void> _editRules() async {
    final tokens = TextEditingController(text: _rule('tokens_per_kg', '100'));
    final conversion =
        TextEditingController(text: _rule('tokens_per_taka', '4'));
    final minimum =
        TextEditingController(text: _rule('min_withdrawal_taka', '100'));
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit reward rules'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _numberField(tokens, 'Tokens per kilogram'),
          _numberField(conversion, 'Tokens per ৳1'),
          _numberField(minimum, 'Minimum withdrawal (৳)'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(
                  context, [tokens.text, conversion.text, minimum.text]),
              child: const Text('Save rules')),
        ],
      ),
    );
    if (result != null) {
      try {
        final token = ref.read(authTokenProvider);
        await _api.updateEconomics(token, 'tokens_per_kg', result[0]);
        await _api.updateEconomics(token, 'tokens_per_taka', result[1]);
        await _api.updateEconomics(token, 'min_withdrawal_taka', result[2]);
        await _load();
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Reward rules could not be saved.')));
      }
    }
    tokens.dispose();
    conversion.dispose();
    minimum.dispose();
  }

  Widget _numberField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: label)),
      );

  Future<void> _editCoupon({Map<String, dynamic>? coupon}) async {
    final brand =
        TextEditingController(text: coupon?['brandName']?.toString() ?? '');
    final code =
        TextEditingController(text: coupon?['promoCode']?.toString() ?? '');
    final discount = TextEditingController(
        text: coupon?['discountPercentage']?.toString() ?? '10');
    final cost =
        TextEditingController(text: coupon?['tokenCost']?.toString() ?? '100');
    final quantity = TextEditingController(
        text: coupon?['quantityAvailable']?.toString() ?? '50');
    final expiry = TextEditingController(
        text: coupon?['expiryDate']?.toString().substring(0, 10) ??
            DateFormat('yyyy-MM-dd')
                .format(DateTime.now().add(const Duration(days: 90))));
    final terms = TextEditingController(
        text: coupon?['termsAndConditions']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            coupon == null ? 'Create partner coupon' : 'Edit partner coupon'),
        content: SizedBox(
            width: 420,
            child: Form(
                key: formKey,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _textField(brand, 'Brand name'),
                  _textField(code, 'Promo code'),
                  Row(children: [
                    Expanded(
                        child:
                            _textField(discount, 'Discount %', numeric: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _textField(cost, 'Token cost', numeric: true))
                  ]),
                  Row(children: [
                    Expanded(
                        child: _textField(quantity, 'Quantity', numeric: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _textField(expiry, 'Expiry (YYYY-MM-DD)'))
                  ]),
                  _textField(terms, 'Terms and conditions'),
                ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, {
                  'brandName': brand.text.trim(),
                  'promoCode': code.text.trim(),
                  'discountPercentage': int.parse(discount.text),
                  'tokenCost': int.parse(cost.text),
                  'quantityAvailable': int.parse(quantity.text),
                  'expiryDate': '${expiry.text} 23:59:59',
                  'termsAndConditions': terms.text.trim(),
                });
              },
              child: const Text('Save coupon'))
        ],
      ),
    );
    if (body != null) {
      try {
        await _api.saveAdminCoupon(ref.read(authTokenProvider), body,
            couponId: (coupon?['couponId'] as num?)?.toInt());
        await _load();
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Coupon could not be saved. Promo codes must be unique.')));
      }
    }
    for (final controller in [
      brand,
      code,
      discount,
      cost,
      quantity,
      expiry,
      terms
    ]) {
      controller.dispose();
    }
  }

  Widget _textField(TextEditingController controller, String label,
          {bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            if (numeric && int.tryParse(value) == null)
              return 'Enter a whole number';
            return null;
          },
        ),
      );

  Future<void> _archiveCoupon(Map<String, dynamic> coupon) async {
    try {
      await _api.archiveAdminCoupon(
          ref.read(authTokenProvider), (coupon['couponId'] as num).toInt());
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon could not be archived.')));
    }
  }

  Widget _errorBanner() => Material(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: AppTheme.errorRed),
          title: Text(_error!),
          trailing: TextButton(onPressed: _load, child: const Text('Retry')),
        ),
      );
}

class _EmptyCoupons extends StatelessWidget {
  const _EmptyCoupons();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
          child: Text('No partner coupons yet.',
              style: TextStyle(color: AppTheme.muted))));
}
