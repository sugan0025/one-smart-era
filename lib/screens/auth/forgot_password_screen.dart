import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../providers/app_state.dart';
import '../../widgets/animated_mesh_background.dart';
import '../../widgets/glass_card.dart';

/// Secure Password Reset via OTP Verification
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _otpSent = false;
  String? _generatedOtp;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showSnackBar(appState.t('error_phone'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final otp = AuthService().requestPasswordResetOtp(phone);
    setState(() {
      _generatedOtp = otp;
      _otpSent = true;
      _isLoading = false;
    });

    _showSnackBar('Verification code sent to $phone: $otp', isError: false);
  }

  Future<void> _resetPassword() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();

    if (otp.length < 4) {
      _showSnackBar('Please enter valid verification OTP.', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnackBar(appState.t('error_password'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await AuthService().verifyOtpAndResetPassword(
      phone: phone,
      otp: otp,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar(appState.t('password_reset_success'), isError: false);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _showSnackBar('Invalid OTP code. Please try again.', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.success,
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

                  const SizedBox(height: 16),

                  Text(
                    t('forgot_password'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Reset your credentials securely via mobile verification',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 28),

                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_otpSent,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: t('phone_number'),
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                          ),
                        ),

                        if (!_otpSent) ...[
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Send Verification OTP'),
                          ),
                        ],

                        if (_otpSent) ...[
                          const SizedBox(height: 16),
                          if (_generatedOtp != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Demo OTP Code: $_generatedOtp',
                                      style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: '6-Digit Verification Code',
                              prefixIcon: Icon(Icons.pin_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: t('new_password'),
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                            ),
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(t('verify_and_reset')),
                          ),
                        ],
                      ],
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
