import 'package:adminmrz/users/userdetails/detailscreen.dart';
import 'package:adminmrz/users/userdetails/userdetailprovider.dart';
import 'package:adminmrz/users/userprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'model/usermodel.dart';

class UsersPage extends StatefulWidget {
  /// Called when admin taps "Direct Chat" on a member card.
  /// The [userId] is the member's ID. DashboardPage should switch to the
  /// Chat tab and open that user's conversation.
  final void Function(int userId)? onOpenChat;

  const UsersPage({Key? key, this.onOpenChat}) : super(key: key);

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

  String _cleanPhone(String? phone) {
    if (phone == null || phone.isEmpty || phone == 'null') return '';
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Normalises a profile-picture path that may be either a full URL or a
  /// server-relative path (e.g. "/uploads/photo.jpg").  The chat section uses
  /// https://digitallami.com/get.php which returns full URLs; the admin API
  /// may return relative paths – we handle both here.
  static const _kImgBase = 'https://digitallami.com';

  String? _normaliseImageUrl(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'null') return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    // Relative path: prepend domain
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$_kImgBase$path';
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleaned = _cleanPhone(phone);
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchViber(String phone) async {
    final cleaned = _cleanPhone(phone);
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('viber://chat?number=$cleaned');
    bool launched = false;
    if (await canLaunchUrl(uri)) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viber app is not installed on this device'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ─── Verification badge ──────────────────────────────────────────────────

  Widget _verifiedBadge(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVerified
              ? Colors.green.withOpacity(0.4)
              : Colors.red.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.cancel_outlined,
            size: 10,
            color: isVerified ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 3),
          Text(
            isVerified ? 'Verified' : 'Unverified',
            style: TextStyle(
              fontSize: 10,
              color: isVerified ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sendVerifyBtn(BuildContext ctx, String type) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Verification request sent for $type'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, size: 10, color: Colors.blue.shade700),
            const SizedBox(width: 3),
            Text(
              'Send Verification Request',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Communication button ────────────────────────────────────────────────

  Widget _commBtn({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  // ─── User Card ───────────────────────────────────────────────────────────

  Widget _buildUserCard(User user, UserProvider provider) {
    final bool isSelected = provider.isUserSelected(user.id);
    final Color statusColor = user.statusColor;
    final bool isFemale = user.gender.toLowerCase() == 'female';
    final String cleanedPhone = _cleanPhone(user.phone);
    final bool hasPhone = cleanedPhone.isNotEmpty;
    final bool isEmailVerified = user.emailVerified == 1;
    final bool isPhoneVerified = user.phoneVerified == 1;
    final Color genderAccentColor = isFemale ? const Color(0xFFE91E8C) : const Color(0xFF1976D2);
    final String? profileImageUrl = _normaliseImageUrl(user.profilePicture);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: isSelected ? 3 : 1,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: Colors.blue.shade400, width: 1.5)
            : BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToUser(user),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: checkbox + avatar + name/contact + badges ─────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
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
                        activeColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Profile photo
                  GestureDetector(
                    onTap: () => _navigateToUser(user),
                    child: Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isFemale
                                  ? [Colors.pink.shade100, Colors.pink.shade50]
                                  : [Colors.blue.shade100, Colors.blue.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: genderAccentColor.withOpacity(0.35),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: profileImageUrl != null
                                ? Image.network(
                                    profileImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _avatarIcon(isFemale),
                                  )
                                : _avatarIcon(isFemale),
                          ),
                        ),
                        // Online/Offline indicator dot (always visible, like chat section)
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: user.isOnline == 1
                                  ? Colors.green.shade500
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name + contact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full name
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // ID + Gender
                        Row(
                          children: [
                            Text(
                              '#${user.id}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade400,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              ' · ${user.gender}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                user.email.isNotEmpty ? user.email : '—',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _miniVerifiedDot(isEmailVerified),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Phone
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                hasPhone ? cleanedPhone : '—',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasPhone) _miniVerifiedDot(isPhoneVerified),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Status + Plan badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _badge(user.formattedStatus, statusColor),
                      const SizedBox(height: 4),
                      _badge(
                        user.usertype.toUpperCase(),
                        user.usertype.toLowerCase() == 'paid'
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 9),
              Divider(height: 1, thickness: 0.8, color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
              const SizedBox(height: 7),

              // ── Row 2: Info chips ────────────────────────────────────────
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  _infoChip(Icons.calendar_today_outlined,
                      'Reg: ${_formatDate(user.registrationDate)}', Colors.teal),
                  _infoChip(
                    user.isActive == 1
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    user.isActive == 1 ? 'Active' : 'Inactive',
                    user.isActive == 1 ? Colors.green : Colors.red,
                  ),
                  _infoChip(
                    user.isOnline == 1 ? Icons.circle : Icons.circle_outlined,
                    user.isOnline == 1 ? 'Online' : 'Offline',
                    user.isOnline == 1 ? Colors.green : Colors.grey,
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

              const SizedBox(height: 7),
              Divider(height: 1, thickness: 0.8, color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
              const SizedBox(height: 7),

              // ── Row 3: Action buttons (contact LEFT · admin RIGHT) ────────
              Row(
                children: [
                  // Contact buttons
                  if (hasPhone) ...[
                    _actionIconBtn(
                      Icons.chat_rounded,
                      'WhatsApp',
                      const Color(0xFF25D366),
                      () => _launchWhatsApp(cleanedPhone),
                    ),
                    const SizedBox(width: 5),
                    _actionIconBtn(
                      Icons.videocam_rounded,
                      'Viber',
                      const Color(0xFF7360F2),
                      () => _launchViber(cleanedPhone),
                    ),
                    const SizedBox(width: 5),
                  ],
                  if (user.email.isNotEmpty)
                    _actionIconBtn(
                      Icons.email_outlined,
                      'Send Email',
                      Colors.orange,
                      () => _launchEmail(user.email),
                    ),
                  const Spacer(),
                  // Admin actions
                  _actionIconBtn(
                    Icons.chat_bubble_outline,
                    'Direct Chat',
                    Colors.teal,
                    () {
                      if (widget.onOpenChat != null) {
                        widget.onOpenChat!(user.id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening chat…'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 5),
                  _actionIconBtn(
                    Icons.visibility_outlined,
                    'View Profile',
                    Colors.blue,
                    () => _navigateToUser(user),
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
    return Center(
      child: Icon(
        isFemale ? Icons.face_2 : Icons.person,
        size: 24,
        color: isFemale ? Colors.pink.shade300 : Colors.blue.shade300,
      ),
    );
  }

  Widget _miniVerifiedDot(bool isVerified) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isVerified
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.12),
      ),
      child: Icon(
        isVerified ? Icons.check : Icons.close,
        size: 9,
        color: isVerified ? Colors.green.shade600 : Colors.red.shade400,
      ),
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

  // ─── Filter chips row ────────────────────────────────────────────────────

  Widget _buildFilterRow(UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _selectAllChip(provider),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300),
            const SizedBox(width: 10),
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
            Container(width: 1, height: 22, color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300),
            const SizedBox(width: 6),
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
            if (provider.statusFilter != 'all' ||
                provider.userTypeFilter != 'all')
              _filterChip('✕ Clear', true, Colors.red, provider.clearFilters),
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
        return const Color(0xFF6366F1);
      case 'free':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _selectAllChip(UserProvider provider) {
    final bool allSelected = provider.areAllFilteredSelected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: provider.filteredUsers.isNotEmpty
          ? () => provider.selectAllUsers()
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: allSelected ? Colors.blue.shade50 : (isDark ? const Color(0xFF263248) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: allSelected ? Colors.blue.shade300 : (isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300),
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
                color: allSelected ? Colors.blue : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                fontWeight: allSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
      String label, bool selected, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : (isDark ? const Color(0xFF263248) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.45) : (isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ─── Bulk action bar ─────────────────────────────────────────────────────

  Widget _buildBulkActionBar(UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: provider.selectedCount > 0
          ? Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.shade200),
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
                    onPressed: () => provider.suspendSelectedUsers(context),
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
                    onPressed: () => provider.deleteSelectedUsers(context),
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

  // ─── Empty state ─────────────────────────────────────────────────────────

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
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
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

  // ─── Top section: title + search + stats + filters ───────────────────────

  Widget _buildTopSection(UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Row 1: Search bar + Refresh (title shown in dashboard topbar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                // Search bar (takes remaining space)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, phone or ID…',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey.shade400, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.blue.shade300, width: 1.5),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF263248) : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 9, horizontal: 12),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 16),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => provider.setSearchQuery(v),
                  ),
                ),
                const SizedBox(width: 10),
                // Refresh button
                Tooltip(
                  message: 'Refresh',
                  child: InkWell(
                    onTap: () => provider.fetchUsers(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF263248) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: isDark ? Colors.white.withOpacity(0.10) : Colors.grey.shade200),
                      ),
                      child: Icon(Icons.refresh_rounded,
                          size: 18, color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row 2: Stats + vertical divider + filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
            child: Row(
              children: [
                // Stat pills
                if (provider.totalCount > 0) ...[
                  _statPill('Total', provider.totalCount, Colors.blue),
                  const SizedBox(width: 6),
                  _statPill(
                      'Shown', provider.filteredCount, Colors.teal),
                  if (provider.selectedCount > 0) ...[
                    const SizedBox(width: 6),
                    _statPill('Selected', provider.selectedCount,
                        Colors.purple),
                  ],
                  const SizedBox(width: 12),
                  Container(
                      width: 1, height: 22, color: isDark ? Colors.white.withOpacity(0.10) : Colors.grey.shade200),
                  const SizedBox(width: 12),
                ],
                // Select-all chip
                _selectAllChip(provider),
                const SizedBox(width: 8),
                Container(
                    width: 1, height: 22, color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300),
                const SizedBox(width: 8),
                // Status filter chips
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
                Container(
                    width: 1, height: 22, color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300),
                const SizedBox(width: 6),
                // Plan filter chips
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
                if (provider.statusFilter != 'all' ||
                    provider.userTypeFilter != 'all')
                  _filterChip(
                      '✕ Clear', true, Colors.red, provider.clearFilters),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$count ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    // Plain Column — no Scaffold/AppBar to avoid duplicating the "Members"
    // title already shown in dashboard.dart's top bar.
    return Column(
      children: [
        // ── Top section: title + search + stats + filters ─────────────────
        _buildTopSection(provider),

        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

        // ── Scrollable list ──────────────────────────────────────────────
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchUsers(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildBulkActionBar(provider),
                      ),
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
    );
  }
}
