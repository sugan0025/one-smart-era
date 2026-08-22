import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../providers/data_repository.dart';
import '../widgets/animated_mesh_background.dart';
import 'citizen/public_home_screen.dart';
import 'citizen/civic_map_screen.dart';
import 'citizen/schemes_screen.dart';
import 'citizen/news_feed_screen.dart';
import 'citizen/profile_screen.dart';
import 'citizen/report_screen.dart';
import 'farmer/farmer_home_screen.dart';
import 'farmer/market_screen.dart';
import 'farmer/crop_doctor_screen.dart';
import 'farmer/farmer_logistics_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_analytics_screen.dart';
import 'admin/admin_users_screen.dart';
import 'admin/admin_warehouse_screen.dart';

/// Role-Tailored Main Navigation Shell
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final user = appState.currentUser;
        final role = user?.role ?? 'Public';
        final int currentIndex = appState.navIndex;

        List<Widget> screens;
        List<BottomNavigationBarItem> navItems;
        Color accentColor;

        if (role == 'Farmer') {
          accentColor = AppColors.accent;
          screens = const [
            FarmerHomeScreen(),
            MarketScreen(),
            CropDoctorScreen(),
            FarmerLogisticsScreen(),
            ProfileScreen(),
          ];
          navItems = [
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
          ];
        } else if (role == 'Admin') {
          accentColor = AppColors.secondary;
          screens = const [
            AdminDashboardScreen(),
            AdminAnalyticsScreen(),
            AdminUsersScreen(),
            AdminWarehouseScreen(),
            ProfileScreen(),
          ];
          navItems = [
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
          ];
        } else {
          // Public Citizen
          accentColor = AppColors.primary;
          screens = const [
            PublicHomeScreen(),
            CivicMapScreen(),
            SchemesScreen(),
            NewsFeedScreen(),
            ProfileScreen(),
          ];
          navItems = [
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
          ];
        }

        final safeIndex = currentIndex.clamp(0, screens.length - 1);

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              AnimatedMeshBackground(roleTheme: role),
              IndexedStack(
                index: safeIndex,
                children: screens,
              ),
            ],
          ),
          floatingActionButton: (role == 'Public' && safeIndex == 0)
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  ),
                  backgroundColor: AppColors.primary,
                  elevation: 6,
                  icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                  label: const Text(
                    'Report Issue',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1118).withValues(alpha: 0.82),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: safeIndex,
                  selectedItemColor: accentColor,
                  unselectedItemColor: AppColors.textMuted,
                  onTap: (idx) => appState.setNav(idx),
                  items: navItems,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
