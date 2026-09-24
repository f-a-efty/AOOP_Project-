import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/user/user_home_screen.dart';
import 'features/company/company_home_screen.dart';
import 'features/admin/admin_home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GreenifyApp(),
    ),
  );
}

final userRoleProvider = StateProvider<String?>((ref) => null); // 'USER', 'COMPANY', 'ADMIN'

class GreenifyApp extends ConsumerWidget {
  const GreenifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(userRoleProvider);

    return MaterialApp(
      title: 'Greenify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildScreenForRole(currentRole),
    );
  }

  Widget _buildScreenForRole(String? role) {
    switch (role) {
      case 'USER':
        return const UserHomeScreen();
      case 'COMPANY':
        return const CompanyHomeScreen();
      case 'ADMIN':
        return const AdminHomeScreen();
      default:
        return const LoginScreen();
    }
  }
}
