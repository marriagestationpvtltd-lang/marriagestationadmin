import 'package:adminmrz/theme/app_theme.dart';
import 'package:adminmrz/users/userdetails/detailscreen.dart';
import 'package:adminmrz/users/userdetails/userdetailprovider.dart';
import 'package:adminmrz/users/userprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/usermodel.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToUserDetails(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => UserDetailsProvider(),
          child: UserDetailsScreen(
            userId: user.id,
            myId: user.id,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user, UserProvider provider) {
    final isSelected = provider.isUserSelected(user.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.borderLight,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.radiusLg,
        child: InkWell(
          onTap: () => _navigateToUserDetails(user),
          borderRadius: AppTheme.radiusLg,
          splashColor: AppTheme.primary.withOpacity(0.06),
          highlightColor: AppTheme.primary.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () => provider.toggleUserSelection(user.id),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => provider.toggleUserSelection(user.id),
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Avatar
                    GestureDetector(
                      onTap: () => _navigateToUserDetails(user),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: user.hasProfilePicture
                              ? null
                              : AppTheme.primaryGradient,
                          border: Border.all(
                            color: AppTheme.border,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: user.hasProfilePicture
                            ? ClipOval(
                                child: Image.network(
                                  user.profilePicture!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _defaultAvatar(user),
                                ),
                              )
                            : _defaultAvatar(user),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name / Email / Badges
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToUserDetails(user),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Status + Type badges
                            Row(
                              children: [
                                _statusBadge(user.formattedStatus),
                                const SizedBox(width: 6),
                                _typeBadge(user.usertype),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Details Strip ────────────────────────────────────────────
                GestureDetector(
                  onTap: () => _navigateToUserDetails(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        // Gender
                        Expanded(
                          child: _detailCell(
                            label: 'Gender',
                            icon: user.gender == 'Female'
                                ? Icons.female_rounded
                                : Icons.male_rounded,
                            iconColor: user.gender == 'Female'
                                ? AppTheme.primary
                                : AppTheme.info,
                            value: user.gender,
                          ),
                        ),
                        _vertDivider(),
                        // Online status
                        Expanded(
                          child: _onlineCell(user.isOnline == 1),
                        ),
                        _vertDivider(),
                        // User ID
                        Expanded(
                          child: _detailCell(
                            label: 'User ID',
                            icon: Icons.tag_rounded,
                            iconColor: AppTheme.textMuted,
                            value: '#${user.id}',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Action Row ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToUserDetails(user),
                        icon: const Icon(Icons.person_outline_rounded, size: 15),
                        label: const Text('View Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusMd,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded,
                                  size: 18, color: AppTheme.primary),
                              const SizedBox(width: 10),
                              const Text('View Full Profile'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'message',
                          child: Row(
                            children: [
                              Icon(Icons.message_rounded,
                                  size: 18, color: AppTheme.success),
                              const SizedBox(width: 10),
                              const Text('Send Message'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'email',
                          child: Row(
                            children: [
                              Icon(Icons.email_rounded,
                                  size: 18, color: AppTheme.warning),
                              const SizedBox(width: 10),
                              const Text('Send Email'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'view') {
                          _navigateToUserDetails(user);
                        } else if (value == 'message') {
                          // TODO: Implement send message
                        } else if (value == 'email') {
                          // TODO: Implement send email
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(User user) {
    return Center(
      child: Text(
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status),
        borderRadius: AppTheme.radiusSm,
        border: Border.all(
          color: AppTheme.statusColor(status).withOpacity(0.25),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.statusColor(status),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final isPaid = type.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: isPaid ? AppTheme.goldGradient : null,
        color: isPaid ? null : AppTheme.borderLight,
        borderRadius: AppTheme.radiusSm,
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: isPaid ? Colors.white : AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _detailCell({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _onlineCell(bool isOnline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppTheme.success : AppTheme.textMuted,
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: AppTheme.success.withOpacity(0.4),
                          blurRadius: 4,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOnline ? AppTheme.success : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppTheme.borderLight,
    );
  }

  Widget _buildFilters(BuildContext context, UserProvider provider) {
    final hasActiveFilters =
        provider.statusFilter != 'all' || provider.userTypeFilter != 'all';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tune_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 10),
          const Text(
            'Filter:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          _styledDropdown<String>(
            value: provider.statusFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Status')),
              DropdownMenuItem(value: 'approved', child: Text('Approved')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              DropdownMenuItem(
                  value: 'not_uploaded', child: Text('Not Uploaded')),
            ],
            onChanged: (v) {
              if (v != null) provider.setStatusFilter(v);
            },
          ),
          const SizedBox(width: 8),
          _styledDropdown<String>(
            value: provider.userTypeFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Types')),
              DropdownMenuItem(value: 'paid', child: Text('Paid')),
              DropdownMenuItem(value: 'free', child: Text('Free')),
            ],
            onChanged: (v) {
              if (v != null) provider.setUserTypeFilter(v);
            },
          ),
          const Spacer(),
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.error,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _styledDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, UserProvider provider) {
    final statusStats = provider.getStatusStats();
    final typeStats = provider.getUserTypeStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top stat boxes
          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: 'Total',
                  value: provider.totalCount.toString(),
                  icon: Icons.people_alt_rounded,
                  gradient: AppTheme.primaryGradient,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: 'Filtered',
                  value: provider.filteredCount.toString(),
                  icon: Icons.filter_alt_rounded,
                  gradient: AppTheme.blueGradient,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: 'Selected',
                  value: provider.selectedCount.toString(),
                  icon: Icons.check_circle_rounded,
                  gradient: AppTheme.greenGradient,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Mini chips row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _miniChip('Approved', statusStats['approved'] ?? 0,
                  AppTheme.success, AppTheme.successLight),
              _miniChip('Pending', statusStats['pending'] ?? 0,
                  AppTheme.warning, AppTheme.warningLight),
              _miniChip('Rejected', statusStats['rejected'] ?? 0,
                  AppTheme.error, AppTheme.errorLight),
              _miniChip('Not Uploaded', statusStats['not_uploaded'] ?? 0,
                  AppTheme.textSecondary, const Color(0xFFF3F4F6)),
              _miniChip('Paid', typeStats['paid'] ?? 0,
                  AppTheme.accentDark, const Color(0xFFFFF8E1)),
              _miniChip('Free', typeStats['free'] ?? 0,
                  AppTheme.textSecondary, const Color(0xFFF3F4F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppTheme.radiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, int count, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context, UserProvider provider) {
    if (provider.selectedCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.primaryShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Text(
              '${provider.selectedCount} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => provider.suspendSelectedUsers(context),
              icon: const Icon(Icons.pause_circle_rounded, size: 16),
              label: const Text('Suspend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 9),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusSm,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => provider.deleteSelectedUsers(context),
              icon: const Icon(Icons.delete_rounded, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorLight,
                foregroundColor: AppTheme.error,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 9),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusSm,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: provider.clearSelection,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            tooltip: 'Clear selection',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllRow(BuildContext context, UserProvider provider) {
    if (provider.filteredUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Checkbox(
            value: provider.areAllFilteredSelected,
            onChanged: (_) => provider.selectAllUsers(),
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: AppTheme.textMuted),
          ),
          const SizedBox(width: 6),
          Text(
            provider.areAllFilteredSelected ? 'Deselect All' : 'Select All',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: AppTheme.radiusSm,
            ),
            child: Text(
              '${provider.filteredCount} users',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          if (provider.selectedCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: AppTheme.radiusSm,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.25),
                ),
              ),
              child: Text(
                '${provider.selectedCount} selected',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UserProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.people_alt_rounded,
            size: 44,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          provider.searchQuery.isNotEmpty
              ? 'No results for "${provider.searchQuery}"'
              : 'No users available',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Try adjusting your search or filters',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        if (provider.statusFilter != 'all' || provider.userTypeFilter != 'all')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusSm,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Column(
      children: [
        // ── Search Bar ──────────────────────────────────────────────────────
        Container(
          color: AppTheme.topBarBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or ID…',
                    hintStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppTheme.scaffoldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radiusMd,
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radiusMd,
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radiusMd,
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Refresh',
                child: Material(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: AppTheme.radiusMd,
                  child: InkWell(
                    onTap: () => provider.fetchUsers(),
                    borderRadius: AppTheme.radiusMd,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Main Scrollable Content ─────────────────────────────────────────
        Expanded(
          child: provider.isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading users…',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchUsers(),
                  color: AppTheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Stats
                        _buildStats(context, provider),

                        // Filters
                        _buildFilters(context, provider),

                        // Bulk action bar
                        _buildBulkActionBar(context, provider),

                        // Select-all row
                        _buildSelectAllRow(context, provider),

                        // Empty state or list
                        if (provider.filteredUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: _buildEmptyState(provider),
                          )
                        else ...[
                          // List header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                            child: Row(
                              children: [
                                const Text(
                                  'Users',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: AppTheme.radiusSm,
                                  ),
                                  child: Text(
                                    '${provider.filteredUsers.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Cards
                          ...provider.filteredUsers
                              .map((user) => _buildUserCard(user, provider)),

                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}