import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class PickupRequestsTab extends ConsumerStatefulWidget {
  const PickupRequestsTab({super.key});

  @override
  ConsumerState<PickupRequestsTab> createState() => _PickupRequestsTabState();
}

class _PickupRequestsTabState extends ConsumerState<PickupRequestsTab> {
  final _api = AuthService();
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _error;
  int? _workingRequest;

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
      final values = await Future.wait([
        _api.fetchCompanyPickups(token),
        _api.fetchCompanyVehicles(token),
      ]);
      if (!mounted) return;
      setState(() {
        _requests = _maps(values[0]);
        _vehicles = _maps(values[1]);
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not load company pickup requests.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _maps(dynamic rows) => (rows as List<dynamic>)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  @override
  Widget build(BuildContext context) {
    final active =
        _requests.where((request) => request['status'] != 'Completed').toList();
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
                  Text('Pickup requests',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      '${active.length} open requests  ·  ${_vehicles.where((vehicle) => vehicle['status'] == 'Available').length} vehicles available',
                      style: const TextStyle(color: AppTheme.muted)),
                ])),
            IconButton(
                onPressed: _load,
                tooltip: 'Refresh pickup requests',
                icon: const Icon(Icons.refresh_rounded)),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            _errorState()
          else if (_requests.isEmpty)
            const _EmptyPickupState('No pickup requests for this company yet.')
          else
            ..._requests.map(_requestCard),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final status = request['status']?.toString() ?? 'Pending';
    final completed = status == 'Completed';
    final assigned = request['vehicleId'] != null;
    final priority = request['priority']?.toString() ?? 'NORMAL';
    final color = completed
        ? AppTheme.primary
        : priority == 'HIGH'
            ? AppTheme.errorRed
            : AppTheme.warningAmber;
    final requestId = (request['requestId'] as num).toInt();
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(request['requestCode']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800))),
            _PickupBadge(status, color: color),
          ]),
          const SizedBox(height: 7),
          Text(
              '${request['boothCode'] ?? 'Booth'}  ·  ${request['payloadKg'] ?? 0} kg',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(request['locationAddress']?.toString() ?? '',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          if (assigned) ...[
            const SizedBox(height: 5),
            Text('Vehicle  ${request['vehicleNumber'] ?? 'Assigned'}',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ],
          if (!completed) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 7, children: [
              if (status == 'Pending')
                OutlinedButton.icon(
                    onPressed: _workingRequest == requestId
                        ? null
                        : () => _accept(requestId),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accept')),
              if (!assigned)
                FilledButton.icon(
                    onPressed: _workingRequest == requestId
                        ? null
                        : () => _assign(requestId),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Assign vehicle')),
              if (assigned)
                FilledButton.icon(
                    onPressed: _workingRequest == requestId
                        ? null
                        : () => _complete(requestId),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Complete collection')),
            ]),
          ] else ...[
            const SizedBox(height: 8),
            Text('Completed ${_date(request['completedAt'])}',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }

  Future<void> _accept(int requestId) async => _runAction(
        requestId,
        () => _api.acceptCompanyPickup(ref.read(authTokenProvider), requestId),
        'Pickup request accepted.',
      );

  Future<void> _assign(int requestId) async {
    final available =
        _vehicles.where((vehicle) => vehicle['status'] == 'Available').toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'No available vehicles. Add or release a company vehicle first.')));
      return;
    }
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
            const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Select an available vehicle',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            ...available.map((vehicle) => ListTile(
                  leading: const Icon(Icons.local_shipping_outlined,
                      color: AppTheme.primary),
                  title:
                      Text(vehicle['vehicle_number']?.toString() ?? 'Vehicle'),
                  subtitle: Text(
                      '${vehicle['vehicle_type'] ?? ''}  ·  ${vehicle['driver_name'] ?? ''}'),
                  onTap: () => Navigator.pop(
                      context, (vehicle['vehicle_id'] as num).toInt()),
                )),
          ])),
    );
    if (selected == null) return;
    await _runAction(
      requestId,
      () => _api.assignCompanyVehicle(
          ref.read(authTokenProvider), requestId, selected),
      'Vehicle assigned to pickup.',
    );
  }

  Future<void> _complete(int requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete collection?'),
        content: const Text(
            'This will record the collected booth weight and add it to your company history and the admin collections report.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(
      requestId,
      () => _api.completeCompanyPickup(ref.read(authTokenProvider), requestId),
      'Collection recorded successfully.',
    );
  }

  Future<void> _runAction(
      int requestId, Future<void> Function() action, String success) async {
    setState(() => _workingRequest = requestId);
    try {
      await action();
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Pickup could not be updated. Refresh and try again.')));
    } finally {
      if (mounted) setState(() => _workingRequest = null);
    }
  }

  Widget _errorState() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: AppTheme.muted)),
        TextButton(onPressed: _load, child: const Text('Retry'))
      ]));

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null
        ? ''
        : DateFormat('MMM d, y').format(parsed.toLocal());
  }
}

class _PickupBadge extends StatelessWidget {
  const _PickupBadge(this.label, {required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5)),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)));
}

class _EmptyPickupState extends StatelessWidget {
  const _EmptyPickupState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted))));
}
