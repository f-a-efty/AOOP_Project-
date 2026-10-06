import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class SmartBoothsTab extends ConsumerStatefulWidget {
  const SmartBoothsTab({super.key});

  @override
  ConsumerState<SmartBoothsTab> createState() => _SmartBoothsTabState();
}

class _SmartBoothsTabState extends ConsumerState<SmartBoothsTab> {
  bool _isLoading = false;
  List<dynamic> _booths = [];
  int _viewMode = 0; // 0 = Map View, 1 = List View
  String _filterMode = 'ALL'; // 'ALL', 'URGENT', 'NEAREST'
  Map<String, dynamic>? _selectedBooth;
  final MapController _mapController = MapController();

  // Company Recycling Central Depot (Tejgaon Industrial Area, Dhaka)
  static const LatLng _depotLocation = LatLng(23.7600, 90.3900);

  @override
  void initState() {
    super.initState();
    _fetchBooths();
  }

  Future<void> _fetchBooths() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final booths = await api.getAssignedBooths();
      if (mounted) {
        setState(() {
          _booths = booths.isNotEmpty ? booths : _fallbackBooths;
          _isLoading = false;
          if (_booths.isNotEmpty) {
            _selectedBooth ??= _booths[0] as Map<String, dynamic>;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _booths = _fallbackBooths;
          _isLoading = false;
          _selectedBooth ??= _fallbackBooths[0];
        });
      }
    }
  }

  bool _isDispatching = false;

  Future<void> _handleDispatch(Map<String, dynamic> booth) async {
    final boothId = booth['boothId'] ?? booth['id'] ?? 1;
    final code = booth['boothCode']?.toString() ?? 'BTH';

    setState(() => _isDispatching = true);

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.dispatchBoothCollection(int.tryParse(boothId.toString()) ?? 1);

      if (mounted) {
        final collected = res['collectedKg'] ?? booth['currentWeightKg'] ?? 0;
        final vehicle = res['vehicleNumber'] ?? 'DH-TRUCK-01';

        setState(() {
          booth['currentWeightKg'] = 0.0;
          booth['boothStatus'] = 'Available';
          booth['_fillPct'] = 0.0;
          _selectedBooth = Map<String, dynamic>.from(booth);
        });

        _fetchBooths();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 26),
                SizedBox(width: 8),
                Text('Vehicle Deployed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup vehicle $vehicle has been successfully deployed to collect from $code.',
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Plastic Recovered:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF166534))),
                      Text('$collected kg', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF166534))),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deploy pickup: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isDispatching = false);
    }
  }

  // Haversine Distance in Kilometers
  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String _formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  List<Map<String, dynamic>> _getFilteredBooths() {
    final rawList = (_booths.isNotEmpty ? _booths : _fallbackBooths)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (var b in rawList) {
      final lat = (b['latitude'] as num?)?.toDouble() ?? 23.7461;
      final lng = (b['longitude'] as num?)?.toDouble() ?? 90.3742;
      b['_distanceKm'] = _calculateDistanceKm(_depotLocation.latitude, _depotLocation.longitude, lat, lng);

      final current = (b['currentWeightKg'] as num?)?.toDouble() ?? 0.0;
      final capacity = (b['capacityKg'] as num?)?.toDouble() ?? 100.0;
      b['_fillPct'] = capacity > 0 ? (current / capacity) * 100.0 : 0.0;
    }

    if (_filterMode == 'URGENT') {
      return rawList.where((b) => (b['_fillPct'] as double) >= 75.0).toList();
    } else if (_filterMode == 'NEAREST') {
      rawList.sort((a, b) => (a['_distanceKm'] as double).compareTo(b['_distanceKm'] as double));
      return rawList;
    }
    return rawList;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredBooths();

    return Column(
      children: [
        // Top Header & Mode Switcher
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dustbins & Smart Booths', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Dispatch Hub: Tejgaon (${filtered.length} locations)',
                            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                    tooltip: 'Refresh booths',
                    onPressed: _fetchBooths,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // View Mode Selector (Map View vs List View)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              icon: Icons.map_rounded,
                              label: 'Map View',
                              isSelected: _viewMode == 0,
                              onTap: () => setState(() => _viewMode = 0),
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              icon: Icons.view_list_rounded,
                              label: 'List View',
                              isSelected: _viewMode == 1,
                              onTap: () => setState(() => _viewMode = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter Menu
                  PopupMenuButton<String>(
                    initialValue: _filterMode,
                    onSelected: (mode) => setState(() => _filterMode = mode),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'ALL', child: Text('All Dustbins')),
                      const PopupMenuItem(value: 'URGENT', child: Text('Urgent (>=75% Full)')),
                      const PopupMenuItem(value: 'NEAREST', child: Text('Nearest First')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: _filterMode != 'ALL' ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list_rounded, size: 16, color: _filterMode != 'ALL' ? Colors.white : AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            _filterMode == 'URGENT' ? 'Urgent' : _filterMode == 'NEAREST' ? 'Nearest' : 'Filter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _filterMode != 'ALL' ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main Content: Interactive Map or List View
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
              : _viewMode == 0
                  ? _buildInteractiveMap(filtered)
                  : _buildListView(filtered),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.muted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMap(List<Map<String, dynamic>> booths) {
    return Stack(
      children: [
        // OpenStreetMap Layer via flutter_map
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(23.780887, 90.398000), // Dhaka Metro Center
            initialZoom: 12.2,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.greenify.mobile',
            ),

            // Markers Layer
            MarkerLayer(
              markers: [
                // 1. Recycler Central Depot Marker
                Marker(
                  point: _depotLocation,
                  width: 140,
                  height: 60,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Text('Dispatch Hub', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle),
                        child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),

                // 2. Dustbin / Smart Booth Markers with Fill Percentage Badges
                ...booths.map((b) {
                  final lat = (b['latitude'] as num?)?.toDouble() ?? 23.7461;
                  final lng = (b['longitude'] as num?)?.toDouble() ?? 90.3742;
                  final pct = (b['_fillPct'] as num?)?.toDouble() ?? 0.0;
                  final isSelected = _selectedBooth != null && _selectedBooth!['boothCode'] == b['boothCode'];

                  Color pinColor = const Color(0xFF15803D); // Green (<50%)
                  if (pct >= 80.0) {
                    pinColor = const Color(0xFFDC2626); // Red (>=80%)
                  } else if (pct >= 50.0) {
                    pinColor = const Color(0xFFD97706); // Amber (50-79%)
                  }

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 72,
                    height: 72,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedBooth = b);
                        _mapController.move(LatLng(lat, lng), 13.8);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Percentage Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: pinColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: pinColor.withValues(alpha: 0.4),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 1),
                          // Pin Icon
                          Icon(
                            Icons.delete_rounded,
                            color: pinColor,
                            size: isSelected ? 28 : 22,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Map Legend Indicator
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem(const Color(0xFFDC2626), '>=80%'),
                const SizedBox(width: 8),
                _buildLegendItem(const Color(0xFFD97706), '50-80%'),
                const SizedBox(width: 8),
                _buildLegendItem(const Color(0xFF15803D), '<50%'),
              ],
            ),
          ),
        ),

        // Selected Dustbin Proximity Callout Card
        if (_selectedBooth != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 92,
            child: _buildSelectedBoothCard(_selectedBooth!),
          ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildSelectedBoothCard(Map<String, dynamic> b) {
    final code = b['boothCode']?.toString() ?? 'BTH-DH-001';
    final loc = b['locationAddress']?.toString() ?? 'Dhaka City';
    final current = (b['currentWeightKg'] as num?)?.toDouble() ?? 0.0;
    final capacity = (b['capacityKg'] as num?)?.toDouble() ?? 100.0;
    final status = b['boothStatus']?.toString() ?? 'Available';
    final distKm = (b['_distanceKm'] as num?)?.toDouble() ?? 0.0;
    final pct = (capacity > 0 ? (current / capacity) : 0.0).clamp(0.0, 1.0);

    Color statusColor = const Color(0xFF166534);
    if (status == 'Full' || pct >= 0.8) {
      statusColor = AppTheme.errorRed;
    } else if (status == 'Almost Full' || pct >= 0.5) {
      statusColor = AppTheme.warningAmber;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_sweep_rounded, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                      Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ],
              ),
              // Proximity Distance Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded, color: AppTheme.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(distKm),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Address
          Text(loc, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),

          // Trash Fill Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.subtle,
              color: statusColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trash Fill: ${(pct * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: statusColor),
              ),
              Text(
                '${current.toStringAsFixed(1)} / ${capacity.toStringAsFixed(0)} kg',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dispatch Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _isDispatching ? null : () => _handleDispatch(b),
              icon: _isDispatching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.local_shipping_rounded, size: 16),
              label: Text(
                _isDispatching
                    ? 'Deploying Pickup Vehicle...'
                    : (pct >= 0.75 ? 'Deploy Priority Pickup Truck' : 'Deploy Routine Collection Truck'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pct >= 0.75 ? AppTheme.errorRed : AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> booths) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 96.0),
      itemCount: booths.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = booths[index];
        final code = b['boothCode']?.toString() ?? 'BTH-DH-001';
        final loc = b['locationAddress']?.toString() ?? 'Dhaka City';
        final current = (b['currentWeightKg'] as num?)?.toDouble() ?? 0.0;
        final capacity = (b['capacityKg'] as num?)?.toDouble() ?? 100.0;
        final status = b['boothStatus']?.toString() ?? 'Available';
        final distKm = (b['_distanceKm'] as num?)?.toDouble() ?? 0.0;
        final pct = (capacity > 0 ? (current / capacity) : 0.0).clamp(0.0, 1.0);

        Color statusColor = const Color(0xFF166534);
        if (status == 'Full' || pct >= 0.8) {
          statusColor = AppTheme.errorRed;
        } else if (status == 'Almost Full' || pct >= 0.5) {
          statusColor = AppTheme.warningAmber;
        } else if (status == 'Under Maintenance') {
          statusColor = Colors.grey;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.delete_rounded, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                      ],
                    ),
                    Row(
                      children: [
                        // Distance Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.subtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.near_me_rounded, size: 12, color: AppTheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                _formatDistance(distKm),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(loc, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.subtle,
                    color: statusColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fill Rate: ${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
                    Text('${current.toStringAsFixed(1)} / ${capacity.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _isDispatching ? null : () => _handleDispatch(b),
                    icon: const Icon(Icons.local_shipping_rounded, size: 15),
                    label: Text(
                      pct >= 0.75 ? 'Deploy Priority Pickup' : 'Deploy Collection Truck',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pct >= 0.75 ? AppTheme.errorRed : AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const List<Map<String, dynamic>> _fallbackBooths = [
    {
      'boothCode': 'BTH-DH-001',
      'locationAddress': 'Dhanmondi Lake Park Entrance, Road 8, Dhaka',
      'latitude': 23.7461,
      'longitude': 90.3742,
      'currentWeightKg': 25.5,
      'capacityKg': 100.0,
      'boothStatus': 'Available',
      'sensorStatus': 'Online'
    },
    {
      'boothCode': 'BTH-DH-002',
      'locationAddress': 'Mirpur 10 Bus Stand Roundabout, Dhaka',
      'latitude': 23.8069,
      'longitude': 90.3687,
      'currentWeightKg': 82.0,
      'capacityKg': 100.0,
      'boothStatus': 'Almost Full',
      'sensorStatus': 'Online'
    },
    {
      'boothCode': 'BTH-DH-003',
      'locationAddress': 'Uttara Sector 3 Park, Road 4, Dhaka',
      'latitude': 23.8690,
      'longitude': 90.3980,
      'currentWeightKg': 100.0,
      'capacityKg': 100.0,
      'boothStatus': 'Full',
      'sensorStatus': 'Online'
    },
    {
      'boothCode': 'BTH-DH-004',
      'locationAddress': 'Gulshan 2 DCC Market Plaza, Dhaka',
      'latitude': 23.7948,
      'longitude': 90.4143,
      'currentWeightKg': 12.0,
      'capacityKg': 150.0,
      'boothStatus': 'Available',
      'sensorStatus': 'Online'
    },
    {
      'boothCode': 'BTH-DH-005',
      'locationAddress': 'Banani Chairman Bari Bus Stop, Dhaka',
      'latitude': 23.7937,
      'longitude': 90.4047,
      'currentWeightKg': 0.0,
      'capacityKg': 100.0,
      'boothStatus': 'Empty',
      'sensorStatus': 'Online'
    },
    {
      'boothCode': 'BTH-DH-006',
      'locationAddress': 'Mohammadpur Town Hall Market, Dhaka',
      'latitude': 23.7588,
      'longitude': 90.3630,
      'currentWeightKg': 0.0,
      'capacityKg': 100.0,
      'boothStatus': 'Under Maintenance',
      'sensorStatus': 'Sensor Error'
    },
  ];
}
