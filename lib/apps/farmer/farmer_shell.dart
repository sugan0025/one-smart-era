import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../screens/farmer/farmer_home_screen.dart';
import '../../screens/farmer/market_screen.dart';
import '../../screens/farmer/crop_doctor_screen.dart';
import '../../screens/farmer/farmer_logistics_screen.dart';
import '../../screens/citizen/profile_screen.dart';
import '../../widgets/animated_mesh_background.dart';

/// Standalone Shell for Farmer Hub App (OneNation Kisan)
class FarmerShell extends StatelessWidget {
  const FarmerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final int currentIndex = appState.navIndex.clamp(0, 4);

        const screens = [
          FarmerHomeScreen(),
          MarketScreen(),
          CropDoctorScreen(),
          FarmerLogisticsScreen(),
          ProfileScreen(),
        ];

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              const AnimatedMeshBackground(roleTheme: 'Farmer'),
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
                  color: const Color(0xFF140D05).withValues(alpha: 0.88),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  selectedItemColor: AppColors.accent,
                  unselectedItemColor: AppColors.textMuted,
                  onTap: (idx) => appState.setNav(idx),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      label: appState.t('home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.storefront_rounded),
                      label: appState.t('mandi'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.healing_rounded),
                      label: appState.t('crop_doctor'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.local_shipping_rounded),
                      label: appState.t('logistics'),
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
