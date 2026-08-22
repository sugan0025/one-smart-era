import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../auth/role_selection_screen.dart';

/// User Profile Screen with Civic Champion Badges, Activity History, and Settings
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final t = appState.t;
        final user = appState.currentUser;
        final userReports = dataRepository.reports
            .where((r) => r.userId == (user?.uid ?? ''))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(t('profile')),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                onPressed: () {
                  appState.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (r) => false,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar & Name Card
                GlassCard(
                  padding: const EdgeInsets.all(22),
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
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user?.name ?? 'Citizen User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.role ?? "Public"} • ${user?.phone ?? ""}',
                        style: const TextStyle(fontSize: 13, color: AppColors.primaryLight),
                      ),
                      const SizedBox(height: 16),

                      // Civic Points & Badges Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${user?.civicPoints ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const Text('Civic Points', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                            Column(
                              children: [
                                Text(
                                  '${userReports.length}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                const Text('Filed Reports', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                            Column(
                              children: [
                                Text(
                                  user?.championBadge.split(' ').first ?? 'Active',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const Text('Rank Badge', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Settings & Preferences Card
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferences & Language',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Language Selector Row
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.translate_rounded, color: AppColors.primaryLight),
                        title: const Text('App Language', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: Text(appState.lang == 'en' ? 'English' : 'தமிழ் (Tamil)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        trailing: OutlinedButton(
                          onPressed: () => appState.toggleLang(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            appState.lang == 'en' ? 'தமிழ்' : 'English',
                            style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_city_rounded, color: AppColors.secondary),
                        title: const Text('Assigned Municipal Ward', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: const Text('Ward 1 • Sathyamangalam APMC', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sign Out Button
                ElevatedButton.icon(
                  onPressed: () {
                    appState.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                      (r) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(t('logout')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
