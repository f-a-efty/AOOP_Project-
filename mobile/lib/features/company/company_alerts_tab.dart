import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class CompanyAlertsTab extends ConsumerStatefulWidget {
  const CompanyAlertsTab({super.key});

  @override
  ConsumerState<CompanyAlertsTab> createState() => _CompanyAlertsTabState();
}

class _CompanyAlertsTabState extends ConsumerState<CompanyAlertsTab> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  final List<Map<String, dynamic>> _sampleAlerts = [
    {
      'alertId': 101,
      'title': 'Booth Full Alert: BTH-DH-003',
      'message': 'BTH-DH-003 at Uttara Sector 3 Park has reached 100% capacity (100.0 kg). Immediate pickup dispatch required.',
      'category': 'Booth Full',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
    },
    {
      'alertId': 102,
      'title': 'High Fill Warning: BTH-DH-002',
      'message': 'BTH-DH-002 at Mirpur 10 has exceeded 82% capacity (82.5 kg). Route planning advised.',
      'category': 'Almost Full',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 1, minutes: 20)).toIso8601String(),
    },
    {
      'alertId': 103,
      'title': 'Collection Confirmed: REQ-DH-8010',
      'message': 'Pickup for BTH-DH-001 (Dhanmondi Lake) successfully cleared 98.5 kg sorted PET.',
      'category': 'Pickup',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.getCompanyAlerts();
      if (!mounted) return;

      if (raw.isNotEmpty) {
        setState(() {
          _alerts = raw.map((r) => Map<String, dynamic>.from(r as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _alerts = List.from(_sampleAlerts);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _alerts = List.from(_sampleAlerts);
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(Map<String, dynamic> alert) async {
    final alertId = (alert['alertId'] as num?)?.toInt();
    if (alertId == null) return;

    setState(() {
      alert['isRead'] = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      await api.markCompanyAlertRead(alertId);
    } catch (_) {
      // Ignored for sample items or offline
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((a) => a['isRead'] != true && a['isRead'] != 1).length;

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Operational Alerts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 3),
                    Text(
                      '$unreadCount unread • ${_alerts.length} total notifications',
                      style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                tooltip: 'Refresh alerts',
                onPressed: _loadAlerts,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (_alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: const [
                  Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.muted),
                  SizedBox(height: 12),
                  Text('No operational alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('All smart booths and pickup routes are operating normally.', style: TextStyle(color: AppTheme.muted, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ..._alerts.map(_buildAlertCard),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isRead = alert['isRead'] == true || alert['isRead'] == 1;
    final category = alert['category']?.toString() ?? 'System';
    final date = DateTime.tryParse(alert['createdAt']?.toString() ?? '');

    Color color = AppTheme.primary;
    IconData icon = Icons.notifications_active_rounded;

    if (category.toLowerCase().contains('full')) {
      color = AppTheme.errorRed;
      icon = Icons.warning_rounded;
    } else if (category.toLowerCase().contains('almost') || category.toLowerCase().contains('warning')) {
      color = AppTheme.warningAmber;
      icon = Icons.error_outline_rounded;
    } else if (category.toLowerCase().contains('pickup')) {
      color = const Color(0xFF0284C7);
      icon = Icons.local_shipping_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead ? AppTheme.border : color.withOpacity(0.4),
          width: isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isRead ? null : () => _markRead(alert),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alert['title']?.toString() ?? 'Operational Notice',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14.5,
                              color: isRead ? AppTheme.textDark : color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert['message']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isRead ? AppTheme.muted : const Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date != null ? DateFormat('MMM d, h:mm a').format(date.toLocal()) : 'Recent',
                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                        ),
                        if (!isRead)
                          GestureDetector(
                            onTap: () => _markRead(alert),
                            child: const Text(
                              'Mark as read',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
