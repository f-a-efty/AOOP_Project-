import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

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
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _regNumController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final p = _phoneController.text.trim();
    if (p.startsWith('0') && p.length == 11) return '+880${p.substring(1)}';
    if (!p.startsWith('+880')) return '+880$p';
    return p;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final regNum = _regNumController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty ||
        regNum.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        address.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters long.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerCompany(
        companyName: name,
        registrationNumber: regNum,
        contactEmail: email,
        contactPhone: _normalizedPhone,
        companyAddress: address,
        password: password,
        confirmPassword: confirm,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Application Submitted!'),
          content: const Text(
            'Your company registration has been submitted and is pending administrator review. You will be able to log in once approved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back to login
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Registration failed.';
      _showError(msg.toString());
    } catch (_) {
      _showError('Cannot connect to server. Make sure the backend is running.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
              const Text('Company Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      hintText: 'e.g. ABC Recycling Ltd.')),
              const SizedBox(height: 16),
              const Text('Trade Licence / Registration Number',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                  controller: _regNumController,
                  decoration:
                      const InputDecoration(hintText: 'e.g. REC-2024-9842')),
              const SizedBox(height: 16),
              const Text('Official Email',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'contact@company.bd'),
              ),
              const SizedBox(height: 16),
              const Text('Contact Phone',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '017XXXXXXXX'),
              ),
              const SizedBox(height: 16),
              const Text('Company Address',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                      hintText: 'Industrial Area, Dhaka')),
              const SizedBox(height: 16),
              const Text('Password (Min 8 chars, 1 number)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 16),
              const Text('Confirm Password',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Partnership Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
