import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('User Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by user name, phone, or bKash...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted),
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildUserTile(context, 'Rakibul Islam', '+8801711111111', '450 Tokens (৳112.50)', 'Green Friend', 'ACTIVE'),
        _buildUserTile(context, 'Tania Sultana', '+8801822222222', '150 Tokens (৳37.50)', 'Eco Buddy', 'ACTIVE'),
      ],
    );
  }

  Widget _buildUserTile(BuildContext context, String name, String phone, String balance, String tier, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppTheme.primary, child: Text(name[0], style: const TextStyle(color: Colors.white))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$phone • $tier\n$balance'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Edit User Profile'), onTap: () => Navigator.pop(context)),
                    ListTile(leading: const Icon(Icons.block_rounded, color: Colors.red), title: const Text('Suspend Account'), onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
