import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class AdminMoreTab extends ConsumerStatefulWidget {
  const AdminMoreTab({super.key});

  @override
  ConsumerState<AdminMoreTab> createState() => _AdminMoreTabState();
}

class _AdminMoreTabState extends ConsumerState<AdminMoreTab> {
  final _api = AuthService();
  int _section = 0;
  int _days = 30;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _campaigns = [];
  Map<String, dynamic> _analytics = {};

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
      final results = await Future.wait([
        _api.fetchLoyaltyLevels(token),
        _api.fetchCampaigns(token),
        _api.fetchAdminAnalytics(token, days: _days),
      ]);
      if (!mounted) return;
      setState(() {
        _levels = _maps(results[0]);
        _campaigns = _maps(results[1]);
        _analytics = Map<String, dynamic>.from(results[2] as Map);
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not load administration data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _maps(dynamic data) => (data as List<dynamic>)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

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
                  Text('Growth & impact',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Loyalty, community campaigns, and reporting',
                      style: TextStyle(color: AppTheme.muted)),
                ])),
            IconButton(
                onPressed: _load,
                tooltip: 'Refresh data',
                icon: const Icon(Icons.refresh_rounded)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Tiers')),
                ButtonSegment(value: 1, label: Text('Campaigns')),
                ButtonSegment(value: 2, label: Text('Reports')),
              ],
              selected: {_section},
              onSelectionChanged: (value) =>
                  setState(() => _section = value.first),
            ),
          ),
        ]),
      ),
      Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _errorView()
                  : _sectionView()),
    ]);
  }

  Widget _sectionView() {
    if (_section == 0) return _loyaltyView();
    if (_section == 1) return _campaignView();
    return _reportsView();
  }

  Widget _loyaltyView() => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
            children: [
              const Text(
                  'Deposit totals automatically assign the highest tier whose minimum is met.',
                  style: TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 12),
              if (_levels.isEmpty)
                const _EmptyMore('No loyalty tiers configured.')
              else
                ..._levels.map((level) => Card(
                      margin: const EdgeInsets.only(bottom: 9),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        leading: const Icon(Icons.workspace_premium_rounded,
                            color: AppTheme.warningAmber),
                        title: Text(level['level']?.toString() ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                            '${level['minKg']} to ${level['maxKg']} kg  ·  ${level['benefits'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                            tooltip: 'Edit tier',
                            onPressed: () => _editLevel(level),
                            icon: const Icon(Icons.edit_outlined)),
                      ),
                    )),
            ]),
      );

  Widget _campaignView() => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
            children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                      onPressed: () => _editCampaign(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New campaign'))),
              const SizedBox(height: 8),
              if (_campaigns.isEmpty)
                const _EmptyMore('No campaigns created yet.')
              else
                ..._campaigns.map((campaign) => Card(
                      margin: const EdgeInsets.only(bottom: 9),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                                color: const Color(0xFFE4F1E9),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.campaign_rounded,
                                color: AppTheme.primary)),
                        title: Text(campaign['title']?.toString() ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                            '${campaign['type']}  ·  ${campaign['status']}\n${campaign['description'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Campaign actions',
                          onSelected: (action) => action == 'edit'
                              ? _editCampaign(campaign: campaign)
                              : _archiveCampaign(campaign),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'archive', child: Text('Archive'))
                          ],
                        ),
                      ),
                    )),
            ]),
      );

  Widget _reportsView() {
    final daily = (List<dynamic>.from(_analytics['daily'] as List? ?? []))
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final topBooths =
        (List<dynamic>.from(_analytics['topBooths'] as List? ?? []))
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
    final totalKg = daily.fold<double>(
        0, (sum, row) => sum + ((row['plasticKg'] as num?)?.toDouble() ?? 0));
    final tokens = daily.fold<int>(
        0, (sum, row) => sum + ((row['tokensIssued'] as num?)?.toInt() ?? 0));
    final peak = daily.fold<double>(
        0,
        (value, row) => value > ((row['plasticKg'] as num?)?.toDouble() ?? 0)
            ? value
            : ((row['plasticKg'] as num?)?.toDouble() ?? 0));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Deposit performance',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800))),
              DropdownButton<int>(
                  value: _days,
                  underline: const SizedBox.shrink(),
                  items: const [7, 30, 90, 365]
                      .map((days) => DropdownMenuItem(
                          value: days, child: Text('$days days')))
                      .toList(),
                  onChanged: (days) {
                    if (days != null) {
                      setState(() => _days = days);
                      _load();
                    }
                  }),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _ReportValue(
                      label: 'Plastic',
                      value: '${totalKg.toStringAsFixed(1)} kg',
                      color: AppTheme.primary)),
              const SizedBox(width: 9),
              Expanded(
                  child: _ReportValue(
                      label: 'Tokens issued',
                      value: NumberFormat('#,##0').format(tokens),
                      color: AppTheme.warningAmber))
            ]),
            const SizedBox(height: 18),
            const Text('Daily deposits',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (daily.isEmpty)
              const _EmptyMore('No deposits in this period.')
            else
              ...daily.map((row) {
                final value = (row['plasticKg'] as num?)?.toDouble() ?? 0;
                final date = DateTime.tryParse(row['date']?.toString() ?? '');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    SizedBox(
                        width: 58,
                        child: Text(
                            date == null
                                ? ''
                                : DateFormat('MMM d').format(date),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.muted))),
                    Expanded(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                                value: peak <= 0 ? 0 : value / peak,
                                minHeight: 9,
                                backgroundColor: AppTheme.subtle,
                                color: AppTheme.accent))),
                    SizedBox(
                        width: 56,
                        child: Text('${value.toStringAsFixed(1)} kg',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700))),
                  ]),
                );
              }),
            const SizedBox(height: 20),
            const Text('Top booths',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...topBooths.map((booth) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppTheme.skyBlue),
                  title: Text(booth['boothCode']?.toString() ?? ''),
                  subtitle: Text(booth['locationAddress']?.toString() ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text('${booth['plasticKg']} kg',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                )),
          ]),
    );
  }

  Widget _errorView() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: AppTheme.muted)),
        TextButton(onPressed: _load, child: const Text('Retry'))
      ]));

  Future<void> _editLevel(Map<String, dynamic> level) async {
    final min = TextEditingController(text: level['minKg'].toString());
    final max = TextEditingController(text: level['maxKg'].toString());
    final benefits =
        TextEditingController(text: level['benefits']?.toString() ?? '');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${level['level']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: min,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Minimum kilograms')),
          TextField(
              controller: max,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Maximum kilograms')),
          TextField(
              controller: benefits,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Benefits')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, {
                    'minKg': double.tryParse(min.text),
                    'maxKg': double.tryParse(max.text),
                    'benefits': benefits.text.trim(),
                    'badge': level['badge']
                  }),
              child: const Text('Save'))
        ],
      ),
    );
    if (result != null) {
      try {
        await _api.updateLoyaltyLevel(
            ref.read(authTokenProvider), level['level'].toString(), result);
        await _load();
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Tier rules could not be saved. Check the kg range.')));
      }
    }
    min.dispose();
    max.dispose();
    benefits.dispose();
  }

  Future<void> _editCampaign({Map<String, dynamic>? campaign}) async {
    final title =
        TextEditingController(text: campaign?['title']?.toString() ?? '');
    final type = TextEditingController(
        text: campaign?['type']?.toString() ?? 'Community challenge');
    final description =
        TextEditingController(text: campaign?['description']?.toString() ?? '');
    final start = TextEditingController(
        text: _dateInput(campaign?['startDate']) ??
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
    final end = TextEditingController(
        text: _dateInput(campaign?['endDate']) ??
            DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(DateTime.now().add(const Duration(days: 30))));
    final status = TextEditingController(
        text: campaign?['status']?.toString() ?? 'Upcoming');
    final form = GlobalKey<FormState>();
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(campaign == null ? 'Create green campaign' : 'Edit campaign'),
        content: SizedBox(
            width: 420,
            child: Form(
                key: form,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _field(title, 'Campaign title', required: true),
                  _field(type, 'Campaign type', required: true),
                  _field(description, 'Description', maxLines: 3),
                  _field(start, 'Start (YYYY-MM-DD HH:mm:ss)', required: true),
                  _field(end, 'End (YYYY-MM-DD HH:mm:ss)', required: true),
                  _field(status, 'Status (Upcoming, Active, Completed)',
                      required: true),
                ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (form.currentState!.validate())
                  Navigator.pop(context, {
                    'title': title.text.trim(),
                    'type': type.text.trim(),
                    'description': description.text.trim(),
                    'startDate': start.text.trim(),
                    'endDate': end.text.trim(),
                    'status': status.text.trim()
                  });
              },
              child: const Text('Save campaign'))
        ],
      ),
    );
    if (body != null) {
      try {
        await _api.saveCampaign(ref.read(authTokenProvider), body,
            campaignId: (campaign?['campaignId'] as num?)?.toInt());
        await _load();
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Campaign could not be saved. Check the date range.')));
      }
    }
    for (final controller in [title, type, description, start, end, status]) {
      controller.dispose();
    }
  }

  Widget _field(TextEditingController controller, String label,
          {bool required = false, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(top: 9),
        child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(labelText: label),
            validator: (value) =>
                required && (value == null || value.trim().isEmpty)
                    ? 'Required'
                    : null),
      );

  String? _dateInput(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? null
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toLocal());
  }

  Future<void> _archiveCampaign(Map<String, dynamic> campaign) async {
    try {
      await _api.archiveCampaign(
          ref.read(authTokenProvider), (campaign['campaignId'] as num).toInt());
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign could not be archived.')));
    }
  }
}

class _ReportValue extends StatelessWidget {
  const _ReportValue(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w800))
      ]));
}

class _EmptyMore extends StatelessWidget {
  const _EmptyMore(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted))));
}
