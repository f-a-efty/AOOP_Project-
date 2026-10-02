import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class QrScannerTab extends ConsumerStatefulWidget {
  const QrScannerTab({super.key});

  @override
  ConsumerState<QrScannerTab> createState() => _QrScannerTabState();
}

class _QrScannerTabState extends ConsumerState<QrScannerTab> {
  final _weightController = TextEditingController(text: '54');
  final _sessionController = TextEditingController();
  final _authService = AuthService();
  String _selectedPlasticType = 'PET Plastic Bottles';
  List<Map<String, dynamic>> _booths = [];
  int? _selectedBoothId;
  int _tokensPerKg = 100;
  int _tokensPerTaka = 4;
  bool _loadingBooths = true;
  bool _isSubmitting = false;

  final List<String> _plasticTypes = [
    'PET Plastic Bottles',
    'HDPE Milk & Juice Jugs',
    'LDPE Soft Wraps & Bags',
    'PP Containers & Bottle Caps',
    'Mixed Plastics (General)',
  ];

  @override
  void initState() {
    super.initState();
    _loadDepositOptions();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  double get _enteredWeight => double.tryParse(_weightController.text) ?? 0.0;
  int get _calculatedTokens => (_enteredWeight * _tokensPerKg).floor();
  double get _calculatedTaka => _calculatedTokens / _tokensPerTaka;

  Future<void> _loadDepositOptions() async {
    try {
      final values = await Future.wait([
        _authService.fetchBooths(),
        _authService.fetchPublicEconomics(),
      ]);
      if (!mounted) return;
      final boothRows = values[0] as List<dynamic>;
      final economics = values[1] as Map<String, dynamic>;
      setState(() {
        _booths = boothRows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _selectedBoothId =
            _booths.isEmpty ? null : (_booths.first['boothId'] as num).toInt();
        _tokensPerKg = (economics['tokensPerKg'] as num?)?.toInt() ?? 100;
        _tokensPerTaka = (economics['tokensPerTaka'] as num?)?.toInt() ?? 4;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Could not load available booths and reward rates.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingBooths = false);
    }
  }

  Future<void> _handleManualDeposit() async {
    final weight = _enteredWeight;
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid weight greater than 0 kg.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (_selectedBoothId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an available booth first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final token = ref.read(authTokenProvider);

    try {
      final res = await _authService.manualDeposit(
        token,
        weightKg: weight,
        plasticType: _selectedPlasticType,
        boothId: _selectedBoothId,
      );

      // Trigger dashboard reload
      ref.read(userDashboardReloadTriggerProvider.notifier).state++;

      if (!mounted) return;

      final tokensEarned = res['tokensEarned'] ?? _calculatedTokens;
      final totalTokens = res['totalTokens'] ?? 0;
      final balanceTaka = res['walletBalanceTaka'] != null
          ? (res['walletBalanceTaka'] as num).toDouble()
          : (totalTokens / 4.0);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Deposit Recorded!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎉 Successfully deposited ${weight.toStringAsFixed(2)} kg of $_selectedPlasticType into the database.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.subtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tokens Earned:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('+$tokensEarned Tokens',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Total Balance:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            '$totalTokens Tokens (৳${balanceTaka.toStringAsFixed(2)} BDT)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Great!'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          'Failed to record deposit in database.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg.toString()),
              backgroundColor: Colors.red.shade700),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Could not connect to database server.'),
              backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Manual Plastic Entry (Custom weight without hardware)
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: AppTheme.accent,
                        child: Icon(Icons.recycling_rounded,
                            color: AppTheme.textDark),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Manual Plastic Deposit',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                'Enter kg directly to update database & tokens',
                                style: TextStyle(
                                    color: AppTheme.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text('Collection booth',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (_loadingBooths)
                    const LinearProgressIndicator(minHeight: 2)
                  else if (_booths.isEmpty)
                    const Text('No booths are currently accepting deposits.',
                        style: TextStyle(color: AppTheme.errorRed))
                  else
                    DropdownButtonFormField<int>(
                      value: _selectedBoothId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _booths.map((booth) {
                        final boothId = (booth['boothId'] as num).toInt();
                        final code =
                            booth['boothCode']?.toString() ?? 'Booth $boothId';
                        final address =
                            booth['locationAddress']?.toString() ?? '';
                        return DropdownMenuItem(
                          value: boothId,
                          child: Text('$code · $address',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedBoothId = value),
                    ),
                  const SizedBox(height: 16),

                  // Plastic Type Selector
                  const Text('Plastic Category',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedPlasticType,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _plasticTypes.map((type) {
                      return DropdownMenuItem(
                          value: type,
                          child:
                              Text(type, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedPlasticType = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Weight Input Field
                  const Text('Plastic Weight in Kilograms (kg)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'e.g. 54',
                      suffixText: 'kg',
                      suffixStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary),
                      prefixIcon: const Icon(Icons.scale_rounded,
                          color: AppTheme.primary),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Quick Selection Preset Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [1.0, 5.0, 10.0, 25.0, 54.0].map((w) {
                      final isSelected = _enteredWeight == w;
                      return ActionChip(
                        label: Text(
                            '${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1)} kg'),
                        backgroundColor:
                            isSelected ? AppTheme.primary : AppTheme.subtle,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onPressed: () {
                          setState(() {
                            _weightController.text = w.toStringAsFixed(
                                w.truncateToDouble() == w ? 0 : 1);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Reward Estimation Calculation Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.subtle,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppTheme.accent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reward to Earn:',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.muted,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '$_calculatedTokens Tokens',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Cash Value:',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.muted,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '৳${_calculatedTaka.toStringAsFixed(2)} BDT',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Deposit Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleManualDeposit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('♻️ Deposit Plastic (Save to Database)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Section 2: Hardware Smart Booth QR Scanner Frame (Demo)
          const Text('Smart Booth QR Scanner (Demo)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'In live deployment, point camera at the Smart Booth screen to link hardware scale telemetry.',
            style: TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Simulated Scanner Frame
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.subtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryLight, width: 2),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_weak_rounded,
                      size: 54, color: AppTheme.primary),
                  SizedBox(height: 10),
                  Text('Align QR Code inside box',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Hardware Session Connect (Dev Testing)
          const Text('Or Enter Hardware Session ID (Dev Testing):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _sessionController,
            decoration: const InputDecoration(hintText: 'e.g. DS-88102A'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Linked hardware test session!')),
              );
            },
            child: const Text('Connect Deposit Session'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
