import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';

/// Interactive Government Welfare Scheme Eligibility Calculator
class EligibilityScreen extends StatefulWidget {
  const EligibilityScreen({super.key});

  @override
  State<EligibilityScreen> createState() => _EligibilityScreenState();
}

class _EligibilityScreenState extends State<EligibilityScreen> {
  final _ageController = TextEditingController(text: '32');
  final _incomeController = TextEditingController(text: '180000');
  final _landController = TextEditingController(text: '2.5');

  bool _isTnResident = true;
  List<SchemeModel> _matchingSchemes = [];
  bool _hasCalculated = false;

  @override
  void dispose() {
    _ageController.dispose();
    _incomeController.dispose();
    _landController.dispose();
    super.dispose();
  }

  void _calculateEligibility() {
    final age = int.tryParse(_ageController.text.trim()) ?? 30;
    final income = double.tryParse(_incomeController.text.trim()) ?? 150000;
    final land = double.tryParse(_landController.text.trim()) ?? 0.0;

    final matched = SchemeDirectory.allSchemes.where((scheme) {
      return scheme.isEligible(
        userAge: age,
        userIncome: income,
        landAcres: land,
        isTnResident: _isTnResident,
      );
    }).toList();

    setState(() {
      _matchingSchemes = matched;
      _hasCalculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final isTa = appState.isTamil;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('schemes_calculator')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calculator Form Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Your Demographic Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: t('age'),
                      prefixIcon: const Icon(Icons.cake_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: t('annual_income'),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _landController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: t('land_acres'),
                      prefixIcon: const Icon(Icons.landscape_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // TN Resident Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('is_resident_tn'),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        value: _isTnResident,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isTnResident = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _calculateEligibility,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(t('check_eligibility')),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Matching Results
            if (_hasCalculated) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('eligible_schemes'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_matchingSchemes.length} Matched',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_matchingSchemes.isEmpty)
                EmptyStateWidget(
                  icon: Icons.assignment_late_rounded,
                  title: 'No Matching Schemes',
                  subtitle: 'No government schemes match the specific criteria entered.',
                )
              else
                ..._matchingSchemes.map((scheme) {
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isTa ? scheme.titleTamil : scheme.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTa ? scheme.descriptionTamil : scheme.description,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Benefit: ${scheme.benefitAmount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
