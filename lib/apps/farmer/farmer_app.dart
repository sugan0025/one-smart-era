import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../screens/auth/login_screen.dart';
import 'farmer_shell.dart';

/// Standalone Farmer Application (OneNation Kisan Hub)
class FarmerApp extends StatelessWidget {
  const FarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final isLoggedIn = appState.currentUser != null;

        return MaterialApp(
          title: 'OneNation Kisan Hub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.accent,
              primaryContainer: const Color(0xFFB45309),
              secondary: AppColors.primary,
              surface: const Color(0xFF1C1309),
              error: AppColors.danger,
              onPrimary: Colors.black,
              onSurface: AppColors.textPrimary,
            ),
          ),
          home: isLoggedIn ? const FarmerShell() : const LoginScreen(role: 'Farmer'),
        );
      },
    );
  }
}
