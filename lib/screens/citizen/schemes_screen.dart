import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';
import 'eligibility_screen.dart';

/// Welfare Schemes Directory with Category Filtering and Direct Portal Links
class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Farmer', 'Women', 'Health', 'Housing'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openPortal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final isTa = appState.isTamil;

    final filteredSchemes = SchemeDirectory.allSchemes.where((s) {
      if (_selectedCategory != 'All' && s.category != _selectedCategory) return false;
      final q = _searchController.text.toLowerCase().trim();
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          s.titleTamil.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: OneNationAppBar(
        title: t('schemes'),
        showWeather: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Eligibility Calculator Banner
            GlassCard(
              customBgColor: const Color(0xFF0F766E).withValues(alpha: 0.3),
              customBorder: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calculate_rounded, color: AppColors.primaryLight, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('schemes_calculator'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t('schemes_calculator_sub'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryLight, size: 16),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EligibilityScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Search Box
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search schemes (e.g. PM-Kisan, CMCHIS, Magalir)...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            // 3. Category Pills
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;

                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 4. Schemes List
            if (filteredSchemes.isEmpty)
              EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: 'No Matching Schemes',
                subtitle: 'Try changing your search keywords or category filters.',
              )
            else
              ...filteredSchemes.map((scheme) {
                return StaggeredEntrance(
                  child: GlassCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
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
                                scheme.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                            Text(
                              scheme.benefitAmount,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isTa ? scheme.titleTamil : scheme.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTa ? scheme.descriptionTamil : scheme.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: scheme.requiredDocuments.map((doc) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_rounded, size: 11, color: AppColors.primaryLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    doc,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _openPortal(scheme.portalUrl),
                            icon: const Icon(Icons.open_in_new_rounded, size: 14),
                            label: Text(t('apply_now')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
  }
}
