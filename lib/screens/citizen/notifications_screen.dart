import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';

/// In-App Notifications Inbox with Read Markers and Filter
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final t = appState.t;
        final notifs = dataRepository.notifications;

        return Scaffold(
          appBar: AppBar(
            title: Text(t('notifications')),
            actions: [
              if (notifs.isNotEmpty)
                TextButton(
                  onPressed: () => dataRepository.markAllNotificationsRead(),
                  child: Text(t('mark_all_read'), style: const TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                ),
            ],
          ),
          body: notifs.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.notifications_off_rounded,
                  title: t('no_notifications'),
                  subtitle: 'You are all caught up with municipal updates and market alerts.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notifs.length,
                  itemBuilder: (context, idx) {
                    final n = notifs[idx];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      onTap: () => dataRepository.markNotificationRead(n.id),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getNotifIcon(n.type),
                              color: n.isRead ? AppColors.textMuted : AppColors.primaryLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'price_alert':
        return Icons.trending_up_rounded;
      case 'sos_alert':
        return Icons.crisis_alert_rounded;
      case 'report_resolved':
        return Icons.check_circle_rounded;
      case 'logistics_update':
        return Icons.local_shipping_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
