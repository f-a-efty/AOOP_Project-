import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class SmartBoothsTab extends ConsumerStatefulWidget {
  const SmartBoothsTab({super.key});

  @override
  ConsumerState<SmartBoothsTab> createState() => _SmartBoothsTabState();
}

class _SmartBoothsTabState extends ConsumerState<SmartBoothsTab> {
  final _api = AuthService();
  List<Map<String, dynamic>> _booths = [];
  bool _loading = true;
  String? _error;
  final Set<int> _dispatching = {};

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
      final rows = await _api.fetchCompanyBooths(ref.read(authTokenProvider));
      if (!mounted) return;
      setState(() => _booths =
          rows.map((row) => Map<String, dynamic>.from(row as Map)).toList());
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load assigned booths.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _booths
        .where((booth) => booth['boothStatus'] != 'Under Maintenance')
        .length;
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
                  Text('Assigned booths',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${_booths.length} assigned  ·  $active operational',
                      style: const TextStyle(color: AppTheme.muted)),
                ])),
            IconButton(
                onPressed: _load,
                tooltip: 'Refresh booths',
                icon: const Icon(Icons.refresh_rounded)),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Center(
                child: Column(children: [
              Text(_error!, style: const TextStyle(color: AppTheme.muted)),
              TextButton(onPressed: _load, child: const Text('Retry'))
            ]))
          else if (_booths.isEmpty)
            const _EmptyBooths()
          else
            ..._booths.map(_boothCard),
        ],
      ),
    );
  }

  Widget _boothCard(Map<String, dynamic> booth) {
    final current = (booth['currentWeightKg'] as num?)?.toDouble() ?? 0;
    final capacity = (booth['capacityKg'] as num?)?.toDouble() ?? 100;
    final progress = capacity <= 0 ? 0.0 : (current / capacity).clamp(0.0, 1.0);
    final status = booth['boothStatus']?.toString() ?? 'Unknown';
    final color = status == 'Full'
        ? AppTheme.errorRed
        : status == 'Almost Full'
            ? AppTheme.warningAmber
            : status == 'Under Maintenance'
                ? AppTheme.muted
                : AppTheme.primary;
    final boothId = (booth['boothId'] as num).toInt();
    final requested =
        booth['pickupRequested'] == true || booth['pickupRequested'] == 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.sensors_rounded, color: color)),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(booth['boothCode']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(booth['locationAddress']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ])),
            Text(status,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 11)),
          ]),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(
                child: Text(
                    '${current.toStringAsFixed(1)} / ${capacity.toStringAsFixed(0)} kg',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.subtle,
                  color: color,
                  minHeight: 7)),
          const SizedBox(height: 8),
          Text(
              '${booth['sensorStatus'] ?? 'Sensor status unknown'}${booth['lastPickupDate'] == null ? '' : '  ·  Last pickup ${booth['lastPickupDate']}'}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
          if (current > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: requested || _dispatching.contains(boothId)
                      ? null
                      : () => _dispatch(boothId),
                  icon: Icon(requested
                      ? Icons.schedule_rounded
                      : Icons.local_shipping_outlined),
                  label: Text(
                      requested ? 'Pickup request active' : 'Request pickup'),
                )),
          ],
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pickup ${request['requestCode']} dispatched.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not dispatch pickup. It may already be active.')));
    } finally {
      if (mounted) setState(() => _dispatching.remove(boothId));
    }
  }
}

class _EmptyBooths extends StatelessWidget {
  const _EmptyBooths();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 35),
      child: Center(
          child: Text(
              'No booths are assigned to this company yet. Ask an administrator to assign a booth.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted))));
}
