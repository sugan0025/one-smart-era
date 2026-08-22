import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_analytics_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_warehouse_screen.dart';
import '../../screens/citizen/profile_screen.dart';
import '../../widgets/animated_mesh_background.dart';

/// Standalone Shell for City Operations & Command Center
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final int currentIndex = appState.navIndex.clamp(0, 4);

        const screens = [
          AdminDashboardScreen(),
          AdminAnalyticsScreen(),
          AdminUsersScreen(),
          AdminWarehouseScreen(),
          ProfileScreen(),
        ];

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              const AnimatedMeshBackground(roleTheme: 'Admin'),
              IndexedStack(
                index: currentIndex,
                children: screens,
              ),
            ],
          ),
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF070E1A).withValues(alpha: 0.88),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  selectedItemColor: AppColors.secondary,
                  unselectedItemColor: AppColors.textMuted,
                  onTap: (idx) => appState.setNav(idx),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.dashboard_rounded),
                      label: appState.t('dashboard'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: appState.t('analytics'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.people_rounded),
                      label: appState.t('users'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.ac_unit_rounded),
                      label: appState.t('warehouses'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_rounded),
                      label: appState.t('profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
