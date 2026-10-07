import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'Content-Type': 'application/json'},
  ));

  @override
  void dispose() {
    _nameController.dispose();
    _regNumController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Partnership Application'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_center_rounded, color: AppTheme.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Partner With Greenify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                                SizedBox(height: 2),
                                Text('Register your plastic recycling enterprise', style: TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _buildFormField(
                        label: 'Company Name',
                        controller: _nameController,
                        hint: 'e.g. ABC Recycling Ltd.',
                        icon: Icons.domain_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Trade Licence / Registration Number',
                        controller: _regNumController,
                        hint: 'e.g. REC-2024-9842',
                        icon: Icons.verified_user_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Official Email',
                        controller: _emailController,
                        hint: 'contact@company.bd',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Official Contact Phone',
                        controller: _phoneController,
                        hint: '+88019XXXXXXXX or 019XXXXXXXX',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Company Address',
                        controller: _addressController,
                        hint: 'Industrial Area, Tejgaon, Dhaka',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        label: 'Portal Password',
                        controller: _passwordController,
                        hint: 'Min 8 chars with 1 number',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 28),

                      // Symmetrical Balanced Submit Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegisterCompany,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('Submit Partnership Application', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.send_rounded, size: 16),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A1A)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 19),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegisterCompany() async {
    final name = _nameController.text.trim();
    final regNum = _regNumController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || regNum.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError('Please fill all required fields.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid official email address (e.g. contact@company.bd).');
      return;
    }

    if (phone.length < 10) {
      _showError('Please enter a valid official contact phone number (e.g. 019XXXXXXXX).');
      return;
    }

    if (password.length < 8 || !RegExp(r'\d').hasMatch(password)) {
      _showError('Password must be at least 8 characters long and contain at least one number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _dio.post('/auth/register/company', data: {
        'companyName': name,
        'registrationNumber': regNum,
        'contactEmail': email,
        'contactPhone': phone,
        'companyAddress': address,
        'password': password,
        'confirmPassword': password,
      });

      final data = response.data;
      if (data['success'] == true) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 26),
                SizedBox(width: 8),
                Text('Application Submitted!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: Text(
              'Your company ($name) partnership application has been submitted to the Admin Queue for verification. Once approved by the administrator, you can log in using your contact phone number.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Return to Login'),
              ),
            ],
          ),
        );
      } else {
        _showError(data['message'] ?? 'Registration failed.');
      }
    } on DioException catch (e) {
      String msg = 'Failed to submit company application.';
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response == null) {
        msg = 'Cannot connect to backend server on port 8080. Please ensure the backend is running.';
      } else if (e.response?.data is Map) {
        final resData = e.response!.data as Map;
        if (resData.containsKey('message') && resData['message'] != null) {
          String rawMsg = resData['message'].toString();
          if (rawMsg.startsWith('{') && rawMsg.endsWith('}')) {
            rawMsg = rawMsg.substring(1, rawMsg.length - 1);
            final parts = rawMsg.split(',');
            if (parts.isNotEmpty) {
              final kv = parts.first.split('=');
              rawMsg = kv.length > 1 ? kv[1].trim() : kv[0].trim();
            }
          }
          msg = rawMsg;
        }
      }
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
