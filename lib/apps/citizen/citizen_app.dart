import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../screens/auth/login_screen.dart';
import 'citizen_shell.dart';

/// Standalone Citizen Application (OneNation Citizen)
class CitizenApp extends StatelessWidget {
  const CitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final isLoggedIn = appState.currentUser != null;

        return MaterialApp(
          title: 'OneNation Citizen',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              primaryContainer: AppColors.primaryDark,
              secondary: AppColors.secondary,
              surface: AppColors.bgDarkCard,
              error: AppColors.danger,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          home: isLoggedIn ? const CitizenShell() : const LoginScreen(role: 'Public'),
        );
      },
    );
  }
}
