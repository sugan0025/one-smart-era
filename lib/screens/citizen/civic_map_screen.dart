import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/civic_report_model.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';

/// Interactive Civic Complaint Map with Real-Time Marker Filtering
class CivicMapScreen extends StatefulWidget {
  const CivicMapScreen({super.key});

  @override
  State<CivicMapScreen> createState() => _CivicMapScreenState();
}

class _CivicMapScreenState extends State<CivicMapScreen> {
  final MapController _mapController = MapController();
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Roads', 'Water', 'Sanitation', 'Electricity', 'Pending'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appState, dataRepository]),
      builder: (context, _) {
        final reports = dataRepository.reports.where((r) {
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Pending') return r.status == 'Pending';
          return r.category.toLowerCase() == _selectedFilter.toLowerCase();
        }).toList();

        return Scaffold(
          body: Stack(
            children: [
              // OpenStreetMap Canvas
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: appState.userLocation,
                  initialZoom: 14.5,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.onenation_hub',
                  ),

                  // User Location Marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: appState.userLocation,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: 0.25),
                          ),
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Civic Issue Markers
                      ...reports.map((rep) {
                        return Marker(
                          point: rep.loc,
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            onTap: () => _showReportDetailsModal(rep),
                            child: _MapPinMarker(report: rep),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),

              // Top Search & Category Filter Pills
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Header Card
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                            ),
                            Expanded(
                              child: Text(
                                'Civic Map (${reports.length} Issues)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appState.detectedDistrict,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Filter Pills
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final filter = _filters[idx];
                            final isSelected = _selectedFilter == filter;

                            return ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              onSelected: (val) {
                                if (val) setState(() => _selectedFilter = filter);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Center Location Button
              Positioned(
                bottom: 24,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () {
                    _mapController.move(appState.userLocation, 15);
                  },
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDetailsModal(CivicReport rep) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: 28,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
              Text(
                rep.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rep.desc,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_rounded, size: 14, color: AppColors.primaryLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rep.address ?? rep.wardName ?? 'Ward 1',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upvotes: ${rep.upvotes}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final uid = appState.currentUser?.uid ?? '';
                      if (uid.isNotEmpty) {
                        dataRepository.upvoteReport(rep.id, uid);
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.thumb_up_rounded, size: 16),
                    label: const Text('Upvote Issue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapPinMarker extends StatelessWidget {
  final CivicReport report;
  const _MapPinMarker({required this.report});

  @override
  Widget build(BuildContext context) {
    Color pinColor = AppColors.pending;
    if (report.status == 'Resolved') {
      pinColor = AppColors.resolved;
    } else if (report.status == 'Assigned' || report.status == 'In Progress') {
      pinColor = AppColors.assigned;
    } else if (report.isSlaBreached) {
      pinColor = AppColors.danger;
    }

    return Container(
      decoration: BoxDecoration(
        color: pinColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: pinColor.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
