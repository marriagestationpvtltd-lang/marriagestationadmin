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

  void _navigateToUser(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => UserDetailsProvider(),
          child: UserDetailsScreen(userId: user.id, myId: user.id),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'null') return '—';
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  // ─── User Card ───────────────────────────────────────────────────────────

  Widget _buildUserCard(User user, UserProvider provider) {
    final bool isSelected = provider.isUserSelected(user.id);
    final Color statusColor = user.statusColor;
    final bool isFemale = user.gender.toLowerCase() == 'female';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: isSelected ? 3 : 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.blue.shade400, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToUser(user),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: checkbox + avatar + name/email + badges ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox (stops card navigation)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => provider.toggleUserSelection(user.id),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => provider.toggleUserSelection(user.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Avatar
                  GestureDetector(
                    onTap: () => _navigateToUser(user),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFemale
                            ? Colors.pink.shade50
                            : Colors.blue.shade50,
                        border: Border.all(
                          color: isFemale
                              ? Colors.pink.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: user.hasProfilePicture
                          ? ClipOval(
                              child: Image.network(
                                user.profilePicture!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarIcon(isFemale),
                              ),
                            )
                          : _avatarIcon(isFemale),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name + Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Status + Plan badges (stacked)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _badge(user.formattedStatus, statusColor),
                      const SizedBox(height: 4),
                      _badge(
                        user.usertype.toUpperCase(),
                        user.usertype.toLowerCase() == 'paid'
                            ? const Color(0xFF6C63FF)
                            : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
              const SizedBox(height: 8),

              // ── Row 2: Info chips ───────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _infoChip(Icons.tag, '#${user.id}', Colors.blueGrey),
                  _infoChip(
                    isFemale ? Icons.female : Icons.male,
                    user.gender,
                    isFemale ? Colors.pink : Colors.blue,
                  ),
                  _infoChip(
                    Icons.calendar_today_outlined,
                    'Reg: ${_formatDate(user.registrationDate)}',
                    Colors.teal,
                  ),
                  _infoChip(
                    user.isActive == 1
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    user.isActive == 1 ? 'Active' : 'Inactive',
                    user.isActive == 1 ? Colors.green : Colors.red,
                  ),
                  if (user.expiryDate != null &&
                      user.expiryDate!.isNotEmpty &&
                      user.expiryDate != 'null')
                    _infoChip(
                      Icons.event_outlined,
                      'Exp: ${_formatDate(user.expiryDate)}',
                      Colors.deepOrange,
                    ),
                  if (user.paymentStatus != null &&
                      user.paymentStatus!.isNotEmpty &&
                      user.paymentStatus != 'null')
                    _infoChip(
                      Icons.payment_outlined,
                      user.paymentStatus!,
                      Colors.purple,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Row 3: Actions ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionIconBtn(
                    Icons.visibility_outlined,
                    'View Profile',
                    Colors.blue,
                    () => _navigateToUser(user),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz,
                        size: 18, color: Colors.grey.shade500),
                    tooltip: 'More actions',
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (_) => [
                      _popupItem('view', Icons.person_outline, 'View Profile',
                          Colors.blue),
                      _popupItem('message', Icons.chat_bubble_outline,
                          'Send Message', Colors.green),
                      _popupItem('email', Icons.email_outlined, 'Send Email',
                          Colors.orange),
                    ],
                    onSelected: (v) {
                      if (v == 'view') {
                        _navigateToUser(user);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coming soon'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarIcon(bool isFemale) {
    return Icon(
      isFemale ? Icons.face_2 : Icons.person,
      size: 22,
      color: isFemale ? Colors.pink : Colors.blue,
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIconBtn(
      IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ─── Filter chips row ─────────────────────────────────────────────────────

  Widget _buildFilterRow(UserProvider provider) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Select-all toggle
            _selectAllChip(provider),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: Colors.grey.shade300),
            const SizedBox(width: 10),
            // Status filters
            ...[
              ('all', 'All'),
              ('approved', 'Approved'),
              ('pending', 'Pending'),
              ('rejected', 'Rejected'),
              ('not_uploaded', 'Not Uploaded'),
            ].expand((e) {
                  final (key, label) = e;
                  return [
                    _filterChip(
                      label,
                      provider.statusFilter == key,
                      _statusColor(key),
                      () => provider.setStatusFilter(key),
                    ),
                    const SizedBox(width: 6),
                  ];
                }),
            Container(width: 1, height: 22, color: Colors.grey.shade300),
            const SizedBox(width: 6),
            // Plan filters
            ...[
              ('all', 'All Plans'),
              ('paid', 'Paid'),
              ('free', 'Free'),
            ].expand((e) {
                  final (key, label) = e;
                  return [
                    _filterChip(
                      label,
                      provider.userTypeFilter == key,
                      _planColor(key),
                      () => provider.setUserTypeFilter(key),
                    ),
                    const SizedBox(width: 6),
                  ];
                }),
            // Clear filters button (only if filters active)
            if (provider.statusFilter != 'all' ||
                provider.userTypeFilter != 'all')
              _filterChip(
                  '✕ Clear', true, Colors.red, provider.clearFilters),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'not_uploaded':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'paid':
        return const Color(0xFF6C63FF);
      case 'free':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _selectAllChip(UserProvider provider) {
    final bool allSelected = provider.areAllFilteredSelected;
    return GestureDetector(
      onTap: provider.filteredUsers.isNotEmpty
          ? () => provider.selectAllUsers()
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: allSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: allSelected ? Colors.blue.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 14,
              color: allSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              'All',
              style: TextStyle(
                fontSize: 12,
                color:
                    allSelected ? Colors.blue : Colors.grey.shade700,
                fontWeight:
                    allSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
      String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.45) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ─── Bulk action bar ──────────────────────────────────────────────────────

  Widget _buildBulkActionBar(UserProvider provider) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: provider.selectedCount > 0
          ? Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.selectedCount} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        provider.suspendSelectedUsers(context),
                    icon: const Icon(Icons.pause_circle_outline, size: 15),
                    label: const Text('Suspend'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 2),
                  TextButton.icon(
                    onPressed: () =>
                        provider.deleteSelectedUsers(context),
                    icon: const Icon(Icons.delete_outline, size: 15),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: provider.clearSelection,
                    child: Icon(Icons.close,
                        size: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(UserProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'No results for "${provider.searchQuery}"'
                  : 'No members found',
              style:
                  TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
            if (provider.statusFilter != 'all' ||
                provider.userTypeFilter != 'all')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: provider.clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Members'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        actions: [
          if (provider.totalCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.filteredCount == provider.totalCount
                      ? '${provider.totalCount}'
                      : '${provider.filteredCount}/${provider.totalCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchUsers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar (always visible, pinned at top) ─────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email or ID…',
                hintStyle:
                    TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.grey.shade400, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.blue.shade300, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                provider.setSearchQuery(v);
              },
            ),
          ),

          // ── Filter chips ────────────────────────────────────────────────
          _buildFilterRow(provider),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // ── Scrollable list ─────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.fetchUsers(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Bulk action bar
                        SliverToBoxAdapter(
                          child: _buildBulkActionBar(provider),
                        ),

                        // Empty state or list
                        if (provider.filteredUsers.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildEmptyState(provider),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildUserCard(
                                  provider.filteredUsers[index],
                                  provider,
                                ),
                                childCount: provider.filteredUsers.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
