import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../providers/app_state.dart';
import '../../widgets/animated_mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../main_shell.dart';

/// User Registration Screen with Field Validation and Secure Hashing
class RegisterScreen extends StatefulWidget {
  final String initialRole; // 'Public' or 'Farmer'
  const RegisterScreen({super.key, this.initialRole = 'Public'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late String _selectedRole;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole == 'Admin' ? 'Public' : widget.initialRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showError(appState.t('error_phone'));
      return;
    }
    if (address.isEmpty) {
      _showError('Please enter your city/village name.');
      return;
    }
    if (password.length < 6) {
      _showError(appState.t('error_password'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().register(
        name: name,
        phone: phone,
        address: address,
        email: email,
        password: password,
        role: _selectedRole,
      );

      if (!mounted) return;

      appState.login(user);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
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
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;

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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    t('register'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your citizen profile for smart city services',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 24),

                  // Role Segment Switch
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRole = 'Public'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'Public'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                t('role_public'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedRole == 'Public'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRole = 'Farmer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'Farmer'
                                    ? AppColors.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                t('role_farmer'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedRole == 'Farmer'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Registration Fields
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('full_name'),
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('phone_number'),
                            hintText: '10 digits mobile',
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _addressController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('city_village'),
                            hintText: 'e.g. Sathyamangalam, Erode',
                            prefixIcon: const Icon(Icons.location_on_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('email_optional'),
                            prefixIcon: const Icon(Icons.email_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole == 'Farmer'
                                ? AppColors.accent
                                : AppColors.primary,
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
                                  t('register'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
