import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../main.dart';
import 'signup_screen.dart';
import 'company_register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'USER';
  final _authService = AuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Brand Logo Header
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo/Greenify-01-01.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Smart Plastic Collection & Reward System',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Role Segment Selector
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.subtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildRoleTab('USER', 'Citizen'),
                    _buildRoleTab('COMPANY', 'Recycler'),
                    _buildRoleTab('ADMIN', 'Admin'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Phone / Username Input
              Text(
                _selectedRole == 'ADMIN'
                    ? 'Admin Phone Number'
                    : 'Phone Number',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: _selectedRole == 'ADMIN'
                      ? 'e.g. 01746995650'
                      : '017XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_android_rounded,
                      color: AppTheme.muted),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppTheme.muted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              // Forgot Password (not for admin)
              if (_selectedRole != 'ADMIN')
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: AppTheme.primary)),
                  ),
                ),
              const SizedBox(height: 16),

              // Log In Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Log In'),
              ),
              const SizedBox(height: 24),

              // Register links (not for admin)
              if (_selectedRole != 'ADMIN') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: AppTheme.muted)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Register as Citizen',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CompanyRegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register as a Recycling Company',
                      style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String roleKey, String label) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.muted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showError('Please enter your phone number and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Normalize phone: strip leading 0, add +880 prefix if needed
      String normalizedPhone = phone;
      if (phone.startsWith('0') && phone.length == 11) {
        normalizedPhone = '+880${phone.substring(1)}';
      } else if (!phone.startsWith('+880')) {
        normalizedPhone = '+880$phone';
      }

      final result = await _authService.login(normalizedPhone, password);
      final role = result['role'] as String?;

      if (role != _selectedRole) {
        _showError('This account does not match the selected role.');
        return;
      }

      ref.read(authTokenProvider.notifier).state =
          result['accessToken'] as String?;
      ref.read(currentUserProvider.notifier).state = {
        'userId': result['userId'],
        'fullName': result['fullName'],
        'phoneNumber': result['phoneNumber'],
        'role': role,
      };
      ref.read(userRoleProvider.notifier).state = role;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Login failed. Check your credentials.';
      _showError(msg.toString());
    } catch (e) {
      _showError(
          'Could not connect to server. Make sure the backend is running.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
