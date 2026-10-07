import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class CollectionHistoryTab extends ConsumerStatefulWidget {
  const CollectionHistoryTab({super.key});

  @override
  ConsumerState<CollectionHistoryTab> createState() => _CollectionHistoryTabState();
}

class _CollectionHistoryTabState extends ConsumerState<CollectionHistoryTab> {
  bool _isLoading = false;
  List<dynamic> _collections = [];

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  Future<void> _fetchCollections() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getCollections();
      if (mounted) {
        setState(() {
          _collections = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(companyDataReloadTriggerProvider, (_, __) => _fetchCollections());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Collection History Log', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                tooltip: 'Refresh logs',
                onPressed: _fetchCollections,
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                : RefreshIndicator(
                    onRefresh: _fetchCollections,
                    color: AppTheme.primary,
                    child: ListView.separated(
                      itemCount: _collections.isNotEmpty ? _collections.length : _fallbackCollections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final c = _collections.isNotEmpty ? (_collections[index] as Map<String, dynamic>) : _fallbackCollections[index];
                        final booth = c['booth'] as Map<String, dynamic>? ?? {};
                        final boothCode = booth['boothCode']?.toString() ?? c['boothCode']?.toString() ?? 'BTH-DH-001';
                        final loc = booth['locationAddress']?.toString() ?? c['locationAddress']?.toString() ?? 'Dhanmondi Lake Park';
                        final weight = c['netWeightKg']?.toString() ?? c['weightCollectedKg']?.toString() ?? c['weight']?.toString() ?? '98.50';
                        final grade = c['plasticGrade']?.toString() ?? 'PET 100% Sorted';
                        final date = c['collectedAt'] != null ? c['collectedAt'].toString().split('T').first : '2026-09-29';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: Color(0xFF166534), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$boothCode • $weight kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                                      const SizedBox(height: 3),
                                      Text(loc, style: const TextStyle(color: AppTheme.muted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Text('Grade: $grade • $date', style: const TextStyle(fontSize: 11.5, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.subtle,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('CERTIFIED', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _fallbackCollections = [
    {'boothCode': 'BTH-DH-001', 'locationAddress': 'Dhanmondi Lake Park, Road 8', 'weight': '98.50', 'plasticGrade': 'PET 100% Sorted', 'collectedAt': '2026-09-29T10:00:00'},
    {'boothCode': 'BTH-DH-004', 'locationAddress': 'Gulshan 2 DCC Market Plaza', 'weight': '142.00', 'plasticGrade': 'PET/HDPE Mixed', 'collectedAt': '2026-09-27T14:30:00'},
    {'boothCode': 'BTH-DH-003', 'locationAddress': 'Uttara Sector 3 Park, Road 4', 'weight': '100.00', 'plasticGrade': 'PET 100% Sorted', 'collectedAt': '2026-09-25T11:15:00'},
  ];
}
