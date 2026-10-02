import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class AdminDashboardTab extends ConsumerStatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  final _api = AuthService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _metrics = {};
  List<dynamic> _activity = [];

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
      final results = await Future.wait([
        _api.fetchAdminMetrics(token),
        _api.fetchAdminActivity(token),
      ]);
      if (!mounted) return;
      setState(() {
        _metrics = results[0] as Map<String, dynamic>;
        _activity = results[1] as List<dynamic>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not load platform data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform overview',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Live totals from Greenify operations',
                        style: TextStyle(color: AppTheme.muted)),
                  ],
                ),
              ),
              IconButton(
                  onPressed: _load,
                  tooltip: 'Refresh data',
                  icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          const SizedBox(height: 18),
          if (_error != null) _ErrorBanner(message: _error!, onRetry: _load),
          if (_loading && _metrics.isEmpty)
            const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()))
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 640 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 4 ? 1.55 : 1.5,
                  children: [
                    _MetricTile(
                        label: 'Registered users',
                        value: _integer(_metrics['totalUsers']),
                        icon: Icons.people_alt_rounded,
                        tint: AppTheme.primary),
                    _MetricTile(
                        label: 'Plastic collected',
                        value:
                            '${_decimal(_metrics['totalPlasticCollectedKg'])} kg',
                        icon: Icons.recycling_rounded,
                        tint: AppTheme.accent),
                    _MetricTile(
                        label: 'Tokens issued',
                        value: _integer(_metrics['totalTokensIssued']),
                        icon: Icons.stars_rounded,
                        tint: AppTheme.warningAmber),
                    _MetricTile(
                        label: 'Cashback paid',
                        value: _money(_metrics['totalCashbackTaka']),
                        icon: Icons.account_balance_wallet_rounded,
                        tint: AppTheme.skyBlue),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _sectionHeading(
                'Recent platform activity', '${_activity.length} events'),
            const SizedBox(height: 8),
            if (_activity.isEmpty)
              const _EmptyState(
                  message:
                      'New registrations, deposits, collections, and withdrawals will appear here.')
            else
              ..._activity.map((raw) =>
                  _ActivityRow(item: Map<String, dynamic>.from(raw as Map))),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String trailing) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800))),
          Text(trailing,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ],
      );

  String _integer(dynamic value) =>
      NumberFormat('#,##0').format((value as num?) ?? 0);
  String _decimal(dynamic value) =>
      NumberFormat('#,##0.0').format((value as num?) ?? 0);
  String _money(dynamic value) =>
      '৳${NumberFormat('#,##0.00').format((value as num?) ?? 0)}';
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.tint});

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(icon, color: tint, size: 19),
                  const Spacer(),
                  Container(
                      width: 7,
                      height: 7,
                      decoration:
                          BoxDecoration(color: tint, shape: BoxShape.circle))
                ]),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
      );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final kind = item['activityType'] as String? ?? '';
    final icon = switch (kind) {
      'user' => Icons.person_add_alt_1_rounded,
      'deposit' => Icons.recycling_rounded,
      'cashback' => Icons.account_balance_wallet_rounded,
      'company' => Icons.apartment_rounded,
      'collection' => Icons.local_shipping_rounded,
      _ => Icons.bolt_rounded,
    };
    final time = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppTheme.subtle, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: AppTheme.primary, size: 19)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['title']?.toString() ?? 'Platform activity',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(item['description']?.toString() ?? '',
              style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
        ])),
        const SizedBox(width: 8),
        Text(
            time == null
                ? ''
                : DateFormat('MMM d, HH:mm').format(time.toLocal()),
            style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted))),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading:
              Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          title: Text(message),
          trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      );
}
