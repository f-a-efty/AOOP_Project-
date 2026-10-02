import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class CollectionHistoryTab extends ConsumerStatefulWidget {
  const CollectionHistoryTab({super.key});

  @override
  ConsumerState<CollectionHistoryTab> createState() =>
      _CollectionHistoryTabState();
}

class _CollectionHistoryTabState extends ConsumerState<CollectionHistoryTab> {
  final _api = AuthService();
  List<Map<String, dynamic>> _collections = [];
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
      final rows =
          await _api.fetchCompanyCollections(ref.read(authTokenProvider));
      if (!mounted) return;
      setState(() => _collections =
          rows.map((row) => Map<String, dynamic>.from(row as Map)).toList());
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not load completed collections.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _collections.fold<double>(0,
        (sum, item) => sum + ((item['netWeightKg'] as num?)?.toDouble() ?? 0));
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
                    Text('Collection history',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Completed booth pickups',
                        style: TextStyle(color: AppTheme.muted)),
                  ])),
              IconButton(
                  onPressed: _load,
                  tooltip: 'Refresh history',
                  icon: const Icon(Icons.refresh_rounded)),
            ]),
            const SizedBox(height: 14),
            Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: AppTheme.subtle,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                      child:
                          Text('${_collections.length} completed collections')),
                  Text('${total.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w800))
                ])),
            const SizedBox(height: 13),
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
            else if (_collections.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('Completed pickups will appear here.',
                          style: TextStyle(color: AppTheme.muted))))
            else
              ..._collections.map((collection) {
                final date = DateTime.tryParse(
                    collection['collectedAt']?.toString() ?? '');
                final weight =
                    (collection['netWeightKg'] as num?)?.toDouble() ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE5F1E9),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.check_rounded,
                            color: AppTheme.primary)),
                    title: Text(
                        '${collection['boothCode']}  ·  ${weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        '${collection['locationAddress'] ?? ''}\n${collection['requestCode'] ?? ''}  ·  ${collection['plasticGrade'] ?? 'Sorted plastic'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                    trailing: Text(
                        date == null
                            ? ''
                            : DateFormat('MMM d, y').format(date.toLocal()),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.muted)),
                  ),
                );
              }),
          ]),
    );
  }
}
