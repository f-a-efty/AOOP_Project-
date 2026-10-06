import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
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
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: {'Content-Type': 'application/json'},
  ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 1 ? 'Create Citizen Account' : 'Verify Your Phone'),
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
          decoration: const InputDecoration(hintText: 'e.g. Fahim Ahmed'),
        ),
        const SizedBox(height: 16),
        const Text('Bangladesh Phone Number (+880)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+88017XXXXXXXX or 017XXXXXXXX',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Password (Min 8 chars, 1 number)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: '••••••••'),
        ),
        const SizedBox(height: 16),
        const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: '••••••••'),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSendOtp,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Continue to OTP Verification'),
        ),
      ],
    );
  }

  String _formatPhone(String raw) {
    raw = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (raw.startsWith('+880')) {
      return raw;
    }
    if (raw.startsWith('880')) {
      return '+$raw';
    }
    if (raw.startsWith('0')) {
      return '+88$raw';
    }
    if (raw.startsWith('1')) {
      return '+880$raw';
    }
    if (!raw.startsWith('+')) {
      return '+$raw';
    }
    return raw;
  }

  Future<void> _handleSendOtp() async {
    final name = _nameController.text.trim();
    final phone = _formatPhone(_phoneController.text);
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill all required fields.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    if (password.length < 8 || !RegExp(r'\d').hasMatch(password)) {
      _showError('Password must be at least 8 characters long and contain at least one number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _dio.post('/auth/otp/send', data: {
        'phoneNumber': phone,
        'purpose': 'REGISTER',
      });

      setState(() => _step = 2);
    } on DioException catch (e) {
      String msg = 'Failed to send OTP code.';
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          msg = data['message'].toString();
          if (msg.contains('phoneNumber=')) {
            msg = 'Invalid Bangladesh phone number format (e.g. 017XXXXXXXX).';
          }
        }
      } else if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        msg = 'Cannot connect to backend server. Make sure Start_Backend.exe is running on port 8080.';
      } else {
        msg = 'Network error (${e.message ?? 'Unknown'}). Check server connection.';
      }
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStep2() {
    final formattedPhone = _formatPhone(_phoneController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'We have sent a 6-digit verification code to $formattedPhone. (Dev Test Mode: Use 123456)',
          style: const TextStyle(color: AppTheme.muted, fontSize: 14),
        ),
        const SizedBox(height: 32),
        // 6-box OTP Input
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
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
          onPressed: _isLoading ? null : _handleRegisterUser,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Verify & Create Account'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Edit Phone Number', style: TextStyle(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegisterUser() async {
    final otpCode = _otpControllers.map((c) => c.text.trim()).join();
    if (otpCode.length < 6) {
      _showError('Please enter the full 6-digit OTP code.');
      return;
    }

    final name = _nameController.text.trim();
    final phone = _formatPhone(_phoneController.text);
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await _dio.post('/auth/register/user', data: {
        'fullName': name,
        'phoneNumber': phone,
        'password': password,
        'confirmPassword': password,
        'otpCode': otpCode,
      });

      final data = response.data;
      if (data['success'] == true) {
        final token = data['accessToken'];
        final role = data['role'];
        final fullName = data['fullName'];
        final userId = data['userId'];

        ref.read(authTokenProvider.notifier).state = token;
        ref.read(userNameProvider.notifier).state = fullName;
        ref.read(userPhoneProvider.notifier).state = phone;
        ref.read(userIdProvider.notifier).state = userId;
        ref.read(userRoleProvider.notifier).state = role;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome $fullName! Your account has been registered.')),
        );

        Navigator.pop(context);
      } else {
        _showError(data['message'] ?? 'Registration failed.');
      }
    } on DioException catch (e) {
      String msg = 'Registration error.';
      if (e.response?.data is Map && e.response?.data.containsKey('message')) {
        msg = e.response?.data['message'];
      }
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }
}
