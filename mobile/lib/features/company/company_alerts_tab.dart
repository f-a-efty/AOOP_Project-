import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class CompanyAlertsTab extends ConsumerStatefulWidget {
  const CompanyAlertsTab({super.key});

  @override
  ConsumerState<CompanyAlertsTab> createState() => _CompanyAlertsTabState();
}

class _CompanyAlertsTabState extends ConsumerState<CompanyAlertsTab> {
  final _api = AuthService();
  List<Map<String, dynamic>> _alerts = [];
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
      final rows = await _api.fetchCompanyAlerts(ref.read(authTokenProvider));
      if (!mounted) return;
      setState(() => _alerts =
          rows.map((row) => Map<String, dynamic>.from(row as Map)).toList());
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load company alerts.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _alerts.where((alert) => !_isRead(alert['isRead'])).length;
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
                  Text('Operational alerts',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('$unread unread  ·  ${_alerts.length} total',
                      style: const TextStyle(color: AppTheme.muted)),
                ])),
            IconButton(
                onPressed: _load,
                tooltip: 'Refresh alerts',
                icon: const Icon(Icons.refresh_rounded)),
          ]),
          const SizedBox(height: 12),
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
          else if (_alerts.isEmpty)
            const _EmptyAlerts()
          else
            ..._alerts.map(_alertCard),
        ],
      ),
    );
  }

  Widget _alertCard(Map<String, dynamic> alert) {
    final read = _isRead(alert['isRead']);
    final category = alert['category']?.toString() ?? 'System';
    final color = category.toLowerCase().contains('pickup')
        ? AppTheme.warningAmber
        : category.toLowerCase().contains('booth')
            ? AppTheme.skyBlue
            : AppTheme.primary;
    final date = DateTime.tryParse(alert['createdAt']?.toString() ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: read ? Colors.white : AppTheme.subtle,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.notifications_active_outlined, color: color)),
        title: Row(children: [
          Expanded(
              child: Text(alert['title']?.toString() ?? 'Operational update',
                  style: TextStyle(
                      fontWeight: read ? FontWeight.w600 : FontWeight.w800))),
          if (!read)
            Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppTheme.primary, shape: BoxShape.circle)),
        ]),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
                '${alert['message'] ?? ''}\n${date == null ? '' : DateFormat('MMM d, y · HH:mm').format(date.toLocal())}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis)),
        isThreeLine: true,
        onTap: read ? null : () => _markRead(alert),
      ),
    );
  }

  bool _isRead(dynamic value) => value == true || value == 1 || value == '1';

  Future<void> _markRead(Map<String, dynamic> alert) async {
    try {
      await _api.markCompanyAlertRead(
          ref.read(authTokenProvider), (alert['alertId'] as num).toInt());
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not mark alert as read.')));
    }
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
          child: Text('No operational alerts yet.',
              style: TextStyle(color: AppTheme.muted))));
}
