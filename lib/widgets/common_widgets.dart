import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state.dart';

/// Semantic Status Badge Chip
class StatusBadgeChip extends StatelessWidget {
  final String status;
  final bool isSlaBreached;

  const StatusBadgeChip({
    super.key,
    required this.status,
    this.isSlaBreached = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'resolved':
        bg = AppColors.resolved.withValues(alpha: 0.18);
        fg = AppColors.resolved;
        icon = Icons.check_circle_rounded;
        break;
      case 'in progress':
        bg = AppColors.inProgress.withValues(alpha: 0.18);
        fg = AppColors.inProgress;
        icon = Icons.autorenew_rounded;
        break;
      case 'assigned':
        bg = AppColors.assigned.withValues(alpha: 0.18);
        fg = AppColors.assigned;
        icon = Icons.assignment_ind_rounded;
        break;
      case 'pending':
      default:
        bg = isSlaBreached
            ? AppColors.danger.withValues(alpha: 0.2)
            : AppColors.pending.withValues(alpha: 0.18);
        fg = isSlaBreached ? AppColors.danger : AppColors.pending;
        icon = isSlaBreached ? Icons.warning_amber_rounded : Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            isSlaBreached ? 'SLA Overdue' : status,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category Badge Icon Chip
class CategoryBadge extends StatelessWidget {
  final String category;
  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (category.toLowerCase()) {
      case 'roads':
        icon = Icons.add_road_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'water':
        icon = Icons.water_drop_rounded;
        color = const Color(0xFF0EA5E9);
        break;
      case 'sanitation':
        icon = Icons.delete_sweep_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'electricity':
        icon = Icons.electric_bolt_rounded;
        color = const Color(0xFFEAB308);
        break;
      case 'health':
        icon = Icons.local_hospital_rounded;
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.report_problem_rounded;
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Animated Counter Number
class AnimatedCounter extends StatelessWidget {
  final int count;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.count,
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '$prefix${val.toInt()}$suffix',
          style: style ??
              const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
        );
      },
    );
  }
}

/// Top Application Bar with Weather, Language Toggle, and Notification Badge
class OneNationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showWeather;
  final bool showLangToggle;
  final VoidCallback? onNotifTap;

  const OneNationAppBar({
    super.key,
    required this.title,
    this.showWeather = true,
    this.showLangToggle = true,
    this.onNotifTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Title / Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        appState.currentUser != null
                            ? '${appState.currentUser!.role} • ${appState.detectedDistrict}'
                            : appState.detectedDistrict,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Weather Capsule
                if (showWeather)
                  GestureDetector(
                    onTap: () => appState.fetchWeather(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(appState.weatherIcon, size: 16, color: AppColors.accent),
                          const SizedBox(width: 5),
                          Text(
                            appState.weatherTemp,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Language Switcher (EN <-> தமிழ்)
                if (showLangToggle)
                  IconButton(
                    onPressed: () => appState.toggleLang(),
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        appState.lang == 'en' ? 'தமிழ்' : 'EN',
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
          ),
        );
      },
    );
  }
}

/// Empty State Placeholder
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, size: 48, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
