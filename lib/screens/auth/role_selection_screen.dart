import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../widgets/animated_mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';
import 'login_screen.dart';

/// Role Selection Portal (Public Citizen, Farmer, City Official)
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        final t = appState.t;
        return Scaffold(
          body: Stack(
            children: [
              const AnimatedMeshBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Language Toggle & Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'TN Smart Governance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => appState.toggleLang(),
                            icon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                appState.lang == 'en' ? 'தமிழ்' : 'English',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Logo & App Name Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_city_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              t('app_name'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t('app_tagline'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      Text(
                        t('select_role'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Public Citizen Card
                      StaggeredEntrance(
                        index: 0,
                        child: _RoleCard(
                          title: t('role_public'),
                          subtitle: t('role_public_sub'),
                          icon: Icons.people_alt_rounded,
                          accentColor: AppColors.primary,
                          gradient: AppColors.primaryGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(role: 'Public'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Farmer Hub Card
                      StaggeredEntrance(
                        index: 1,
                        child: _RoleCard(
                          title: t('role_farmer'),
                          subtitle: t('role_farmer_sub'),
                          icon: Icons.agriculture_rounded,
                          accentColor: AppColors.accent,
                          gradient: AppColors.accentGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(role: 'Farmer'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. City Official Card
                      StaggeredEntrance(
                        index: 2,
                        child: _RoleCard(
                          title: t('role_admin'),
                          subtitle: t('role_admin_sub'),
                          icon: Icons.admin_panel_settings_rounded,
                          accentColor: AppColors.secondary,
                          gradient: AppColors.blueGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(role: 'Admin'),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Gradient gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: accentColor.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}
