import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  bool _isLoading = false;
  List<dynamic> _users = [];
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final users = await api.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user directory.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStatus(int userId, String name, String currentStatus) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.toggleUserStatus(userId);
      final action = currentStatus == 'ACTIVE' ? 'suspended' : 'activated';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $name has been $action.'),
            backgroundColor: currentStatus == 'ACTIVE' ? AppTheme.warningAmber : AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      final name = (u['fullName'] ?? '').toString().toLowerCase();
      final phone = (u['phoneNumber'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'User Directory (${_users.length})',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                tooltip: 'Refresh list',
                onPressed: _fetchUsers,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search by full name or phone number...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
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
                            ElevatedButton(onPressed: _fetchUsers, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? const Center(
                            child: Text('No users match search criteria.', style: TextStyle(color: AppTheme.muted)),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchUsers,
                            color: AppTheme.primary,
                            child: ListView.separated(
                              itemCount: filteredUsers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index] as Map<String, dynamic>;
                                final userId = user['userId'] as int? ?? 0;
                                final name = user['fullName'] ?? 'Unnamed';
                                final phone = user['phoneNumber'] ?? 'No Phone';
                                final tokens = user['totalTokens'] ?? 0;
                                final role = user['role'] ?? 'USER';
                                final status = user['status'] ?? 'ACTIVE';
                                final loyalty = user['loyaltyLevel'] ?? 'Eco Citizen';
                                final isActive = status == 'ACTIVE';

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(role).withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: _getRoleColor(role),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textDark),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getRoleColor(role).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      role,
                                                      style: TextStyle(
                                                        color: _getRoleColor(role),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 9.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '$phone • $loyalty',
                                                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$tokens Tokens (৳${(tokens / 4.0).toStringAsFixed(2)})',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  color: isActive ? const Color(0xFF166534) : AppTheme.errorRed,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () => _toggleStatus(userId, name, status),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                child: Text(
                                                  isActive ? 'Suspend' : 'Activate',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isActive ? AppTheme.errorRed : AppTheme.primary,
                                                  ),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return AppTheme.warningAmber;
      case 'COMPANY':
        return AppTheme.skyBlue;
      default:
        return AppTheme.primary;
    }
  }
}
