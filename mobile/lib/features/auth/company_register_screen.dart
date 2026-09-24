import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  final _nameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Partnership Application'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Register your recycling enterprise with Greenify. Accounts require administrator review.',
                style: TextStyle(color: AppTheme.muted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Text('Company Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. ABC Recycling Ltd.')),
              const SizedBox(height: 16),
              const Text('Trade Licence / Registration Number', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: _regNumController, decoration: const InputDecoration(hintText: 'e.g. REC-2024-9842')),
              const SizedBox(height: 16),
              const Text('Official Email', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: _emailController, decoration: const InputDecoration(hintText: 'contact@company.bd')),
              const SizedBox(height: 16),
              const Text('Official Contact Phone', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: _phoneController, decoration: const InputDecoration(hintText: '+88019XXXXXXXX')),
              const SizedBox(height: 16),
              const Text('Company Address', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: _addressController, decoration: const InputDecoration(hintText: 'Industrial Area, Dhaka')),
              const SizedBox(height: 16),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Company registration submitted for Admin review.')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Submit Partnership Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
