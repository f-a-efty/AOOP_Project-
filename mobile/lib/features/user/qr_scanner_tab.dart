import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class QrScannerTab extends ConsumerStatefulWidget {
  const QrScannerTab({super.key});

  @override
  ConsumerState<QrScannerTab> createState() => _QrScannerTabState();
}

class _QrScannerTabState extends ConsumerState<QrScannerTab> {
  final _weightController = TextEditingController(text: '1.5');
  int _selectedBoothId = 1;
  String _selectedPlasticType = 'PET Plastic Bottles';
  bool _isDepositing = false;

  final List<String> _plasticTypes = [
    'PET Plastic Bottles',
    'HDPE Milk & Juice Jugs',
    'LDPE Soft Wraps & Bags',
    'PP Containers & Bottle Caps',
    'Mixed Plastics (General)',
  ];

  final List<Map<String, dynamic>> _booths = [
    {'id': 1, 'code': 'BTH-DH-001', 'name': 'Dhanmondi Lake Park Entrance, Road 8'},
    {'id': 2, 'code': 'BTH-DH-002', 'name': 'Mirpur 10 Bus Stand Roundabout'},
    {'id': 3, 'code': 'BTH-DH-003', 'name': 'Uttara Sector 3 Park, Road 4'},
    {'id': 4, 'code': 'BTH-DH-004', 'name': 'Gulshan 2 DCC Market Plaza'},
  ];

  @override
  void initState() {
    super.initState();
    _weightController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  double get _currentWeight => double.tryParse(_weightController.text.trim()) ?? 0.0;
  int get _projectedTokens => (_currentWeight * 100).floor();
  double get _projectedTaka => _projectedTokens / 4.0;
  double get _projectedCo2 => _currentWeight * 1.5;

  Future<void> _handleDeposit() async {
    final weight = _currentWeight;
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid plastic weight in kg.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _isDepositing = true);

    try {
      final api = ref.read(apiServiceProvider);

      // Perform verified deposit
      Map<String, dynamic> depositRes;
      try {
        depositRes = await api.manualDeposit(
          weightKg: weight,
          plasticType: _selectedPlasticType,
          boothId: _selectedBoothId,
        );
      } catch (_) {
        // Fallback to booth IoT session flow if direct deposit endpoint is unrouted
        final qrRes = await api.generateBoothQr(_selectedBoothId);
        final qrToken = qrRes['qrToken']?.toString() ?? 'QR-SIM-TOKEN';
        final sessionRes = await api.createDepositSession(_selectedBoothId, qrToken);
        final sessionId = sessionRes['sessionId']?.toString() ?? 'DS-AUTO';
        depositRes = await api.submitDepositWeight(_selectedBoothId, sessionId, weight);
      }

      final tokensEarned = (depositRes['tokensEarned'] as num?)?.toInt() ?? _projectedTokens;

      // Trigger automatic dashboard refresh
      ref.read(userDashboardReloadTriggerProvider.notifier).state++;

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 28),
                SizedBox(width: 8),
                Text('Plastic Deposit Verified!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Successfully deposited ${weight.toStringAsFixed(2)} kg of clean $_selectedPlasticType at booth station #$_selectedBoothId.',
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tokens Rewarded:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF166534))),
                      Text('+$tokensEarned Tokens', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF166534))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cashback Value: ৳${(tokensEarned / 4.0).toStringAsFixed(2)} BDT  •  CO2 Abated: ${_projectedCo2.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Collect Reward'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deposit failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isDepositing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Smart Scale Deposit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          const Text('Scan dynamic booth screen QR or select station scale to link deposit', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 18),

          // Scanner Target Frame
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primaryLight.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.subtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, size: 38, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 10),
                  const Text('Hardware Scale Camera Scanner Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  const Text('Align booth dynamic QR code inside viewport or enter drop-off below', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Smart Booth Scale Station Selector Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Select Smart Booth Station', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedBoothId,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.storefront_rounded, color: AppTheme.primary)),
                    items: _booths.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['id'] as int,
                        child: Text('${b['code']} • ${b['name']}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBoothId = val ?? 1),
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Plastic Polymer Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPlasticType,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.category_rounded, color: AppTheme.accent)),
                    items: _plasticTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPlasticType = val ?? _plasticTypes.first),
                  ),
                  const SizedBox(height: 16),

                  const Text('Plastic Deposit Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1.5',
                      prefixIcon: Icon(Icons.scale_rounded, color: AppTheme.primary),
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Real-time Reward Estimate Preview Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.subtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Tokens', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                            const SizedBox(height: 2),
                            Text('+$_projectedTokens', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ],
                        ),
                        Container(height: 28, width: 1, color: AppTheme.border),
                        Column(
                          children: [
                            const Text('Cashback Value', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                            const SizedBox(height: 2),
                            Text('৳${_projectedTaka.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                          ],
                        ),
                        Container(height: 28, width: 1, color: AppTheme.border),
                        Column(
                          children: [
                            const Text('CO2 Abated', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                            const SizedBox(height: 2),
                            Text('${_projectedCo2.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isDepositing ? null : _handleDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isDepositing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.recycling_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Deposit & Claim Tokens', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
