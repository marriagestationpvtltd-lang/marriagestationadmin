import 'package:adminmrz/document/docprovider/docservice.dart';
import 'package:adminmrz/theme/app_theme.dart';
import 'package:adminmrz/users/userdetails/detailscreen.dart';
import 'package:adminmrz/users/userdetails/userdetailprovider.dart';
import 'package:adminmrz/users/userprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'model/usermodel.dart';

// Stat card config (soft colours, no heavy gradients)
class _StatConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final String key;
  const _StatConfig(this.label, this.icon, this.color, this.bg, this.key);
}

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  User? _previewUser;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  static const _statCards = [
    _StatConfig('Total',    Icons.people_alt_rounded,        Color(0xFF7C3AED), Color(0xFFF5F3FF), 'all'),
    _StatConfig('Verified', Icons.verified_rounded,          Color(0xFF059669), Color(0xFFECFDF5), 'verified'),
    _StatConfig('Pending',  Icons.pending_actions_rounded,   Color(0xFFD97706), Color(0xFFFFFBEB), 'pending'),
    _StatConfig('Approved', Icons.check_circle_rounded,      Color(0xFF16A34A), Color(0xFFF0FDF4), 'approved'),
    _StatConfig('Paid',     Icons.workspace_premium_rounded, Color(0xFF9333EA), Color(0xFFFAF5FF), 'paid'),
    _StatConfig('Online',   Icons.circle,                    Color(0xFF0EA5E9), Color(0xFFF0F9FF), 'online'),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _openPreview(User user) {
    setState(() => _previewUser = user);
    _slideController.forward();
  }

  void _closePreview() {
    _slideController.reverse().then((_) {
      if (mounted) setState(() => _previewUser = null);
    });
  }

  void _navigateToUserDetails(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => UserDetailsProvider(),
          child: UserDetailsScreen(userId: user.id, myId: user.id),
        ),
      ),
    );
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _approveUserDocument(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Document'),
        content: Text('Approve document for ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final docProvider = context.read<DocumentsProvider>();
    final success = await docProvider.updateDocumentStatus(userId: user.id, action: 'approve');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Document approved' : (docProvider.error ?? 'Failed to approve')),
      backgroundColor: success ? AppTheme.success : Colors.red,
    ));
    if (success) context.read<UserProvider>().fetchUsers(forceRefresh: true);
  }

  Future<void> _rejectUserDocument(User user) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject document for ${user.fullName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final docProvider = context.read<DocumentsProvider>();
    final success = await docProvider.updateDocumentStatus(
      userId: user.id,
      action: 'reject',
      rejectReason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Document rejected' : (docProvider.error ?? 'Failed to reject')),
      backgroundColor: success ? AppTheme.error : Colors.red,
    ));
    if (success) context.read<UserProvider>().fetchUsers(forceRefresh: true);
  }

  Future<void> _blockUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block Member'),
        content: Text('Block ${user.fullName}? They will no longer be able to access the platform.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<UserProvider>().suspendUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? '${user.fullName} has been blocked' : 'Failed to block member. Please try again.'),
      backgroundColor: success ? AppTheme.error : Colors.red,
    ));
  }

  static const Duration _transitionDuration = Duration(milliseconds: 200);

  Widget _buildHeader(UserProvider provider) {
    final hasSelection = provider.selectedCount > 0;
    return AnimatedContainer(
      duration: _transitionDuration,
      color: hasSelection ? AppTheme.primary : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: hasSelection ? _buildBulkActionRow(provider) : _buildTitleRow(provider),
    );
  }

  Widget _buildTitleRow(UserProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage Members',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: AppTheme.radiusSm),
                    child: Text('${provider.totalCount} total',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  const Text('Marriage Station', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Refresh',
          child: InkWell(
            onTap: () => provider.fetchUsers(forceRefresh: true),
            borderRadius: AppTheme.radiusSm,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionRow(UserProvider provider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: AppTheme.radiusSm),
          child: Text('${provider.selectedCount} selected',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Expanded(child: _bulkBtn('Suspend', Icons.pause_circle_rounded, Colors.white.withOpacity(0.15), Colors.white,
            () => provider.suspendSelectedUsers(context))),
        const SizedBox(width: 6),
        Expanded(child: _bulkBtn('Delete', Icons.delete_rounded, AppTheme.errorLight, AppTheme.error,
            () => provider.deleteSelectedUsers(context))),
        const SizedBox(width: 4),
        IconButton(
          onPressed: provider.clearSelection,
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          tooltip: 'Clear selection',
        ),
      ],
    );
  }

  Widget _buildStatCards(UserProvider provider) {
    final statusStats = provider.getStatusStats();
    final typeStats = provider.getUserTypeStats();
    final onlineCount = provider.allUsers.where((u) => u.isOnline == 1).length;
    final verifiedCount = provider.allUsers.where((u) => u.isVerified == 1).length;
    final counts = [
      provider.totalCount, verifiedCount,
      statusStats['pending'] ?? 0, statusStats['approved'] ?? 0,
      typeStats['paid'] ?? 0, onlineCount,
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_statCards.length, (i) {
            final cfg = _statCards[i];
            final isActive = provider.statFilter == cfg.key;
            return Padding(
              padding: EdgeInsets.only(right: i < _statCards.length - 1 ? 8 : 0),
              child: _buildStatCard(cfg, counts[i], isActive, provider),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatConfig cfg, int count, bool isActive, UserProvider provider) {
    return GestureDetector(
      onTap: () => provider.setStatFilter(cfg.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? cfg.color : Colors.white,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: isActive ? cfg.color : AppTheme.border, width: isActive ? 1.5 : 1),
          boxShadow: isActive
              ? [BoxShadow(color: cfg.color.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.25) : cfg.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(cfg.icon, size: 14, color: isActive ? Colors.white : cfg.color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(count.toString(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : AppTheme.textPrimary, height: 1.1)),
                Text(cfg.label,
                    style: TextStyle(fontSize: 11,
                        color: isActive ? Colors.white.withOpacity(0.85) : AppTheme.textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilterBar(UserProvider provider) {
    final hasFilters = provider.statusFilter != 'all' || provider.userTypeFilter != 'all' || provider.genderFilter != 'all';
    return Container(
      color: AppTheme.scaffoldBg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search name, email or ID\u2026',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: AppTheme.radiusMd, borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMd, borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: AppTheme.radiusMd, borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 15, color: AppTheme.textMuted),
                            onPressed: () { _searchController.clear(); provider.setSearchQuery(''); setState(() {}); },
                          )
                        : null,
                  ),
                  onChanged: (v) { provider.setSearchQuery(v); setState(() {}); },
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Clear all filters',
                  child: GestureDetector(
                    onTap: () { provider.clearFilters(); _searchController.clear(); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.errorLight,
                        borderRadius: AppTheme.radiusSm,
                        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.filter_alt_off_rounded, size: 17, color: AppTheme.error),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _compactDropdown<String>(
                  value: provider.statusFilter,
                  items: const {'all': 'All Status', 'approved': 'Approved', 'pending': 'Pending', 'rejected': 'Rejected', 'not_uploaded': 'Not Uploaded'},
                  onChanged: provider.setStatusFilter,
                ),
                const SizedBox(width: 8),
                _compactDropdown<String>(
                  value: provider.userTypeFilter,
                  items: const {'all': 'All Plans', 'paid': 'Paid', 'free': 'Free'},
                  onChanged: provider.setUserTypeFilter,
                ),
                const SizedBox(width: 8),
                _compactDropdown<String>(
                  value: provider.genderFilter,
                  items: const {'all': 'All Gender', 'Male': 'Male', 'Female': 'Female'},
                  onChanged: provider.setGenderFilter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactDropdown<T>({required T value, required Map<T, String> items, required ValueChanged<T> onChanged}) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusSm, border: Border.all(color: AppTheme.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.textSecondary),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          onChanged: (v) { if (v != null) onChanged(v); },
          items: items.entries.map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value))).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectAllRow(UserProvider provider) {
    if (provider.filteredUsers.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusSm, border: Border.all(color: AppTheme.borderLight)),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
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
          Text(provider.areAllFilteredSelected ? 'Deselect All' : 'Select All',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(width: 5),
          Text('(${provider.filteredCount})', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const Spacer(),
          if (provider.selectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: AppTheme.radiusSm),
              child: Text('${provider.selectedCount} selected',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(User user, UserProvider provider) {
    final isSelected = provider.isUserSelected(user.id);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.04) : Colors.white,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(
          color: isSelected ? AppTheme.primary.withOpacity(0.3) : AppTheme.borderLight,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => provider.toggleUserSelection(user.id),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: AppTheme.textMuted),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openPreview(user),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user.hasProfilePicture ? null : AppTheme.primaryGradient,
                      border: Border.all(color: AppTheme.border, width: 1),
                    ),
                    child: user.hasProfilePicture
                        ? ClipOval(child: Image.network(user.profilePicture!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultAvatar(user)))
                        : _defaultAvatar(user),
                  ),
                  if (user.isOnline == 1)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(
                          color: AppTheme.success, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(user.fullName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (user.isVerified == 1) ...[
                        const SizedBox(width: 3),
                        const Tooltip(message: 'Verified',
                            child: Icon(Icons.verified_rounded, size: 12, color: AppTheme.info)),
                      ],
                      const SizedBox(width: 4),
                      Text('#${user.id}',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 4, runSpacing: 3,
                    children: [
                      _statusBadge(user.formattedStatus, user.status),
                      _typeBadge(user.usertype),
                      if (user.gender.isNotEmpty) _genderBadge(user.gender),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 10, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(_formatLastLogin(user.lastLogin),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBtn(Icons.visibility_rounded, AppTheme.info, 'View Profile', () => _openPreview(user)),
                if (user.isPending) ...[
                  const SizedBox(width: 2),
                  _iconBtn(Icons.check_rounded, AppTheme.success, 'Approve', () => _approveUserDocument(user)),
                  const SizedBox(width: 2),
                  _iconBtn(Icons.close_rounded, AppTheme.error, 'Reject', () => _rejectUserDocument(user)),
                ],
                const SizedBox(width: 2),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 17, color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                  offset: const Offset(0, 28),
                  tooltip: 'More options',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  itemBuilder: (_) => [
                    _popupItem('view', Icons.person_rounded, 'View Full Profile', AppTheme.primary),
                    _popupItem('email', Icons.email_outlined, 'Send Email', AppTheme.warning),
                    const PopupMenuDivider(),
                    _popupItem('block', Icons.block_rounded, 'Block Member', AppTheme.error),
                  ],
                  onSelected: (v) {
                    if (v == 'view') _navigateToUserDetails(user);
                    if (v == 'email') _sendEmail(user.email);
                    if (v == 'block') _blockUser(user);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(User user) {
    return Stack(
      children: [
        GestureDetector(onTap: _closePreview, child: Container(color: Colors.black.withOpacity(0.35))),
        Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(-4, 0))],
              ),
              child: Column(
                children: [
                  Container(
                    color: AppTheme.primary,
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(
                      children: [
                        const Text('Member Profile',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          onPressed: _closePreview,
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 72, height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: user.hasProfilePicture ? null : AppTheme.primaryGradient,
                                        border: Border.all(color: AppTheme.border, width: 2),
                                      ),
                                      child: user.hasProfilePicture
                                          ? ClipOval(child: Image.network(user.profilePicture!, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _defaultAvatar(user, size: 24)))
                                          : _defaultAvatar(user, size: 24),
                                    ),
                                    if (user.isVerified == 1)
                                      Positioned(
                                        right: 0, bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          child: const Icon(Icons.verified_rounded, size: 16, color: AppTheme.info),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(user.fullName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 2),
                                Text(user.email,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4, runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _statusBadge(user.formattedStatus, user.status),
                                    _typeBadge(user.usertype),
                                    if (user.gender.isNotEmpty) _genderBadge(user.gender),
                                    if (user.isOnline == 1) _pillBadge('Online', AppTheme.success, AppTheme.successLight),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppTheme.borderLight),
                          const SizedBox(height: 10),
                          _panelInfoRow(Icons.tag_rounded, AppTheme.textMuted, 'Member ID', '#${user.id}'),
                          _panelInfoRow(Icons.access_time_rounded, AppTheme.textMuted, 'Last Active', _formatLastLogin(user.lastLogin)),
                          _panelInfoRow(
                            user.gender == 'Female' ? Icons.female_rounded : Icons.male_rounded,
                            user.gender == 'Female' ? AppTheme.primary : AppTheme.info,
                            'Gender', user.gender,
                          ),
                          _panelInfoRow(
                            Icons.workspace_premium_rounded,
                            user.usertype == 'paid' ? const Color(0xFF9333EA) : AppTheme.textMuted,
                            'Plan', user.usertype.toUpperCase(),
                          ),
                          _panelInfoRow(Icons.shield_rounded, AppTheme.textMuted, 'Privacy', user.privacy.toUpperCase()),
                          const SizedBox(height: 14),
                          const Divider(color: AppTheme.borderLight),
                          const SizedBox(height: 10),
                          const Text('QUICK ACTIONS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.8)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _panelActionBtn('Full Profile', Icons.person_rounded, AppTheme.primary,
                                  () { _closePreview(); _navigateToUserDetails(user); })),
                              const SizedBox(width: 6),
                              if (user.isPending) ...[
                                Expanded(child: _panelActionBtn('Approve', Icons.check_rounded, AppTheme.success,
                                    () { _closePreview(); _approveUserDocument(user); })),
                                const SizedBox(width: 6),
                                Expanded(child: _panelActionBtn('Reject', Icons.close_rounded, AppTheme.error,
                                    () { _closePreview(); _rejectUserDocument(user); })),
                              ] else ...[
                                Expanded(child: _panelActionBtn('Email', Icons.email_rounded, AppTheme.warning,
                                    () => _sendEmail(user.email))),
                                const SizedBox(width: 6),
                                Expanded(child: _panelActionBtn('Block', Icons.block_rounded, AppTheme.error,
                                    () { _closePreview(); _blockUser(user); })),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(UserProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68, height: 68,
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
            child: const Icon(Icons.people_alt_rounded, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            provider.searchQuery.isNotEmpty ? 'No results for "${provider.searchQuery}"' : 'No members found',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text('Try adjusting your search or filters',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          if (provider.statusFilter != 'all' || provider.userTypeFilter != 'all' || provider.genderFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: OutlinedButton.icon(
                onPressed: provider.clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
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

  Widget _iconBtn(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 16, color: color)),
        ),
      ),
    );
  }

  Widget _panelInfoRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _panelActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: AppTheme.radiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: AppTheme.radiusSm),
      child: Text(label, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w700)),
    );
  }

  Widget _bulkBtn(String label, IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return Material(
      color: bg,
      borderRadius: AppTheme.radiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status),
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: AppTheme.statusColor(status).withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9, color: AppTheme.statusColor(status), fontWeight: FontWeight.w700)),
    );
  }

  Widget _typeBadge(String type) {
    final isPaid = type.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFFAF5FF) : AppTheme.borderLight,
        borderRadius: AppTheme.radiusSm,
        border: isPaid ? Border.all(color: const Color(0xFF9333EA).withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPaid) ...[
            const Icon(Icons.workspace_premium_rounded, size: 9, color: Color(0xFF9333EA)),
            const SizedBox(width: 2),
          ],
          Text(type.toUpperCase(),
              style: TextStyle(fontSize: 9,
                  color: isPaid ? const Color(0xFF9333EA) : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _genderBadge(String gender) {
    final isFemale = gender.toLowerCase() == 'female';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFemale ? AppTheme.primary.withOpacity(0.08) : AppTheme.info.withOpacity(0.08),
        borderRadius: AppTheme.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFemale ? Icons.female_rounded : Icons.male_rounded, size: 10,
              color: isFemale ? AppTheme.primary : AppTheme.info),
          const SizedBox(width: 2),
          Text(gender,
              style: TextStyle(fontSize: 9,
                  color: isFemale ? AppTheme.primary : AppTheme.info,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _defaultAvatar(User user, {double size = 16}) {
    return Center(
      child: Text(
        user.fullName.isNotEmpty ? String.fromCharCode(user.fullName.runes.first).toUpperCase() : '?',
        style: TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            _buildHeader(provider),
            _buildStatCards(provider),
            _buildSearchFilterBar(provider),
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                            strokeWidth: 2.5,
                          ),
                          SizedBox(height: 12),
                          Text('Loading members\u2026',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchUsers(forceRefresh: true),
                      color: AppTheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSelectAllRow(provider),
                            if (provider.filteredUsers.isEmpty)
                              _buildEmptyState(provider)
                            else
                              ...provider.filteredUsers.map((u) => _buildMemberRow(u, provider)).toList(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
        if (_previewUser != null) _buildSidePanel(_previewUser!),
      ],
    );
  }
}
