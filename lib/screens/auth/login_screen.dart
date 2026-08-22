import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../providers/app_state.dart';
import '../../widgets/animated_mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../main_shell.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Multi-Role Sign In Screen with Demo 1-Click Access
class LoginScreen extends StatefulWidget {
  final String role; // 'Public', 'Farmer', 'Admin'
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? overridePhone, String? overridePass}) async {
    final phone = overridePhone ?? _phoneController.text.trim();
    final pass = overridePass ?? _passwordController.text.trim();

    if (phone.isEmpty) {
      _showError(appState.t('error_phone'));
      return;
    }
    if (pass.isEmpty) {
      _showError(appState.t('error_field_required'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().login(
        identifier: phone,
        password: pass,
        role: widget.role,
      );

      if (!mounted) return;

      if (user != null) {
        appState.login(user);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        _showError('Invalid mobile number or password.');
      }
    } catch (e) {
      if (mounted) _showError(appState.t('error_generic'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final isFarmer = widget.role == 'Farmer';
    final isAdmin = widget.role == 'Admin';

    final Color accentColor = isFarmer
        ? AppColors.accent
        : (isAdmin ? AppColors.secondary : AppColors.primary);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button & Role Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          widget.role == 'Public'
                              ? t('role_public')
                              : (widget.role == 'Farmer' ? t('role_farmer') : t('role_admin')),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Header
                  Text(
                    t('login'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Access your verified ${widget.role.toLowerCase()} dashboard',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 32),

                  // Login Form Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone Number
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('phone_number'),
                            hintText: 'e.g. 9876543210',
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('password'),
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              t('forgot_password'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _handleLogin(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  t('login'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Demo Login Shortcut
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              t('demo_login'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (widget.role == 'Public') {
                                    _handleLogin(overridePhone: '9876543210', overridePass: '123456');
                                  } else if (widget.role == 'Farmer') {
                                    _handleLogin(overridePhone: '9876543211', overridePass: '123456');
                                  } else {
                                    _handleLogin(overridePhone: '9876543212', overridePass: 'admin123');
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '1-Click Quick ${widget.role} Demo',
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register Account Link (For Citizens and Farmers)
                  if (widget.role != 'Admin')
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(initialRole: widget.role),
                          ),
                        ),
                        child: Text(
                          t('dont_have_account'),
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
