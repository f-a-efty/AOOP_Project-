import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../main.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  int _step = 1;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _normalizedPhone {
    final p = _phoneController.text.trim();
    if (p.startsWith('0') && p.length == 11) return '+880${p.substring(1)}';
    if (!p.startsWith('+880')) return '+880$p';
    return p;
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
    );
  }

  Future<void> _sendOtp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || phone.isEmpty) {
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
      await _authService.sendOtp(_normalizedPhone);
      _showSuccess('OTP sent! (Test mode: use 123456)');
      setState(() => _step = 2);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to send OTP.';
      _showError(msg.toString());
    } catch (_) {
      _showError('Cannot connect to server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      _showError('Please enter the complete 6-digit OTP.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.registerUser(
        fullName: _nameController.text.trim(),
        phoneNumber: _normalizedPhone,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        otpCode: otp,
      );
      if (result['success'] == true) {
        ref.read(authTokenProvider.notifier).state =
            result['accessToken'] as String?;
        ref.read(currentUserProvider.notifier).state = {
          'userId': result['userId'],
          'fullName': result['fullName'] ?? _nameController.text.trim(),
          'phoneNumber': result['phoneNumber'] ?? _normalizedPhone,
          'role': 'USER',
        };
        ref.read(userRoleProvider.notifier).state = 'USER';
      } else {
        _showError(result['message'] ?? 'Registration failed.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Registration failed.';
      _showError(msg.toString());
    } catch (_) {
      _showError('Cannot connect to server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_step == 1 ? 'Create Citizen Account' : 'Verify Your Phone'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _step == 1 ? _buildStep1() : _buildStep2(),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Join Greenify & start earning cash rewards for plastic recycling!',
          style: TextStyle(color: AppTheme.muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'e.g. Rakibul Islam'),
        ),
        const SizedBox(height: 16),
        const Text('Bangladesh Phone Number',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '017XXXXXXXX',
            prefixText: '+880 ',
          ),
        ),
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
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Continue to OTP Verification'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'We sent a 6-digit code to +880 ${_phoneController.text.trim()}. (Test mode: use 123456)',
          style: const TextStyle(color: AppTheme.muted, fontSize: 14),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: TextField(
                controller: _otpControllers[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
                decoration: const InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyAndRegister,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Verify & Create Account'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('← Edit Phone Number',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }
}
