import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import 'signup_screen.dart';
import 'company_register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'USER'; // 'USER', 'COMPANY', 'ADMIN'

  late AnimationController _bgAnimationController;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: defaultApiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Eco Animated Background with Floating Orbs & Leaves
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              final progress = _bgAnimationController.value;
              return CustomPaint(
                painter: _EcoBackgroundPainter(progress: progress),
                child: Container(),
              );
            },
          ),

          // 2. Glassmorphic / Minimal Login Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E6027).withOpacity(0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Brand Logo & Dynamic Subtitle
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.subtle.withOpacity(0.5),
                                ),
                                child: Image.asset(
                                  'assets/logo/Greenify-01-01.png',
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _getHeaderSubtitle(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.muted,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Role Selector Tabs (Citizen | Recycler | Admin)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildRoleTab('USER', 'Citizen', Icons.person_outline_rounded),
                              _buildRoleTab('COMPANY', 'Recycler', Icons.recycling_rounded),
                              _buildRoleTab('ADMIN', 'Admin', Icons.admin_panel_settings_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Username / Phone / Admin ID Field
                        Text(
                          _getIdentifierLabel(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A1A)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: _getIdentifierHint(),
                            prefixIcon: Icon(
                              _selectedRole == 'ADMIN' ? Icons.badge_outlined : Icons.phone_android_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        const Text(
                          'Password',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A1A)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: _selectedRole == 'ADMIN' ? 'Enter admin password (123)' : 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.muted,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        // Forgot Password Link (Only for Citizen/Recycler)
                        if (_selectedRole != 'ADMIN') ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                              ),
                              child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD8B4FE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF7E22CE)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Admin Access: ID 420 | Password 123',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF7E22CE),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _phoneController.text = '420';
                                      _passwordController.text = '123';
                                    });
                                  },
                                  child: const Text(
                                    'Auto-Fill',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B21A8),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Animated Cool Press/Hover Login Button
                        _buildCoolButton(),
                        const SizedBox(height: 20),

                        // Role-Specific Register Link (Appears ONLY for Citizen and Recycler)
                        _buildRegisterOptionForRole(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderSubtitle() {
    switch (_selectedRole) {
      case 'COMPANY':
        return 'Recycling Enterprise Portal';
      case 'ADMIN':
        return 'System Administration Terminal';
      default:
        return 'Smart Plastic Collection & Reward System';
    }
  }

  String _getIdentifierLabel() {
    switch (_selectedRole) {
      case 'ADMIN':
        return 'Admin Number';
      case 'COMPANY':
        return 'Company Contact Phone Number';
      default:
        return 'Phone Number';
    }
  }

  String _getIdentifierHint() {
    switch (_selectedRole) {
      case 'ADMIN':
        return 'Enter admin number (420)';
      case 'COMPANY':
        return '+88019XXXXXXXX or 019XXXXXXXX';
      default:
        return '+88017XXXXXXXX or 017XXXXXXXX';
    }
  }

  Widget _buildRoleTab(String roleKey, String label, IconData icon) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = roleKey;
            if (roleKey == 'ADMIN') {
              _phoneController.text = '420';
              _passwordController.text = '123';
            } else {
              if (_phoneController.text == '420') _phoneController.clear();
              if (_passwordController.text == '123') _passwordController.clear();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.muted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoolButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E6027), Color(0xFF438A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6027).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getButtonText(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }

  String _getButtonText() {
    switch (_selectedRole) {
      case 'ADMIN':
        return 'Access Administrator Console';
      case 'COMPANY':
        return 'Recycler Log In';
      default:
        return 'Log In as Citizen';
    }
  }

  Widget _buildRegisterOptionForRole() {
    if (_selectedRole == 'USER') {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text("New to Greenify? ", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            child: const Text(
              'Register Citizen Account',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    } else if (_selectedRole == 'COMPANY') {
      return Center(
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyRegisterScreen()),
            );
          },
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryLight),
          child: const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.business_center_outlined, size: 16),
              SizedBox(width: 6),
              Text(
                'Apply for Recycling Partnership',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else {
      // ADMIN role has NO register option as requested
      return const SizedBox.shrink();
    }
  }

  Future<void> _handleLogin() async {
    final rawUsername = _phoneController.text.trim();
    String username = rawUsername.contains('@') ? rawUsername : rawUsername.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    String password = _passwordController.text.trim();

    // Auto-detect Admin shortcut regardless of selected tab
    String effectiveRole = _selectedRole;
    if (username == '420' || username == '0420' || username == '+880420' || username.toLowerCase() == 'admin' || username.toLowerCase() == 'admin420') {
      effectiveRole = 'ADMIN';
    }

    if (effectiveRole == 'ADMIN') {
      if (username.isEmpty) username = '420';
      if (password.isEmpty) password = '123';
    }

    if (username.isEmpty) {
      _showError(_selectedRole == 'ADMIN' ? 'Please enter admin number (420).' : 'Please enter your phone number or email.');
      return;
    }

    if (password.isEmpty) {
      _showError(_selectedRole == 'ADMIN' ? 'Please enter admin password (123).' : 'Please enter your password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'targetRole': effectiveRole,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        final token = data['accessToken'];
        final role = data['role'];
        final fullName = data['fullName'];
        final userId = data['userId'];

        ref.read(authTokenProvider.notifier).state = token;
        ref.read(userPhoneProvider.notifier).state = username;
        ref.read(userNameProvider.notifier).state = fullName;
        ref.read(userIdProvider.notifier).state = userId;
        ref.read(userRoleProvider.notifier).state = role;
      } else {
        _showError(data['message'] ?? 'Login failed. Please check credentials.');
      }
    } on DioException catch (e) {
      String msg = 'Invalid credentials or account not found.';
      if (e.response != null && e.response?.data != null) {
        final res = e.response?.data;
        if (res is Map && res.containsKey('message')) {
          msg = res['message'];
        }
      }
      _showError(msg);
    } catch (e) {
      _showError('Connection error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Custom Animated Background Painter (Floating Orbs & Soft Eco Gradients)
class _EcoBackgroundPainter extends CustomPainter {
  final double progress;
  _EcoBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseGradient = LinearGradient(
      colors: [
        const Color(0xFFE8F5E9),
        const Color(0xFFC8E6C9),
        const Color(0xFFA5D6A7).withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()..shader = baseGradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Floating Animated Circles/Leaves
    final orbPaint1 = Paint()..color = const Color(0xFF2E6027).withOpacity(0.08);
    final orbPaint2 = Paint()..color = const Color(0xFF6BBF3A).withOpacity(0.12);

    final dx1 = size.width * (0.2 + 0.1 * math.sin(progress * 2 * math.pi));
    final dy1 = size.height * (0.25 + 0.08 * math.cos(progress * 2 * math.pi));
    canvas.drawCircle(Offset(dx1, dy1), 140, orbPaint1);

    final dx2 = size.width * (0.8 - 0.12 * math.cos(progress * 2 * math.pi));
    final dy2 = size.height * (0.75 + 0.1 * math.sin(progress * 2 * math.pi));
    canvas.drawCircle(Offset(dx2, dy2), 180, orbPaint2);
  }

  @override
  bool shouldRepaint(covariant _EcoBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
