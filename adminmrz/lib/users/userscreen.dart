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
  bool _showFilterPanel = false;

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

  // ─── Page Header ────────────────────────────────────────────────────────────

  Widget _buildPageHeader(UserProvider provider) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppTheme.radiusSm,
                      ),
                      child: Text(
                        '${provider.totalCount} total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Marriage Station',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Refresh',
            child: Material(
              color: Colors.white.withOpacity(0.15),
              borderRadius: AppTheme.radiusMd,
              child: InkWell(
                onTap: () => provider.fetchUsers(),
                borderRadius: AppTheme.radiusMd,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Grid ─────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(UserProvider provider) {
    final statusStats = provider.getStatusStats();
    final typeStats = provider.getUserTypeStats();
    final onlineCount = provider.allUsers.where((u) => u.isOnline == 1).length;
    final verifiedCount = provider.allUsers.where((u) => u.isVerified == 1).length;

    final stats = [
      _StatItem('Total', provider.totalCount, Icons.people_alt_rounded, AppTheme.primaryGradient),
      _StatItem('Verified', verifiedCount, Icons.verified_rounded, AppTheme.greenGradient),
      _StatItem('Pending', statusStats['pending'] ?? 0, Icons.pending_rounded, AppTheme.blueGradient),
      _StatItem('Approved', statusStats['approved'] ?? 0, Icons.check_circle_rounded, const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      _StatItem('Paid', typeStats['paid'] ?? 0, Icons.workspace_premium_rounded, AppTheme.goldGradient),
      _StatItem('Online', onlineCount, Icons.circle, AppTheme.purpleGradient),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const cols = 3;
          const rows = 2;
          return Column(
            children: List.generate(rows, (row) {
              final start = row * cols;
              final end = (start + cols).clamp(0, stats.length);
              final rowItems = stats.sublist(start, end);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: rowItems
                      .map((s) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildStatCard(s),
                            ),
                          ))
                      .toList(),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: item.gradient,
        borderRadius: AppTheme.radiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.count.toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search & Filter ─────────────────────────────────────────────────────────

  Widget _buildSearchBar(UserProvider provider) {
    final hasActiveFilters = provider.statusFilter != 'all' ||
        provider.userTypeFilter != 'all' ||
        provider.genderFilter != 'all';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search name, email or ID…',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                filled: true,
                fillColor: AppTheme.cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                provider.setSearchQuery(v);
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Filters',
            child: Material(
              color: hasActiveFilters ? AppTheme.primary : AppTheme.cardBg,
              borderRadius: AppTheme.radiusMd,
              child: InkWell(
                onTap: () => setState(() => _showFilterPanel = !_showFilterPanel),
                borderRadius: AppTheme.radiusMd,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: hasActiveFilters ? AppTheme.primary : AppTheme.border,
                    ),
                    borderRadius: AppTheme.radiusMd,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: hasActiveFilters ? Colors.white : AppTheme.primary,
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(UserProvider provider) {
    if (!_showFilterPanel) return const SizedBox.shrink();

    final hasActiveFilters = provider.statusFilter != 'all' ||
        provider.userTypeFilter != 'all' ||
        provider.genderFilter != 'all';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 15, color: AppTheme.primary),
              const SizedBox(width: 6),
              const Text(
                'Filter Members',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (hasActiveFilters)
                GestureDetector(
                  onTap: () {
                    provider.clearFilters();
                    _searchController.clear();
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _filterDropdown<String>(
                label: 'Status',
                value: provider.statusFilter,
                items: const {
                  'all': 'All Status',
                  'approved': 'Approved',
                  'pending': 'Pending',
                  'rejected': 'Rejected',
                  'not_uploaded': 'Not Uploaded',
                },
                onChanged: provider.setStatusFilter,
              ),
              _filterDropdown<String>(
                label: 'Membership',
                value: provider.userTypeFilter,
                items: const {
                  'all': 'All Types',
                  'paid': 'Paid',
                  'free': 'Free',
                },
                onChanged: provider.setUserTypeFilter,
              ),
              _filterDropdown<String>(
                label: 'Gender',
                value: provider.genderFilter,
                items: const {
                  'all': 'All Gender',
                  'Male': 'Male',
                  'Female': 'Female',
                },
                onChanged: provider.setGenderFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                size: 16,
                color: AppTheme.primary,
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: items.entries
                  .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── User Card ───────────────────────────────────────────────────────────────

  Widget _buildUserCard(User user, UserProvider provider) {
    final isSelected = provider.isUserSelected(user.id);
    final isPending = user.status.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () => provider.toggleUserSelection(user.id),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => provider.toggleUserSelection(user.id),
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Avatar with online dot indicator
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToUserDetails(user),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: user.hasProfilePicture ? null : AppTheme.primaryGradient,
                              border: Border.all(color: AppTheme.border, width: 1.5),
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
                        if (user.isOnline == 1)
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.success.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Name + email + badges
                    Expanded(
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
                              if (user.isVerified == 1) ...[
                                const SizedBox(width: 4),
                                const Tooltip(
                                  message: 'Verified',
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 15,
                                    color: AppTheme.info,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _statusBadge(user.formattedStatus, user.status),
                              _typeBadge(user.usertype),
                              if (user.gender.isNotEmpty) _genderBadge(user.gender),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // More actions menu
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                      offset: const Offset(0, 32),
                      itemBuilder: (context) => [
                        _popupItem('view', Icons.person_rounded, 'View Profile', AppTheme.primary),
                        _popupItem('message', Icons.chat_bubble_outline_rounded, 'Send Message', AppTheme.info),
                        _popupItem('email', Icons.email_outlined, 'Send Email', AppTheme.warning),
                        const PopupMenuDivider(),
                        _popupItem('block', Icons.block_rounded, 'Block Member', AppTheme.error),
                      ],
                      onSelected: (value) {
                        if (value == 'view') _navigateToUserDetails(user);
                        // TODO: implement message / email / block actions
                      },
                    ),
                  ],
                ),

                // ── Info Strip ────────────────────────────────────────────
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      _infoCell(
                        icon: user.gender == 'Female'
                            ? Icons.female_rounded
                            : Icons.male_rounded,
                        iconColor: user.gender == 'Female' ? AppTheme.primary : AppTheme.info,
                        value: user.gender,
                      ),
                      _vertDivider(),
                      Expanded(
                        child: _infoCell(
                          icon: Icons.access_time_rounded,
                          iconColor: AppTheme.textMuted,
                          value: _formatLastLogin(user.lastLogin),
                        ),
                      ),
                      _vertDivider(),
                      _infoCell(
                        icon: Icons.tag_rounded,
                        iconColor: AppTheme.textMuted,
                        value: '#${user.id}',
                      ),
                    ],
                  ),
                ),

                // ── Action Buttons ────────────────────────────────────────
                const SizedBox(height: 10),
                if (isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'Approve',
                          icon: Icons.check_circle_outline_rounded,
                          foreground: AppTheme.success,
                          background: AppTheme.successLight,
                          onTap: () {
                            // TODO: implement approve action
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: 'Reject',
                          icon: Icons.cancel_outlined,
                          foreground: AppTheme.error,
                          background: AppTheme.errorLight,
                          onTap: () {
                            // TODO: implement reject action
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _iconActionButton(
                        icon: Icons.person_outline_rounded,
                        color: AppTheme.primary,
                        tooltip: 'View Profile',
                        onTap: () => _navigateToUserDetails(user),
                      ),
                    ],
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () => _navigateToUserDetails(user),
                    icon: const Icon(Icons.person_outline_rounded, size: 15),
                    label: const Text('View Full Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      minimumSize: const Size.fromHeight(0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: AppTheme.radiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.radiusSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.radiusSm,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(User user) {
    return Center(
      child: Text(
        user.fullName.isNotEmpty
            ? String.fromCharCode(user.fullName.runes.first).toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatLastLogin(String lastLogin) {
    if (lastLogin.isEmpty || lastLogin == 'null') return 'Never';
    try {
      final dt = DateTime.parse(lastLogin);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return lastLogin.length > 10 ? lastLogin.substring(0, 10) : lastLogin;
    }
  }

  Widget _statusBadge(String label, String rawStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(rawStatus),
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: AppTheme.statusColor(rawStatus).withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: AppTheme.statusColor(rawStatus),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final isPaid = type.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: isPaid ? AppTheme.goldGradient : null,
        color: isPaid ? null : AppTheme.borderLight,
        borderRadius: AppTheme.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPaid) ...[
            const Icon(Icons.workspace_premium_rounded, size: 10, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: isPaid ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderBadge(String gender) {
    final isFemale = gender.toLowerCase() == 'female';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isFemale
            ? AppTheme.primary.withOpacity(0.1)
            : AppTheme.info.withOpacity(0.1),
        borderRadius: AppTheme.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFemale ? Icons.female_rounded : Icons.male_rounded,
            size: 11,
            color: isFemale ? AppTheme.primary : AppTheme.info,
          ),
          const SizedBox(width: 2),
          Text(
            gender,
            style: TextStyle(
              fontSize: 10,
              color: isFemale ? AppTheme.primary : AppTheme.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.borderLight,
    );
  }

  // ─── Bulk Action Bar ─────────────────────────────────────────────────────────

  Widget _buildBulkActionBar(BuildContext context, UserProvider provider) {
    if (provider.selectedCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _bulkActionButton(
              label: 'Suspend',
              icon: Icons.pause_circle_rounded,
              onTap: () => provider.suspendSelectedUsers(context),
              color: Colors.white.withOpacity(0.2),
              textColor: Colors.white,
              borderColor: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _bulkActionButton(
              label: 'Delete',
              icon: Icons.delete_rounded,
              onTap: () => provider.deleteSelectedUsers(context),
              color: AppTheme.errorLight,
              textColor: AppTheme.error,
              borderColor: AppTheme.error.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: provider.clearSelection,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  Widget _bulkActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    required Color borderColor,
  }) {
    return Material(
      color: color,
      borderRadius: AppTheme.radiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: AppTheme.radiusSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Select All Row ──────────────────────────────────────────────────────────

  Widget _buildSelectAllRow(UserProvider provider) {
    if (provider.filteredUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: provider.areAllFilteredSelected,
              onChanged: (_) => provider.selectAllUsers(),
              activeColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: AppTheme.textMuted),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.areAllFilteredSelected ? 'Deselect All' : 'Select All',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: AppTheme.radiusSm,
            ),
            child: Text(
              '${provider.filteredCount} members',
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: AppTheme.radiusSm,
                border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
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

  // ─── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(UserProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.primaryShadow,
            ),
            child: const Icon(Icons.people_alt_rounded, size: 38, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            provider.searchQuery.isNotEmpty
                ? 'No results for "${provider.searchQuery}"'
                : 'No members found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (provider.statusFilter != 'all' ||
              provider.userTypeFilter != 'all' ||
              provider.genderFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton.icon(
                onPressed: provider.clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Column(
      children: [
        // Page Header
        _buildPageHeader(provider),

        // Main scrollable content
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
                      const Text(
                        'Loading members…',
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
                        // Stats
                        _buildStatsGrid(provider),

                        // Search bar
                        _buildSearchBar(provider),

                        // Filter panel (collapsible)
                        _buildFilterPanel(provider),

                        // Bulk action bar
                        _buildBulkActionBar(context, provider),

                        // Select all row
                        _buildSelectAllRow(provider),

                        // Member list or empty state
                        if (provider.filteredUsers.isEmpty)
                          _buildEmptyState(provider)
                        else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: Row(
                              children: [
                                const Text(
                                  'Members',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
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
                          ...provider.filteredUsers
                              .map((u) => _buildUserCard(u, provider)),
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

// ─── Helper model for stat cards ─────────────────────────────────────────────

class _StatItem {
  final String label;
  final int count;
  final IconData icon;
  final Gradient gradient;

  const _StatItem(this.label, this.count, this.icon, this.gradient);
}
