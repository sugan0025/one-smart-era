import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/civic_report_model.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';
import '../../widgets/charts/interactive_donut_chart.dart';
import '../../widgets/charts/radial_gauge_card.dart';

/// City Official & Admin Dashboard with Incident Triage & KPI Metrics
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedStatusFilter = 'All';
  final List<String> _statusFilters = ['All', 'Pending', 'Assigned', 'In Progress', 'Resolved'];

  void _showTriageDialog(CivicReport rep) {
    String selectedDept = rep.department ?? 'Roads & Bridges';
    String selectedStatus = rep.status;

    final departments = [
      'Roads & Bridges',
      'Water Supply & Drainage',
      'Sanitation & Solid Waste',
      'TANGEDCO / Street Lights',
      'Public Health & Safety',
    ];

    final statuses = ['Pending', 'Assigned', 'In Progress', 'Resolved'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgDarkCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Text(
                'Triage Report: ${rep.title}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assign Municipal Department:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDept,
                        isExpanded: true,
                        dropdownColor: AppColors.bgDarkCard,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        items: departments.map((d) {
                          return DropdownMenuItem(value: d, child: Text(d));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedDept = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Update Incident Status:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        dropdownColor: AppColors.bgDarkCard,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        items: statuses.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedStatus = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    dataRepository.acceptAndAssignReport(
                      reportId: rep.id,
                      department: selectedDept,
                    );
                    dataRepository.updateReportStatus(
                      reportId: rep.id,
                      newStatus: selectedStatus,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Report ${rep.id} assigned to $selectedDept & status set to $selectedStatus.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                  child: const Text('Save & Dispatch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final reports = dataRepository.reports;
        final totalCount = reports.length;
        final resolvedCount = reports.where((r) => r.status == 'Resolved').length;
        final pendingCount = reports.where((r) => r.status == 'Pending').length;
        final resolutionPercent = totalCount > 0 ? (resolvedCount / totalCount) : 0.89;

        // Department breakdown
        final roads = reports.where((r) => r.category == 'Roads').length.toDouble();
        final water = reports.where((r) => r.category == 'Water').length.toDouble();
        final sanitation = reports.where((r) => r.category == 'Sanitation').length.toDouble();
        final light = reports.where((r) => r.category == 'Street Lights').length.toDouble();
        final health = reports.where((r) => r.category == 'Health').length.toDouble();

        final deptSegments = [
          DonutSegment(label: 'Roads', value: roads > 0 ? roads : 4, color: AppColors.secondary),
          DonutSegment(label: 'Water', value: water > 0 ? water : 3, color: AppColors.primary),
          DonutSegment(label: 'Sanitation', value: sanitation > 0 ? sanitation : 2, color: AppColors.accent),
          DonutSegment(label: 'Electricity', value: light > 0 ? light : 1, color: const Color(0xFFFACC15)),
          DonutSegment(label: 'Health', value: health > 0 ? health : 2, color: AppColors.danger),
        ];

        final filteredReports = reports.where((r) {
          if (_selectedStatusFilter == 'All') return true;
          return r.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
        }).toList();

        return Scaffold(
          appBar: const OneNationAppBar(
            title: 'City Operations HQ 🏛️',
            showWeather: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. KPI Resolution Efficiency Radial Gauge
                StaggeredEntrance(
                  index: 0,
                  child: RadialGaugeCard(
                    title: '⚡ Municipal SLA Resolution Rate',
                    value: resolutionPercent,
                    displayValue: '${(resolutionPercent * 100).toInt()}% Fixed',
                    subtitle: '$pendingCount Grievances Pending Dispatch',
                    primaryColor: AppColors.secondary,
                    warningColor: AppColors.danger,
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Department Workload Donut Breakdown
                StaggeredEntrance(
                  index: 1,
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Department Incident Distribution',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Interactive',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InteractiveDonutChart(
                          segments: deptSegments,
                          size: 190,
                          strokeWidth: 24,
                          centerTitle: 'Total Reports',
                          centerSubtitle: 'City Wide',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Incident Triage Header & Filter Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Citizen Grievances Triage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${filteredReports.length} Shown',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final status = _statusFilters[idx];
                      final isSelected = _selectedStatusFilter == status;

                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: AppColors.secondary,
                        onSelected: (val) {
                          if (val) setState(() => _selectedStatusFilter = status);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // 4. Reports List with Quick Triage Action
                if (filteredReports.isEmpty)
                  EmptyStateWidget(
                    icon: Icons.done_all_rounded,
                    title: 'No Grievances in this Queue',
                    subtitle: 'All civic issues under this filter have been handled.',
                  )
                else
                  ...filteredReports.map((rep) {
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
                                CategoryBadge(category: rep.category),
                                StatusBadgeChip(
                                  status: rep.status,
                                  isSlaBreached: rep.isSlaBreached,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              rep.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rep.desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  '${rep.userName} • ${rep.wardName ?? "Ward 1"}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            if (rep.department != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.business_rounded, size: 13, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Assigned: ${rep.department}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _showTriageDialog(rep),
                                icon: const Icon(Icons.tune_rounded, size: 15),
                                label: const Text('Manage & Assign'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
