import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../providers/data_repository.dart';
import '../../widgets/glass_card.dart';

/// Citizen Grievance Filing Screen with Camera & GPS Geotagging
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCategory = 'Roads';
  XFile? _selectedImage;
  LatLng _reportLocation = appState.userLocation;
  bool _isLocating = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Roads', 'icon': Icons.add_road_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Water', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF0EA5E9)},
    {'name': 'Sanitation', 'icon': Icons.delete_sweep_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Electricity', 'icon': Icons.electric_bolt_rounded, 'color': Color(0xFFEAB308)},
    {'name': 'Health', 'icon': Icons.local_hospital_rounded, 'color': Color(0xFFEF4444)},
    {'name': 'Other', 'icon': Icons.report_problem_rounded, 'color': Color(0xFF94A3B8)},
  ];

  @override
  void initState() {
    super.initState();
    _reportLocation = appState.userLocation;
    _reverseGeocode(_reportLocation);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
      if (img != null) {
        setState(() => _selectedImage = img);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _detectGPS() async {
    setState(() => _isLocating = true);
    await appState.determinePosition();
    setState(() {
      _reportLocation = appState.userLocation;
      _isLocating = false;
    });
    await _reverseGeocode(_reportLocation);
  }

  Future<void> _reverseGeocode(LatLng loc) async {
    try {
      final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addr = '${p.street != null && p.street!.isNotEmpty ? '${p.street}, ' : ''}${p.subLocality ?? ''}, ${p.locality ?? 'Sathyamangalam'}, ${p.administrativeArea ?? 'Tamil Nadu'}';
        if (mounted) {
          setState(() {
            _addressController.text = addr.replaceAll(RegExp(r',\s*,'), ',').trim();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        _addressController.text = 'Near Market Road, Sathyamangalam (Lat: ${loc.latitude.toStringAsFixed(4)}, Lng: ${loc.longitude.toStringAsFixed(4)})';
      }
    }
  }

  Future<void> _submitReport() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final address = _addressController.text.trim();
    final user = appState.currentUser;

    if (title.isEmpty) {
      _showSnackBar('Please enter a title for the issue.', isError: true);
      return;
    }
    if (desc.isEmpty) {
      _showSnackBar('Please describe the issue in detail.', isError: true);
      return;
    }

    if (user == null) {
      _showSnackBar('Please sign in to file complaints.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await dataRepository.saveReport(
        title: title,
        desc: desc,
        category: _selectedCategory,
        loc: _reportLocation,
        address: address.isNotEmpty ? address : 'Sathyamangalam Area',
        image: _selectedImage,
        user: user,
      );

      if (!mounted) return;

      if (success) {
        appState.addCivicPoints(20);
        _showSnackBar(appState.t('report_success'), isError: false);
        Navigator.pop(context);
      } else {
        _showSnackBar(appState.t('error_generic'), isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar(appState.t('error_generic'), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = appState.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('report')),
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
            // Category Selector
            Text(
              t('report_category'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat['name'];
                  final color = cat['color'] as Color;

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 15, color: isSelected ? Colors.white : color),
                        const SizedBox(width: 6),
                        Text(cat['name'] as String),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat['name'] as String);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Form Inputs Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: t('report_title'),
                      hintText: 'e.g. Broken water pipe or Pothole',
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: t('report_desc'),
                      hintText: 'Describe location details, severity, and hazards...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: t('report_address'),
                      prefixIcon: const Icon(Icons.location_on_rounded),
                      suffixIcon: IconButton(
                        icon: _isLocating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, color: AppColors.primaryLight),
                        onPressed: _isLocating ? null : _detectGPS,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Photo Attachment Card
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('pick_image'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedImage != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedImage = null),
                          child: const Text('Remove Photo', style: TextStyle(color: AppColors.danger)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_selectedImage == null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
                            label: Text(t('camera'), style: const TextStyle(color: AppColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                            label: Text(t('gallery'), style: const TextStyle(color: AppColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black26,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: const Icon(Icons.image_rounded, size: 64, color: AppColors.primaryLight),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedImage!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      t('submit_report'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
