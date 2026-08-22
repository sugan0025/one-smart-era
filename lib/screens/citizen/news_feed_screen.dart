import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';

/// Community Ward Announcements and Interactive Citizen Polls
class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final List<WardNotice> _notices = [
    WardNotice(
      id: 'wn1',
      title: 'Market Road Resurfacing & Pipe Laying',
      body: 'Municipal road reconstruction will be carried out between 10 AM to 4 PM from June 12 to 14. Commuters are requested to use West Car Street alternate route.',
      wardId: 'w1',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    WardNotice(
      id: 'wn2',
      title: 'Drinking Water Pipeline Maintenance',
      body: 'Scheduled overhead tank cleaning and chlorination. Drinking water supply will be paused on Thursday morning for 4 hours.',
      wardId: 'w2',
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    WardNotice(
      id: 'wn3',
      title: 'Ward 1 Grama Sabha & Civic Feedback Meeting',
      body: 'Public consultation on FY 2026-27 infrastructure priority projects at Town Hall, Sunday at 5:00 PM.',
      wardId: 'w1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<Map<String, dynamic>> _polls = [
    {
      'id': 'poll_1',
      'question': 'Which civic project should receive top priority for Ward 1 in the upcoming municipal budget?',
      'options': [
        {'label': 'Underground Drainage System', 'votes': 45},
        {'label': 'LED High-Mast Street Lighting', 'votes': 28},
        {'label': 'New Public Children Park & Gym', 'votes': 37},
      ],
      'userVotedIndex': -1,
    },
    {
      'id': 'poll_2',
      'question': 'Are you satisfied with the daily door-to-door waste collection in your area?',
      'options': [
        {'label': 'Yes, on time daily', 'votes': 52},
        {'label': 'Needs improvement in timing', 'votes': 31},
        {'label': 'Irregular collection', 'votes': 14},
      ],
      'userVotedIndex': -1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final t = appState.t;

    return Scaffold(
      appBar: OneNationAppBar(
        title: t('feed'),
        showWeather: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Official Ward Notices
            Row(
              children: [
                const Icon(Icons.campaign_rounded, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Official Ward Notices',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._notices.map((notice) {
              return StaggeredEntrance(
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ward ${notice.wardId.replaceAll('w', '')}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          Text(
                            '${notice.createdAt.hour}:${notice.createdAt.minute.toString().padLeft(2, '0')} hrs',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notice.body,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Section 2: Citizen Participation Polls
            Row(
              children: [
                const Icon(Icons.poll_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Civic Decision Polls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._polls.asMap().entries.map((entry) {
              final pollIdx = entry.key;
              final poll = entry.value;
              final options = poll['options'] as List<Map<String, dynamic>>;
              final int totalVotes = options.fold(0, (sum, opt) => sum + (opt['votes'] as int));
              final int userVote = poll['userVotedIndex'] as int;

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll['question'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    ...options.asMap().entries.map((optEntry) {
                      final optIdx = optEntry.key;
                      final opt = optEntry.value;
                      final int votes = opt['votes'] as int;
                      final double percent = totalVotes > 0 ? (votes / totalVotes) : 0.0;
                      final bool isSelected = userVote == optIdx;

                      return GestureDetector(
                        onTap: () {
                          if (userVote == -1) {
                            setState(() {
                              opt['votes'] = votes + 1;
                              poll['userVotedIndex'] = optIdx;
                            });
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      opt['label'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(percent * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$totalVotes total citizen votes',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
