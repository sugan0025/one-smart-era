import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../screens/citizen/public_home_screen.dart';
import '../../screens/citizen/civic_map_screen.dart';
import '../../screens/citizen/schemes_screen.dart';
import '../../screens/citizen/news_feed_screen.dart';
import '../../screens/citizen/profile_screen.dart';
import '../../screens/citizen/report_screen.dart';
import '../../widgets/animated_mesh_background.dart';

/// Standalone Shell for Citizen App with Floating Report Action and Blur Bar
class CitizenShell extends StatelessWidget {
  const CitizenShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final int currentIndex = appState.navIndex.clamp(0, 4);

        const screens = [
          PublicHomeScreen(),
          CivicMapScreen(),
          SchemesScreen(),
          NewsFeedScreen(),
          ProfileScreen(),
        ];

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              const AnimatedMeshBackground(roleTheme: 'Public'),
              IndexedStack(
                index: currentIndex,
                children: screens,
              ),
            ],
          ),
          floatingActionButton: currentIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  ),
                  backgroundColor: AppColors.primary,
                  elevation: 8,
                  icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                  label: const Text(
                    'Report Issue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF08121A).withValues(alpha: 0.85),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textMuted,
                  onTap: (idx) => appState.setNav(idx),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      label: appState.t('home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.map_rounded),
                      label: appState.t('map'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.account_balance_rounded),
                      label: appState.t('schemes'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.campaign_rounded),
                      label: appState.t('feed'),
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
