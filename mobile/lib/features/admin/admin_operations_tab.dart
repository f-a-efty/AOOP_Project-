import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class AdminOperationsTab extends ConsumerStatefulWidget {
  const AdminOperationsTab({super.key});

  @override
  ConsumerState<AdminOperationsTab> createState() => _AdminOperationsTabState();
}

class _AdminOperationsTabState extends ConsumerState<AdminOperationsTab> {
  final _api = AuthService();
  int _segmentIndex = 0;
  bool _showPickupQueue = false;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _booths = [];
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _pickups = [];
  List<Map<String, dynamic>> _activeCompanies = [];

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
      final token = ref.read(authTokenProvider);
      final result = await Future.wait([
        _api.fetchAdminBooths(token),
        _api.fetchAdminCollections(token),
        _api.fetchPendingCompanies(token),
        _api.fetchAdminPickupRequests(token),
        _api.fetchAdminCompanies(token),
      ]);
      if (!mounted) return;
      setState(() {
        _booths = _maps(result[0]);
        _collections = _maps(result[1]);
        _companies = _maps(result[2]);
        _pickups = _maps(result[3]);
        _activeCompanies = _maps(result[4]);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load operations data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _maps(List<dynamic> values) =>
      values.map((value) => Map<String, dynamic>.from(value as Map)).toList();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Operations',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Collection network and recycling partners',
                      style: TextStyle(color: AppTheme.muted)),
                ])),
            IconButton(
                onPressed: _load,
                tooltip: 'Refresh operations',
                icon: const Icon(Icons.refresh_rounded)),
            if (_segmentIndex == 0)
              IconButton(
                  onPressed: () => _showBoothDialog(),
                  tooltip: 'Add booth',
                  icon: const Icon(Icons.add_circle_outline_rounded)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _segmentButton(0, 'Booths', _booths.length),
            _segmentButton(1, 'Collections', _collections.length),
            _segmentButton(2, 'Company queue', _companies.length),
          ]),
          if (_segmentIndex == 2) ...[
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    label: Text('Applications (${_companies.length})')),
                ButtonSegment(
                    value: true,
                    label: Text(
                        'Pickup queue (${_pickups.where((item) => item['status'] != 'Completed').length})')),
              ],
              selected: {_showPickupQueue},
              onSelectionChanged: (value) =>
                  setState(() => _showPickupQueue = value.first),
            ),
          ],
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : RefreshIndicator(onRefresh: _load, child: _segmentContent()),
      ),
    ]);
  }

  Widget _segmentButton(int index, String label, int count) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ChoiceChip(
            selected: _segmentIndex == index,
            onSelected: (_) => setState(() => _segmentIndex = index),
            label: SizedBox(
                width: double.infinity,
                child: Text('$label  $count',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            labelStyle: TextStyle(
                color:
                    _segmentIndex == index ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 12),
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.subtle,
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
        ),
      );

  Widget _segmentContent() {
    if (_segmentIndex == 0) return _boothList();
    if (_segmentIndex == 1) return _collectionList();
    return _showPickupQueue ? _pickupList() : _companyList();
  }

  Widget _boothList() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        children: [
          _summaryStrip('Collection points', '${_booths.length} booths',
              Icons.sensors_rounded, AppTheme.primary),
          const SizedBox(height: 12),
          if (_booths.isEmpty)
            const _EmptyOperations('No collection booths have been added yet.')
          else
            ..._booths.map(_boothCard),
        ],
      );

  Widget _boothCard(Map<String, dynamic> booth) {
    final weight = (booth['currentWeightKg'] as num?)?.toDouble() ?? 0;
    final capacity = (booth['capacityKg'] as num?)?.toDouble() ?? 100;
    final fill = capacity <= 0 ? 0.0 : (weight / capacity).clamp(0.0, 1.0);
    final status = booth['boothStatus']?.toString() ?? 'Available';
    final statusColor = status == 'Full'
        ? AppTheme.errorRed
        : status == 'Almost Full'
            ? AppTheme.warningAmber
            : AppTheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppTheme.subtle,
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.recycling_rounded,
                    color: AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(booth['boothCode']?.toString() ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(booth['locationAddress']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ])),
            PopupMenuButton<String>(
              tooltip: 'Booth actions',
              onSelected: (value) {
                if (value == 'edit') _showBoothDialog(booth: booth);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit booth'))
              ],
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: Text(
                    '${weight.toStringAsFixed(1)} / ${capacity.toStringAsFixed(0)} kg',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 7),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 7,
                  color: statusColor,
                  backgroundColor: AppTheme.subtle)),
          const SizedBox(height: 7),
          Text(
              'Operated by ${booth['companyName'] ?? 'Unassigned'}  ·  ${booth['sensorStatus'] ?? 'Sensor unknown'}',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
        ]),
      ),
    );
  }

  Widget _collectionList() {
    final totalKg = _collections.fold<double>(0,
        (sum, item) => sum + ((item['netWeightKg'] as num?)?.toDouble() ?? 0));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      children: [
        _summaryStrip(
            'Collected by partners',
            '${totalKg.toStringAsFixed(1)} kg',
            Icons.local_shipping_rounded,
            AppTheme.skyBlue),
        const SizedBox(height: 12),
        if (_collections.isEmpty)
          const _EmptyOperations(
              'Completed booth collections will appear here.')
        else
          ..._collections.map((collection) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: const Color(0xFFE6F3F7),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: AppTheme.skyBlue)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  '${collection['boothCode'] ?? 'Booth'}  ·  ${collection['netWeightKg'] ?? 0} kg',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                  '${collection['companyName'] ?? 'Recycler'}  ·  ${collection['requestCode'] ?? ''}',
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 12)),
                              Text(
                                  collection['locationAddress']?.toString() ??
                                      '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppTheme.muted, fontSize: 11)),
                            ])),
                        Text(_date(collection['collectedAt']),
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 11)),
                      ]),
                ),
              )),
      ],
    );
  }

  Widget _companyList() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        children: [
          if (_companies.isEmpty)
            const _EmptyOperations(
                'No company applications are waiting for review.')
          else
            ..._companies.map(_companyCard),
        ],
      );

  Widget _companyCard(Map<String, dynamic> company) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(company['company_name']?.toString() ?? 'Company',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800))),
              _StatusBadge('PENDING', color: AppTheme.warningAmber),
            ]),
            const SizedBox(height: 7),
            Text(
                'Registration  ${company['registration_number'] ?? 'Not provided'}',
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            Text(
                '${company['contact_email'] ?? ''}  ·  ${company['contact_phone'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            Text(company['company_address']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _reviewCompany(company, approve: false),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reject'))),
              const SizedBox(width: 8),
              Expanded(
                  child: FilledButton.icon(
                      onPressed: () => _reviewCompany(company, approve: true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Approve'))),
            ]),
          ]),
        ),
      );

  Widget _pickupList() {
    final open =
        _pickups.where((item) => item['status'] != 'Completed').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      children: [
        if (open.isEmpty)
          const _EmptyOperations('There are no open company pickup requests.')
        else
          ...open.map((request) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: const Icon(Icons.local_shipping_outlined,
                      color: AppTheme.skyBlue),
                  title: Text(
                      '${request['requestCode']}  ·  ${request['payloadKg']} kg',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      '${request['boothCode']}  ·  ${request['companyName']}\n${request['locationAddress']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  trailing: _StatusBadge(
                      request['status']?.toString() ?? 'Pending',
                      color: request['priority'] == 'HIGH'
                          ? AppTheme.errorRed
                          : AppTheme.warningAmber),
                  isThreeLine: true,
                ),
              )),
      ],
    );
  }

  Widget _summaryStrip(
          String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppTheme.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800))
        ]),
      );

  Widget _errorView() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: AppTheme.muted)),
        TextButton(onPressed: _load, child: const Text('Retry'))
      ]));

  Future<void> _reviewCompany(Map<String, dynamic> company,
      {required bool approve}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve partnership?' : 'Reject application?'),
        content: Text(
            '${company['company_name']} will be ${approve ? 'activated' : 'declined'}. This changes its registration status in the database.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(approve ? 'Approve' : 'Reject'))
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.reviewCompany(
          ref.read(authTokenProvider), (company['company_id'] as num).toInt(),
          approve: approve);
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(approve ? 'Company approved.' : 'Company rejected.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Company status could not be updated.')));
    }
  }

  Future<void> _showBoothDialog({Map<String, dynamic>? booth}) async {
    final code =
        TextEditingController(text: booth?['boothCode']?.toString() ?? 'B-');
    final address = TextEditingController(
        text: booth?['locationAddress']?.toString() ?? '');
    final capacity =
        TextEditingController(text: (booth?['capacityKg'] ?? 100).toString());
    int? selectedCompanyId = (booth?['companyId'] as num?)?.toInt();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            booth == null ? 'Add collection booth' : 'Edit collection booth'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
                controller: code,
                decoration: const InputDecoration(
                    labelText: 'Short booth code', hintText: 'B-Utr-1'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a booth code.'
                    : null),
            TextFormField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a location.'
                    : null),
            TextFormField(
                controller: capacity,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Capacity (kg)'),
                validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                    ? 'Capacity must be positive.'
                    : null),
            DropdownButtonFormField<int?>(
              value: selectedCompanyId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Assigned recycler'),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Unassigned')),
                ..._activeCompanies.map((company) => DropdownMenuItem<int?>(
                      value: (company['companyId'] as num).toInt(),
                      child: Text(
                          company['companyName']?.toString() ?? 'Company',
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) => selectedCompanyId = value,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate())
                  Navigator.pop(context, true);
              },
              child: const Text('Save'))
        ],
      ),
    );
    if (saved == true) {
      final body = {
        'boothCode': code.text.trim(),
        'locationAddress': address.text.trim(),
        'capacityKg': double.parse(capacity.text),
        'companyId': selectedCompanyId,
        'boothStatus': booth?['boothStatus'] ?? 'Empty',
      };
      try {
        final token = ref.read(authTokenProvider);
        if (booth == null) {
          await _api.createAdminBooth(token, body);
        } else {
          await _api.updateAdminBooth(
              token, (booth['boothId'] as num).toInt(), body);
        }
        await _load();
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Booth could not be saved. Check that its code is unique.')));
      }
    }
    code.dispose();
    address.dispose();
    capacity.dispose();
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '' : DateFormat('MMM d, y').format(date.toLocal());
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label, {required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5)),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)));
}

class _EmptyOperations extends StatelessWidget {
  const _EmptyOperations(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted))));
}
