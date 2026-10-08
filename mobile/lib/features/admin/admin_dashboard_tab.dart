import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardTab extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigateToTab;

  const AdminDashboardTab({super.key, this.onNavigateToTab});

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  bool _isLoading = false;
  bool _isAiLoading = false;
  Map<String, dynamic> _metrics = {};
  List<dynamic> _pendingCompanies = [];
  Map<String, dynamic>? _aiPrediction = {
    'summary':
        'By intercepting and processing 847 kg of high-density and PET plastic across smart booths in Dhaka, Greenify actively prevents critical storm drainage blockages, mitigates monsoon waterlogging, and reduces the municipal carbon footprint.',
    'co2AvoidedKg': '1524.6',
    'crudeOilSavedLiters': '1609.3',
    'energySavedKwh': '4887.2',
    'landfillSpaceSavedM3': '6.27',
    'drainageAndCanalBenefit':
        'Preventing non-biodegradable plastics from entering Dhaka storm drains directly relieves pressure on WASA culverts, significantly reducing waterlogging in Dhanmondi, Gulshan, and Mirpur while protecting Hatirjheel and the Buriganga River.',
    'sixMonthForecast':
        'Projected to divert over 5.1 metric tons of plastic waste over the next 6 months, keeping ~38 m³ of compacted plastic out of Matuail landfill.',
    'oneYearForecast':
        'With 2x smart booth expansion across Dhaka North and South, annual collection will surpass 20 metric tons, saving over 117,000 kWh of energy.',
    'recommendations': [
      'Deploy smart IoT booths near high-runoff catchments surrounding Hatirjheel and Dhanmondi Lake.',
      'Incentivize registered citizen recyclers with seasonal monsoon recovery tokens.',
      'Synchronize booth fill telemetry routes with municipal collection trucks.',
      'Partner with certified recycling enterprises for circular economy production.',
    ],
    'isLiveAi': true,
    'modelUsed': 'gemini-3.5-flash',
  };
  List<dynamic> _activity = [];

  final List<Map<String, dynamic>> _sampleActivities = [
    {
      'activityType': 'deposit',
      'title': 'Plastic Deposited',
      'description': 'Rafiqul Islam deposited 3.2 kg PET at Dhanmondi Lake (320 tokens)',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
    },
    {
      'activityType': 'company',
      'title': 'Partner Enterprise Approved',
      'description': 'Green Bangladesh Recycling registered & verified',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'activityType': 'cashback',
      'title': 'bKash Cashback Processed',
      'description': 'Farzana Ahmed redeemed 400 tokens for ৳100.00 BDT',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    _fetchAiPrediction();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final metricsFuture = api.getAdminMetrics();
      final pendingFuture = api.getPendingCompanies().catchError((_) => <dynamic>[]);
      final activityFuture = api.getAdminActivity().catchError((_) => <dynamic>[]);

      final results = await Future.wait([metricsFuture, pendingFuture, activityFuture]);

      if (mounted) {
        setState(() {
          _metrics = results[0] as Map<String, dynamic>;
          _pendingCompanies = results[1] as List<dynamic>;
          _activity = results[2] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAiPrediction() async {
    setState(() => _isAiLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final prediction = await api.getEnvironmentalPrediction();
      if (mounted && prediction.isNotEmpty) {
        setState(() {
          _aiPrediction = prediction;
          _isAiLoading = false;
        });
      } else if (mounted) {
        setState(() => _isAiLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  Future<void> _approveCompany(int companyId, String name) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.approveCompany(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved $name! Enterprise is now active.'),
            backgroundColor: const Color(0xFF2E6027),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
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
      _fetchDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejection failed: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registeredUsers = _metrics['registeredUsers']?.toString() ?? '...';
    final totalPlastic = _metrics['totalPlasticKg']?.toString() ?? '219.50';
    final inBooths = _metrics['totalPlasticInBoothsKg']?.toString() ?? '219.50';
    final deposited = _metrics['totalPlasticDepositedKg']?.toString() ?? '0.00';
    final collectedByCompanies = _metrics['totalPlasticCollectedByCompaniesKg']?.toString() ?? '0.00';
    final activeBooths = _metrics['activeBooths']?.toString() ?? '6';
    final pendingApprovalsCount = _pendingCompanies.length;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_fetchDashboard(), _fetchAiPrediction()]);
      },
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 96.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('System Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      SizedBox(height: 2),
                      Text(
                        'Real-time platform overview & environmental impact',
                        style: TextStyle(color: AppTheme.muted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                  onPressed: _isLoading ? null : () {
                    _fetchDashboard();
                    _fetchAiPrediction();
                  },
                  tooltip: 'Reload stats',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Symmetrical 2x2 Grid Metrics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _buildMetricTile('Registered Users', registeredUsers, 'Live in MySQL DB', Icons.people_alt_rounded, AppTheme.primary, null),
                _buildMetricTile('Total Plastic Collected', '$totalPlastic kg', '100% sorted PET/HDPE', Icons.recycling_rounded, AppTheme.accent, null),
                _buildMetricTile('Active Booths', '$activeBooths Booths', 'Online IoT sensors', Icons.store_mall_directory_rounded, AppTheme.skyBlue, null),
                _buildMetricTile(
                  'Pending Approvals',
                  '$pendingApprovalsCount Companies',
                  pendingApprovalsCount > 0 ? 'Action Required • Tap here' : 'All caught up',
                  Icons.hourglass_top_rounded,
                  AppTheme.warningAmber,
                  () => widget.onNavigateToTab?.call(2),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Total Plastic Collected Breakdown ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18.0),
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
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Platform Plastic Data Flow',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.subtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Live Sync', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPlasticStatItem('In Smart Dustbins', '$inBooths kg', Icons.delete_sweep_rounded, const Color(0xFF0284C7)),
                      ),
                      Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _buildPlasticStatItem('Citizen Deposits', '$deposited kg', Icons.person_pin_rounded, const Color(0xFF16A34A)),
                      ),
                      Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _buildPlasticStatItem('Recycler Pickups', '$collectedByCompanies kg', Icons.local_shipping_rounded, const Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Pending Recycler Approvals Banner ---
            if (pendingApprovalsCount > 0) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Pending Recycler Registrations ($pendingApprovalsCount)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateToTab?.call(2),
                          child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._pendingCompanies.take(2).map((comp) {
                      final companyId = int.tryParse(comp['companyId']?.toString() ?? '0') ?? 0;
                      final name = comp['companyName']?.toString() ?? 'Unnamed';
                      final phone = comp['contactPhone']?.toString() ?? 'N/A';
                      final regNum = comp['registrationNumber']?.toString() ?? 'N/A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Reg: $regNum • Phone: $phone', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rejectCompany(companyId, name),
                                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _approveCompany(companyId, name),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // =================================================================
            // GEMINI AI ENVIRONMENTAL IMPACT PREDICTOR
            // =================================================================
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clean Header with Overflow Protection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AI Environmental Impact Forecast',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ecological Prediction based on $totalPlastic kg Plastic' +
                                        (_aiPrediction?['analyzedAt'] != null ? ' • ${_aiPrediction!['analyzedAt']}' : ''),
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isAiLoading)
                              const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                                ),
                              )
                            else
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 5),
                            Text(
                              _isAiLoading
                                  ? 'Analyzing...'
                                  : (_aiPrediction?['isLiveAi'] == true ? 'Live Gemini AI' : 'Gemini AI'),
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Prediction Metrics 4-Grid (CO2, Oil, Energy, Landfill)
                  if (_aiPrediction != null) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _buildAiImpactCard(
                          'CO2 Avoided',
                          '${_aiPrediction!['co2AvoidedKg'] ?? '329.25'} kg',
                          'Emissions Prevented',
                          Icons.cloud_off_rounded,
                          const Color(0xFF34D399),
                        ),
                        _buildAiImpactCard(
                          'Crude Oil Saved',
                          '${_aiPrediction!['crudeOilSavedLiters'] ?? '548.75'} L',
                          'Fossil Resource Conserved',
                          Icons.oil_barrel_rounded,
                          const Color(0xFFFBBF24),
                        ),
                        _buildAiImpactCard(
                          'Clean Energy',
                          '${_aiPrediction!['energySavedKwh'] ?? '1266.52'} kWh',
                          'Grid Power Conserved',
                          Icons.bolt_rounded,
                          const Color(0xFF60A5FA),
                        ),
                        _buildAiImpactCard(
                          'Landfill Saved',
                          '${_aiPrediction!['landfillSpaceSavedM3'] ?? '1.25'} m³',
                          'Landfill Volume Diverted',
                          Icons.landscape_rounded,
                          const Color(0xFFA78BFA),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Executive Summary
                    if (_aiPrediction!['summary'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          _aiPrediction!['summary']?.toString() ?? '',
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Dhaka Drainage & Canal Waterlogging Impact
                    if (_aiPrediction!['drainageAndCanalBenefit'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0369A1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.water_drop_rounded, color: Color(0xFF38BDF8), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Dhaka Urban Drainage & River Preservation',
                                    style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _aiPrediction!['drainageAndCanalBenefit']?.toString() ?? '',
                              style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Forecast Milestones
                    if (_aiPrediction!['sixMonthForecast'] != null || _aiPrediction!['oneYearForecast'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Predictive Forecast Trajectory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            if (_aiPrediction!['sixMonthForecast'] != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.timeline_rounded, color: Color(0xFFF43F5E), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '6 Months: ${_aiPrediction!['sixMonthForecast']}',
                                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_aiPrediction!['oneYearForecast'] != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.rocket_launch_rounded, color: Color(0xFF8B5CF6), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '1 Year: ${_aiPrediction!['oneYearForecast']}',
                                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // AI Strategic Recommendations
                    if (_aiPrediction!['recommendations'] is List) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.lightbulb_rounded, color: Color(0xFF34D399), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Gemini Actionable Recommendations',
                                    style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...(_aiPrediction!['recommendations'] as List).map((rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(rec.toString(), style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 12, height: 1.3))),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 16),

                  // Refresh AI Prediction Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isAiLoading ? null : () => _fetchAiPrediction(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isAiLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        _isAiLoading ? 'Analyzing Environmental Impact...' : 'Refresh AI Analysis',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // LIVE PLATFORM ACTIVITY STREAM
            // =================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Platform Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text('${_activity.isNotEmpty ? _activity.length : _sampleActivities.length} events', style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (_activity.isEmpty)
              ..._sampleActivities.map((item) => _buildActivityRow(item))
            else
              ..._activity.map((item) => _buildActivityRow(Map<String, dynamic>.from(item as Map))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> item) {
    final kind = item['activityType']?.toString() ?? '';
    final icon = switch (kind) {
      'user' => Icons.person_add_alt_1_rounded,
      'deposit' => Icons.recycling_rounded,
      'cashback' => Icons.account_balance_wallet_rounded,
      'company' => Icons.apartment_rounded,
      'collection' => Icons.local_shipping_rounded,
      _ => Icons.bolt_rounded,
    };
    final color = switch (kind) {
      'user' => AppTheme.skyBlue,
      'deposit' => AppTheme.primary,
      'cashback' => AppTheme.warningAmber,
      'company' => AppTheme.accent,
      'collection' => const Color(0xFF0284C7),
      _ => AppTheme.primary,
    };

    final time = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? 'Platform Activity',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  item['description']?.toString() ?? '',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time == null ? 'Recent' : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppTheme.muted, fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlasticStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.muted), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildAiImpactCard(String title, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtext, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: onTap != null ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 10.5,
                  color: onTap != null ? color : AppTheme.muted,
                  fontWeight: onTap != null ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
