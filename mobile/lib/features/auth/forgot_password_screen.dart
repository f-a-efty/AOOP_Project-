import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/eco_background_wrapper.dart';

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
        elevation: 0,
      ),
      body: EcoBackgroundWrapper(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E6027).withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(28.0),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.subtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Verify Phone',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your registered phone number to receive a 6-digit OTP verification code.',
            style: TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '017XXXXXXXX',
              prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primary, size: 20),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              if (_phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your phone number')),
                );
                return;
              }
              setState(() => _step = 2);
            },
            child: const Text('Send Verification OTP'),
          ),
        ],
      );
    } else if (_step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.subtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Enter OTP Code',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter the 6-digit verification code sent to your phone (Dev Test Mode: 123456).',
            style: TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                height: 52,
                child: TextField(
                  controller: _otpControllers[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    fillColor: AppTheme.subtle.withOpacity(0.5),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) FocusScope.of(context).nextFocus();
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => setState(() => _step = 3),
            child: const Text('Verify Code'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.subtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.password_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'New Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Choose a strong password with at least 6 characters.', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 24),
          const Text('New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: '••••••••', prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
          ),
          const SizedBox(height: 16),
          const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: '••••••••', prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset successfully. Please log in with your new credentials.')),
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
