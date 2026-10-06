import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class PickupRequestsTab extends ConsumerStatefulWidget {
  const PickupRequestsTab({super.key});

  @override
  ConsumerState<PickupRequestsTab> createState() => _PickupRequestsTabState();
}

class _PickupRequestsTabState extends ConsumerState<PickupRequestsTab> {
  bool _isLoading = false;
  List<dynamic> _pickups = [];
  List<dynamic> _vehicles = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPickups();
  }

  Future<void> _fetchPickups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final pickupsFuture = api.getPickupRequests();
      final vehiclesFuture = api.getVehicles().catchError((_) => <dynamic>[]);

      final results = await Future.wait([pickupsFuture, vehiclesFuture]);

      if (mounted) {
        setState(() {
          _pickups = results[0];
          _vehicles = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load pickup requests.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptPickup(int pickupId, String code) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.acceptPickup(pickupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted pickup request $code!'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchPickups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _completePickup(int pickupId, String code) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.completePickup(pickupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pickup $code completed and logged in Collections!'),
            backgroundColor: const Color(0xFF166534),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchPickups();
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _pickups.indexWhere((p) => (p['requestId']?.toString() == pickupId.toString()));
          if (idx != -1) {
            _pickups[idx]['status'] = 'Completed';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pickup $code marked Completed!'),
            backgroundColor: const Color(0xFF166534),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAssignVehicleDialog(int pickupId, String code) {
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active fleet vehicles available.'),
          backgroundColor: AppTheme.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Vehicle to $code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select an available dispatch vehicle:', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
            const SizedBox(height: 12),
            ..._vehicles.map((v) {
              final vId = int.tryParse(v['vehicleId']?.toString() ?? '0') ?? 0;
              final plate = v['vehicleNumber'] ?? 'Unknown Vehicle';
              final type = v['vehicleType'] ?? 'Van';
              final driver = v['driverName'] ?? 'Assigned Driver';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.local_shipping_rounded, color: AppTheme.primary),
                  title: Text(plate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text('$type • Driver: $driver', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final api = ref.read(apiServiceProvider);
                      await api.assignVehicle(pickupId, vId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Assigned vehicle $plate to $code!'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      _fetchPickups();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Assigned vehicle $plate to $code!'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Active Pickup Feed (${_pickups.length})', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                tooltip: 'Refresh feed',
                onPressed: _fetchPickups,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Automated Fleet Dispatch Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.subtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.alt_route_rounded, color: AppTheme.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Real-time IoT smart booth telemetry triggers pickup dispatch alerts.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 36),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchPickups, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _pickups.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary, size: 48),
                                SizedBox(height: 10),
                                Text('No Pending Pickup Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                                SizedBox(height: 4),
                                Text('All assigned smart booths are currently within safe thresholds.', style: TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchPickups,
                            color: AppTheme.primary,
                            child: ListView.separated(
                              itemCount: _pickups.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final p = _pickups[index] as Map<String, dynamic>;
                                final reqId = int.tryParse(p['requestId']?.toString() ?? '0') ?? 0;
                                final reqCode = p['requestCode'] ?? 'REQ-000';
                                final booth = p['booth'] as Map<String, dynamic>? ?? {};
                                final boothCode = booth['boothCode'] ?? 'BTH-000';
                                final boothLoc = booth['locationAddress'] ?? 'Dhaka City';
                                final payload = p['payloadKgAtRequest'] ?? 0;
                                final priority = p['priority'] ?? 'NORMAL';
                                final status = p['status'] ?? 'Pending';

                                final isPending = status == 'Pending';
                                final isAccepted = status == 'Accepted';
                                final isHigh = priority == 'HIGH';

                                Color statusColor = AppTheme.warningAmber;
                                if (isHigh || status == 'URGENT') statusColor = AppTheme.errorRed;
                                if (isAccepted) statusColor = AppTheme.skyBlue;
                                if (status == 'Completed') statusColor = const Color(0xFF166534);

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(reqCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isHigh ? AppTheme.errorRed.withOpacity(0.12) : AppTheme.subtle,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    priority,
                                                    style: TextStyle(
                                                      color: isHigh ? AppTheme.errorRed : AppTheme.muted,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.muted),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '$boothCode • $boothLoc',
                                                style: const TextStyle(color: AppTheme.muted, fontSize: 12.5),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.scale_rounded, size: 15, color: AppTheme.muted),
                                            const SizedBox(width: 6),
                                            Text('Payload: $payload kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                          ],
                                        ),
                                        const SizedBox(height: 14),

                                        // Symmetrical Action Buttons
                                        if (status == 'Completed')
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: const Color(0xFF86EFAC)),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 18),
                                                SizedBox(width: 8),
                                                Text('Collection Completed & Recorded', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 13)),
                                              ],
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: isPending ? () => _acceptPickup(reqId, reqCode) : () => _showAssignVehicleDialog(reqId, reqCode),
                                                  style: OutlinedButton.styleFrom(
                                                    minimumSize: const Size(0, 44),
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Icon(isAccepted ? Icons.local_shipping_outlined : Icons.check_rounded, size: 16),
                                                      const SizedBox(width: 6),
                                                      Text(isAccepted ? 'Change Fleet' : 'Accept Request', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: isAccepted ? () => _completePickup(reqId, reqCode) : () => _showAssignVehicleDialog(reqId, reqCode),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isAccepted ? const Color(0xFF166534) : AppTheme.primary,
                                                    minimumSize: const Size(0, 44),
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Icon(isAccepted ? Icons.task_alt_rounded : Icons.local_shipping_outlined, size: 16, color: Colors.white),
                                                      const SizedBox(width: 6),
                                                      Text(isAccepted ? 'Complete & Collect' : 'Assign Fleet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
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
}
