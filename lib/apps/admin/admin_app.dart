import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../screens/auth/login_screen.dart';
import 'admin_shell.dart';

/// Standalone City Admin Application (OneNation Command Center)
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final isLoggedIn = appState.currentUser != null;

        return MaterialApp(
          title: 'OneNation Admin Command Center',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.secondary,
              primaryContainer: AppColors.secondaryDark,
              secondary: AppColors.primary,
              surface: const Color(0xFF0F1B2B),
              error: AppColors.danger,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          home: isLoggedIn ? const AdminShell() : const LoginScreen(role: 'Admin'),
        );
      },
    );
  }
}
