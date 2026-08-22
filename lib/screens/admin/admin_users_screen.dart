import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass_card.dart';

/// Admin User Management Directory (Citizens, Farmers, Municipal Officers)
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';

  late List<AppUser> _usersList;

  @override
  void initState() {
    super.initState();
    _usersList = List.from(AuthService.demoUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _usersList.where((u) {
      if (_selectedRoleFilter != 'All' && u.role != _selectedRoleFilter) return false;
      final q = _searchController.text.toLowerCase().trim();
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: const OneNationAppBar(
        title: 'User Management 👥',
        showWeather: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by citizen name, phone, village...',
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

            // Role Filter Chips
            Row(
              children: ['All', 'Public', 'Farmer', 'Admin'].map((role) {
                final isSelected = _selectedRoleFilter == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(role == 'Public' ? 'Citizens' : (role == 'Farmer' ? 'Farmers' : role)),
                    selected: isSelected,
                    selectedColor: AppColors.secondary,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRoleFilter = role);
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Users List
            if (filteredUsers.isEmpty)
              EmptyStateWidget(
                icon: Icons.person_off_rounded,
                title: 'No Users Found',
                subtitle: 'Try changing search query or role filter.',
              )
            else
              ...filteredUsers.map((u) {
                Color roleColor = AppColors.primary;
                if (u.role == 'Farmer') roleColor = AppColors.accent;
                if (u.role == 'Admin') roleColor = AppColors.secondary;

                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          u.role == 'Farmer'
                              ? Icons.agriculture_rounded
                              : (u.role == 'Admin'
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.person_rounded),
                          color: roleColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (u.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryLight),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${u.phone} • ${u.address}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Civic Points: ${u.civicPoints} • ${u.championBadge}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          u.isVerified ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: u.isVerified ? AppColors.success : AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            u.isVerified = !u.isVerified;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.secondary,
                              content: Text('${u.name} verification status updated.'),
                            ),
                          );
                        },
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
