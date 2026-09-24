import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1;
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your registered phone number to receive an OTP verification code.',
            style: TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 24),
          const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(hintText: '+88017XXXXXXXX'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            child: const Text('Send Verification OTP'),
          ),
        ],
      );
    } else if (_step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter the 6-digit verification code sent to your phone (Dev test mode: 123456)',
            style: TextStyle(color: AppTheme.muted),
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _step = 3),
            child: const Text('Verify OTP'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Set your new password.', style: TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 24),
          const Text('New Password', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
          const SizedBox(height: 16),
          const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(hintText: '••••••••')),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset successfully. Please log in.')),
              );
              Navigator.pop(context);
            },
            child: const Text('Reset Password & Return to Login'),
          ),
        ],
      );
    }
  }
}
