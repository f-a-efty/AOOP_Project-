import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final _api = AuthService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _api.fetchAdminUsers(ref.read(authTokenProvider));
      if (!mounted) return;
      setState(() {
        _users = rows
            .map((row) => Map<String, dynamic>.from(row as Map))
            .where((user) => user['role'] == 'USER')
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load registered users.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((user) {
      return ['fullName', 'phoneNumber', 'bkashNumber', 'loyaltyLevel'].any(
          (field) =>
              (user[field]?.toString().toLowerCase() ?? '').contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Registered users',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${_users.length} citizen accounts',
                        style: const TextStyle(color: AppTheme.muted)),
                  ])),
              IconButton(
                  onPressed: _loadUsers,
                  tooltip: 'Refresh users',
                  icon: const Icon(Icons.refresh_rounded)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search name, phone, or bKash',
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.muted),
                isDense: true,
              ),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _errorState()
                  : users.isEmpty
                      ? const Center(
                          child: Text('No matching registered users.',
                              style: TextStyle(color: AppTheme.muted)))
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 56),
                            itemBuilder: (context, index) =>
                                _userRow(users[index]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _userRow(Map<String, dynamic> user) {
    final name = user['fullName']?.toString() ?? 'Greenify member';
    final tokens = (user['totalTokens'] as num?)?.toInt() ?? 0;
    final status = user['status']?.toString() ?? 'ACTIVE';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary,
        child: Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
            '${user['phoneNumber'] ?? ''}  ·  ${user['loyaltyLevel'] ?? 'Eco Buddy'}\n${NumberFormat('#,##0').format(tokens)} tokens  ·  ৳${(tokens / 4).toStringAsFixed(2)}',
            maxLines: 2),
      ),
      isThreeLine: true,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _StatusLabel(status: status),
        PopupMenuButton<String>(
          tooltip: 'User actions',
          onSelected: (action) =>
              action == 'details' ? _showDetails(user) : _toggleStatus(user),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'details',
                child: ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('View details'),
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'status',
                child: ListTile(
                    leading: Icon(status == 'ACTIVE'
                        ? Icons.block_outlined
                        : Icons.check_circle_outline),
                    title: Text(status == 'ACTIVE'
                        ? 'Suspend account'
                        : 'Restore account'),
                    contentPadding: EdgeInsets.zero)),
          ],
        ),
      ]),
    );
  }

  Widget _errorState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: AppTheme.muted)),
          TextButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      );

  Future<void> _showDetails(Map<String, dynamic> user) async {
    final userId = (user['userId'] as num).toInt();
    final token = ref.read(authTokenProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _api.fetchAdminUser(token, userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const _UserDetailsError();
            if (!snapshot.hasData)
              return const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()));
            final details = snapshot.data!;
            final deposits =
                (details['recentDeposits'] as List<dynamic>? ?? []).cast<Map>();
            final transactions =
                (details['recentTransactions'] as List<dynamic>? ?? [])
                    .cast<Map>();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.88,
              maxChildSize: 0.96,
              builder: (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                children: [
                  Text(details['fullName']?.toString() ?? 'User profile',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                      '${details['phoneNumber'] ?? ''}  ·  ${details['status'] ?? ''}',
                      style: const TextStyle(color: AppTheme.muted)),
                  const SizedBox(height: 18),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _DetailChip(
                        label: 'Tokens',
                        value: NumberFormat('#,##0')
                            .format((details['totalTokens'] as num?) ?? 0)),
                    _DetailChip(
                        label: 'Tier',
                        value:
                            details['loyaltyLevel']?.toString() ?? 'Eco Buddy'),
                    _DetailChip(
                        label: 'bKash',
                        value: details['bkashNumber']?.toString().isNotEmpty ==
                                true
                            ? details['bkashNumber'].toString()
                            : 'Not set'),
                  ]),
                  const SizedBox(height: 22),
                  const Text('Recent deposits',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (deposits.isEmpty)
                    const Text('No deposits yet.',
                        style: TextStyle(color: AppTheme.muted))
                  else
                    ...deposits.map((deposit) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.recycling_rounded,
                              color: AppTheme.primary),
                          title: Text(
                              '${deposit['plasticWeightKg']} kg at ${deposit['boothCode']}'),
                          subtitle: Text(
                              '${deposit['plasticType'] ?? 'Plastic'}  ·  ${deposit['tokensEarned']} tokens'),
                        )),
                  const SizedBox(height: 16),
                  const Text('Recent wallet activity',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (transactions.isEmpty)
                    const Text('No wallet activity yet.',
                        style: TextStyle(color: AppTheme.muted))
                  else
                    ...transactions.map((transaction) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                              transaction['transactionType'] ==
                                      'Cashback Withdrawal'
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.swap_horiz_rounded,
                              color: AppTheme.skyBlue),
                          title: Text(
                              transaction['transactionType']?.toString() ??
                                  'Wallet transaction'),
                          subtitle: Text(
                              '${transaction['tokensDelta']} tokens  ·  ${transaction['status']}'),
                          trailing: transaction['cashDelta'] == null
                              ? null
                              : Text('৳${transaction['cashDelta']}'),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final active = user['status'] == 'ACTIVE';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Suspend account?' : 'Restore account?'),
        content: Text(active
            ? 'This user will no longer be able to sign in.'
            : 'This user will be able to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(active ? 'Suspend' : 'Restore')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.toggleAdminUserStatus(
          ref.read(authTokenProvider), (user['userId'] as num).toInt());
      await _loadUsers();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update this account.')));
    }
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'ACTIVE';
    final color = active ? AppTheme.primary : AppTheme.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: AppTheme.subtle, borderRadius: BorderRadius.circular(7)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}

class _UserDetailsError extends StatelessWidget {
  const _UserDetailsError();
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 240, child: Center(child: Text('Could not load user details.')));
}
