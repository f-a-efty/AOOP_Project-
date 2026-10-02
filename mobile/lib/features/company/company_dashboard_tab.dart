import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class CompanyDashboardTab extends ConsumerStatefulWidget {
  const CompanyDashboardTab({super.key});

  @override
  ConsumerState<CompanyDashboardTab> createState() =>
      _CompanyDashboardTabState();
}

class _CompanyDashboardTabState extends ConsumerState<CompanyDashboardTab> {
  final _api = AuthService();
  Map<String, dynamic> _dashboard = {};
  List<Map<String, dynamic>> _booths = [];
  final Set<int> _dispatching = {};
  bool _loading = true;
  String? _error;

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
        _api.fetchCompanyDashboard(token),
        _api.fetchCompanyBooths(token),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _booths = (results[1] as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not load recycler operations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawBreakdown = _dashboard['boothStatusBreakdown'];
    final breakdown = rawBreakdown is Map
        ? Map<String, dynamic>.from(rawBreakdown)
        : <String, dynamic>{};
    final urgentBooths = _booths.where((booth) {
      return booth['boothStatus'] == 'Full' ||
          booth['boothStatus'] == 'Almost Full';
    }).toList();

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
                  const Text('Recycler workspace',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(
                    _dashboard['companyName']?.toString() ?? 'Your company',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ])),
            IconButton(
                onPressed: _load,
                tooltip: 'Refresh dashboard',
                icon: const Icon(Icons.refresh_rounded)),
          ]),
          const SizedBox(height: 18),
          if (_error != null) _errorBanner(),
          if (_loading && _dashboard.isEmpty)
            const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()))
          else ...[
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 4 ? 1.55 : 1.45,
                children: [
                  _Metric(
                      label: 'Assigned booths',
                      value: '${_dashboard['assignedBoothsCount'] ?? 0}',
                      icon: Icons.storefront_outlined,
                      color: AppTheme.primary),
                  _Metric(
                      label: 'Plastic collected',
                      value:
                          '${_number(_dashboard['totalPlasticCollectedKg'])} kg',
                      icon: Icons.recycling_rounded,
                      color: AppTheme.accent),
                  _Metric(
                      label: 'Pickup required',
                      value: '${_dashboard['pickupRequiredCount'] ?? 0}',
                      icon: Icons.local_shipping_outlined,
                      color: AppTheme.warningAmber),
                  _Metric(
                      label: 'This month',
                      value:
                          '${_number(_dashboard['thisMonthPlasticCollectedKg'])} kg',
                      icon: Icons.calendar_month_rounded,
                      color: AppTheme.skyBlue),
                ],
              );
            }),
            const SizedBox(height: 22),
            const Text('Booth fill status',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            _statusBreakdown(breakdown),
            const SizedBox(height: 22),
            Row(children: [
              const Expanded(
                  child: Text('Pickup required',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800))),
              Text('${urgentBooths.length} booths',
                  style: const TextStyle(
                      color: AppTheme.muted, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            if (urgentBooths.isEmpty)
              const _EmptyCompanyState(
                  'No assigned booths need collection right now.')
            else
              ...urgentBooths.map(_urgentBoothCard),
          ],
        ],
      ),
    );
  }

  Widget _statusBreakdown(Map<String, dynamic> counts) {
    const statuses = <String, Color>{
      'Available': AppTheme.primary,
      'Almost Full': AppTheme.warningAmber,
      'Full': AppTheme.errorRed,
      'Empty': AppTheme.muted,
      'Under Maintenance': AppTheme.skyBlue,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.entries
          .map((entry) => Container(
                constraints: const BoxConstraints(minWidth: 135),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(7)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: entry.value, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.muted))),
                  Text('${counts[entry.key] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ))
          .toList(),
    );
  }

  Widget _urgentBoothCard(Map<String, dynamic> booth) {
    final current = (booth['currentWeightKg'] as num?)?.toDouble() ?? 0;
    final capacity = (booth['capacityKg'] as num?)?.toDouble() ?? 100;
    final progress = capacity <= 0 ? 0.0 : (current / capacity).clamp(0.0, 1.0);
    final full = booth['boothStatus'] == 'Full';
    final color = full ? AppTheme.errorRed : AppTheme.warningAmber;
    final boothId = (booth['boothId'] as num).toInt();
    final requested =
        booth['pickupRequested'] == true || booth['pickupRequested'] == 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('${booth['boothCode']}  ·  ${booth['boothStatus']}',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, color: color))),
            Text(
                '${current.toStringAsFixed(1)} / ${capacity.toStringAsFixed(0)} kg',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 3),
          Text(booth['locationAddress']?.toString() ?? '',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          const SizedBox(height: 9),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress,
                  color: color,
                  backgroundColor: AppTheme.subtle,
                  minHeight: 7)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: requested || _dispatching.contains(boothId)
                  ? null
                  : () => _dispatch(boothId),
              icon: Icon(requested
                  ? Icons.schedule_rounded
                  : Icons.local_shipping_outlined),
              label: Text(requested
                  ? 'Pickup already requested'
                  : 'Request pickup dispatch'),
            ),
          ),
          if (requested && booth['pickupRequestCode'] != null)
            Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('Request ${booth['pickupRequestCode']}',
                    style:
                        const TextStyle(color: AppTheme.muted, fontSize: 11))),
        ]),
      ),
    );
  }

  Future<void> _dispatch(int boothId) async {
    setState(() => _dispatching.add(boothId));
    try {
      final request =
          await _api.requestCompanyPickup(ref.read(authTokenProvider), boothId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pickup ${request['requestCode']} dispatched.')));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Pickup request failed. Refresh to check for an existing request.')));
    } finally {
      if (mounted) setState(() => _dispatching.remove(boothId));
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

  double _number(dynamic value) => (value as num?)?.toDouble() ?? 0;
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
      );
}

class _EmptyCompanyState extends StatelessWidget {
  const _EmptyCompanyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted))));
}
