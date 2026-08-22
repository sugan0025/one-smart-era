import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/mock_data.dart';
import '../../core/services/ai_doctor_service.dart';
import '../../models/diagnosis_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/staggered_entrance.dart';

import '../../widgets/laser_scanner_animation.dart';

/// AI Crop Pathology Scanner & Agronomy Remedy Guide
class CropDoctorScreen extends StatefulWidget {
  const CropDoctorScreen({super.key});

  @override
  State<CropDoctorScreen> createState() => _CropDoctorScreenState();
}

class _CropDoctorScreenState extends State<CropDoctorScreen> {
  String _selectedCrop = 'Tomato';
  XFile? _capturedImage;
  bool _isAnalyzing = false;
  DiagnosisEntry? _latestDiagnosis;

  final List<String> _crops = ['Tomato', 'Banana', 'Turmeric', 'Onion', 'Sugarcane', 'Brinjal', 'Potato', 'Coconut'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1000);
      if (img != null) {
        setState(() {
          _capturedImage = img;
          _latestDiagnosis = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking plant image: $e');
    }
  }

  Future<void> _runDiagnosis() async {
    if (_capturedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await AiDoctorService().diagnoseCrop(
        image: _capturedImage!,
        cropName: _selectedCrop,
      );

      if (!mounted) return;

      setState(() {
        _latestDiagnosis = result;
        _isAnalyzing = false;
      });

      appState.addDiagnosis(result);
    } catch (e) {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;
    final isTa = appState.isTamil;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('crop_doctor')),
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
            // Crop Selector Chips
            const Text(
              'Select Infected Crop Type',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _crops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final crop = _crops[idx];
                  final isSelected = _selectedCrop == crop;
                  final displayName = isTa ? (MockData.cropOptionsTamil[crop] ?? crop) : crop;

                  return ChoiceChip(
                    label: Text(displayName),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCrop = crop);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Photo Capture & Preview Card
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  if (_capturedImage == null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.document_scanner_rounded, size: 48, color: AppColors.primaryLight),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('ai_scanner'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('ai_scanner_desc'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: Text(t('camera')),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                            label: Text(t('gallery'), style: const TextStyle(color: AppColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    LaserScannerAnimation(
                      isScanning: _isAnalyzing,
                      scanColor: AppColors.primaryLight,
                      child: Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black38,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: const Center(
                          child: Icon(Icons.eco_rounded, size: 64, color: AppColors.primaryLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _capturedImage = null;
                              _latestDiagnosis = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            child: const Text('Retake', style: TextStyle(color: AppColors.danger)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _runDiagnosis,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.auto_awesome_rounded),
                            label: Text(_isAnalyzing ? 'Analyzing...' : t('diagnose_now')),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Diagnostic Results Card
            if (_latestDiagnosis != null)
              StaggeredEntrance(
                child: GlassCard(
                  customBgColor: const Color(0xFF0F766E).withValues(alpha: 0.25),
                  customBorder: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_latestDiagnosis!.cropName} Diagnosis',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          _SeverityChip(severity: _latestDiagnosis!.severity),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _latestDiagnosis!.diseaseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _DiagnosisDetailSection(
                        title: 'Symptoms Observed',
                        icon: Icons.search_rounded,
                        content: _latestDiagnosis!.symptoms,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 12),

                      _DiagnosisDetailSection(
                        title: 'Organic Herbal Remedy',
                        icon: Icons.eco_rounded,
                        content: _latestDiagnosis!.organicTreatment,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(height: 12),

                      _DiagnosisDetailSection(
                        title: 'Chemical Control (Foliar Spray)',
                        icon: Icons.science_rounded,
                        content: _latestDiagnosis!.chemicalTreatment,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 12),

                      _DiagnosisDetailSection(
                        title: 'Field Prevention Plan',
                        icon: Icons.shield_rounded,
                        content: _latestDiagnosis!.prevention,
                        color: const Color(0xFFA855F7),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;
  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.accent;
    if (severity.toLowerCase().contains('critical') || severity.toLowerCase().contains('high')) {
      color = AppColors.danger;
    } else if (severity.toLowerCase().contains('low')) {
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$severity Severity',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _DiagnosisDetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  final Color color;

  const _DiagnosisDetailSection({
    required this.title,
    required this.icon,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}
