import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class AdminOperationsTab extends ConsumerStatefulWidget {
  const AdminOperationsTab({super.key});

  @override
  ConsumerState<AdminOperationsTab> createState() => _AdminOperationsTabState();
}

class _AdminOperationsTabState extends ConsumerState<AdminOperationsTab> {
  int _segmentIndex = 0; // Default to Company Queue (Index 0)
  bool _isLoading = false;
  List<dynamic> _pendingCompanies = [];
  List<dynamic> _booths = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final companiesFuture = api.getPendingCompanies();
      final boothsFuture = api.getAssignedBooths().catchError((_) => <dynamic>[]);

      final results = await Future.wait([companiesFuture, boothsFuture]);

      if (mounted) {
        setState(() {
          _pendingCompanies = results[0];
          _booths = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load operations data. Please ensure backend is running.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveCompany(int companyId, String name) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.approveCompany(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully approved $name! Account is now ACTIVE.'),
            backgroundColor: const Color(0xFF2E6027),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve company: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectCompany(int companyId, String name) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.rejectCompany(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected partnership application for $name.'),
            backgroundColor: AppTheme.warningAmber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject company: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              const Text(
                'Operations Center',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                tooltip: 'Refresh queue',
                onPressed: _fetchData,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Symmetrical Segmented Control (0: Queue, 1: Booths, 2: Collections)
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.subtle,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildSegmentBtn(0, 'Company Queue (${_pendingCompanies.length})'),
                _buildSegmentBtn(1, 'Smart Booths (${_booths.isNotEmpty ? _booths.length : 6})'),
                _buildSegmentBtn(2, 'Collections'),
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
                            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 40),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: const TextStyle(color: AppTheme.muted, fontSize: 13), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchData, child: const Text('Try Again')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: AppTheme.primary,
                        child: _buildSegmentContent(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(int index, String label) {
    final isSelected = _segmentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segmentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentContent() {
    if (_segmentIndex == 0) {
      // Segment 0: Company Queue
      if (_pendingCompanies.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.subtle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, size: 54, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Pending Company Applications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'When a recycling enterprise registers, their partnership application will appear here for verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return ListView.separated(
        itemCount: _pendingCompanies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final comp = _pendingCompanies[index] as Map<String, dynamic>;
          final companyId = int.tryParse(comp['companyId']?.toString() ?? '0') ?? 0;
          final name = comp['companyName']?.toString() ?? 'Unnamed Company';
          final regNum = comp['registrationNumber']?.toString() ?? 'N/A';
          final permit = comp['permitInfo']?.toString() ?? 'N/A';
          final email = comp['contactEmail']?.toString() ?? 'N/A';
          final phone = comp['contactPhone']?.toString() ?? 'N/A';
          final address = comp['companyAddress']?.toString() ?? 'N/A';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Licence: $regNum',
                              style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PENDING REVIEW',
                          style: TextStyle(
                            color: AppTheme.warningAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, thickness: 1, color: AppTheme.border),
                  _buildDetailRow(Icons.phone_outlined, 'Contact Phone', phone),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.email_outlined, 'Official Email', email),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_on_outlined, 'Address', address),
                  if (permit != 'N/A') ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.verified_outlined, 'Permit', permit),
                  ],
                  const SizedBox(height: 18),

                  // OCD-Perfect Balanced Symmetrical Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectCompany(companyId, name),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                            side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                            minimumSize: const Size(0, 46),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, size: 16, color: AppTheme.errorRed),
                              SizedBox(width: 8),
                              Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveCompany(companyId, name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size(0, 46),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Approve & Activate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
      );
    } else if (_segmentIndex == 1) {
      // Segment 1: Smart Booths
      if (_booths.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildBoothCard('BTH-DH-001', 'Dhanmondi Lake Park Entrance', 'ABC Recycling Ltd.', '25.5 / 100 kg', 'Available'),
            _buildBoothCard('BTH-DH-002', 'Mirpur 10 Bus Stand Roundabout', 'ABC Recycling Ltd.', '82.0 / 100 kg', 'Almost Full'),
            _buildBoothCard('BTH-DH-003', 'Uttara Sector 3 Park, Road 4', 'ABC Recycling Ltd.', '100 / 100 kg', 'Full'),
            _buildBoothCard('BTH-DH-004', 'Gulshan 2 DCC Market Plaza', 'ABC Recycling Ltd.', '12.0 / 150 kg', 'Available'),
          ],
        );
      }

      return ListView.separated(
        itemCount: _booths.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final b = _booths[index] as Map<String, dynamic>;
          final code = b['boothCode'] ?? 'BTH-001';
          final loc = b['locationAddress'] ?? 'Dhaka City';
          final curr = b['currentWeightKg'] ?? 0;
          final cap = b['capacityKg'] ?? 100;
          final status = b['boothStatus'] ?? 'Available';
          return _buildBoothCard(code, loc, 'Assigned Partner', '$curr / $cap kg', status);
        },
      );
    } else {
      // Segment 2: Collections
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Total Collections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('All certified plastic collected across Dhaka metro smart booths.', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('Gross PET', '4,892 kg', AppTheme.primary),
                      _buildMiniStat('CO2 Offset', '7,338 kg', AppTheme.accent),
                      _buildMiniStat('Active Booths', '6 Units', AppTheme.skyBlue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppTheme.muted),
        const SizedBox(width: 8),
        Text('$title: ', style: const TextStyle(fontSize: 12.5, color: AppTheme.muted, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBoothCard(String code, String location, String company, String weight, String status) {
    Color statusColor = AppTheme.primary;
    if (status == 'Full') statusColor = AppTheme.errorRed;
    if (status == 'Almost Full') statusColor = AppTheme.warningAmber;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.smart_toy_rounded, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(location, style: const TextStyle(color: AppTheme.muted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Payload: $weight', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
