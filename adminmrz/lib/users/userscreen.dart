import 'package:adminmrz/users/userdetails/detailscreen.dart';
import 'package:adminmrz/users/userdetails/userdetailprovider.dart';
import 'package:adminmrz/users/userprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'model/usermodel.dart';
import 'userdetails/detailmodel.dart';

const _kPrimary = Color(0xFF6366F1);
const _kPrimaryDark = Color(0xFF4F46E5);
const _kViolet = Color(0xFF8B5CF6);
const _kEmerald = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);
const _kRose = Color(0xFFEF4444);
const _kSky = Color(0xFF0EA5E9);

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
          child: UserDetailsScreen(
            userId: user.id,
            myId: user.id,
            onOpenChat: widget.onOpenChat,
            email: user.email,
            phone: user.phone,
          ),
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
            backgroundColor: _kPrimary,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kPrimary.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, size: 10, color: _kPrimaryDark),
            const SizedBox(width: 3),
            Text(
              'Send Verification Request',
              style: TextStyle(
                fontSize: 10,
                color: _kPrimaryDark,
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
    provider.preloadActivity(user.id);
    final activity = provider.activityFor(user.id);
    final isActivityLoading = provider.isActivityLoading(user.id);

    final bool isSelected = provider.isUserSelected(user.id);
    final Color statusColor = user.statusColor;
    final bool isFemale = user.gender.toLowerCase() == 'female';
    final String cleanedPhone = _cleanPhone(user.phone);
    final bool hasPhone = cleanedPhone.isNotEmpty;
    final bool isEmailVerified = user.emailVerified == 1;
    final bool isPhoneVerified = user.phoneVerified == 1;
    final Color genderAccentColor = isFemale ? _kRose : _kSky;
    final String? profileImageUrl = _normaliseImageUrl(user.profilePicture);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardBg,
            isDark ? const Color(0xFF0B1222) : Colors.grey.shade50
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? _kPrimary.withOpacity(0.7)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.shade200),
          width: isSelected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.10 : 0.06),
            blurRadius: isSelected ? 14 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToUser(user),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: selection + avatar + identity + badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => provider.toggleUserSelection(user.id),
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _kPrimary.withOpacity(0.12)
                              : (isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? _kPrimary
                                : Colors.grey.shade400.withOpacity(0.6),
                          ),
                        ),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => provider.toggleUserSelection(user.id),
                          activeColor: _kPrimary,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _navigateToUser(user),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isFemale
                                    ? [const Color(0xFFFCE7F3), const Color(0xFFFFF1F2)]
                                    : [const Color(0xFFE0F2FE), const Color(0xFFEEF2FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: genderAccentColor.withOpacity(0.45),
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
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4)
                                ],
                              ),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: user.isOnline == 1
                                      ? _kEmerald
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.fullName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0B1222),
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _badge(
                                user.formattedStatus,
                                statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _softChip(
                                '#${user.id}',
                                icon: Icons.badge_outlined,
                                color: _kPrimary,
                              ),
                              const SizedBox(width: 6),
                              _softChip(
                                user.gender,
                                icon: isFemale ? Icons.female : Icons.male,
                                color: genderAccentColor,
                              ),
                              const SizedBox(width: 6),
                              _softChip(
                                'Last active ${_formatDate(user.lastLogin)}',
                                icon: Icons.access_time,
                                color: _kSky,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _badge(
                                user.usertype.toUpperCase(),
                                user.usertype.toLowerCase() == 'paid'
                                    ? _kPrimary
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              _badge(
                                user.isActive == 1 ? 'ACTIVE' : 'INACTIVE',
                                user.isActive == 1 ? _kEmerald : _kRose,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _divider(isDark),
                const SizedBox(height: 10),

                // Contact block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _kPrimary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.email_outlined,
                                  size: 14, color: _kPrimary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.email.isNotEmpty ? user.email : 'No email',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade200
                                      : const Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _miniVerifiedDot(isEmailVerified),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _kEmerald.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_outlined,
                                  size: 14, color: _kEmerald),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasPhone ? cleanedPhone : 'No phone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade200
                                      : const Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasPhone) _miniVerifiedDot(isPhoneVerified),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                _divider(isDark),
                const SizedBox(height: 10),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(Icons.calendar_today_outlined,
                        'Reg: ${_formatDate(user.registrationDate)}', _kEmerald),
                    _infoChip(
                      user.isOnline == 1 ? Icons.wifi_tethering : Icons.wifi_off,
                      user.isOnline == 1 ? 'Online' : 'Offline',
                      user.isOnline == 1 ? _kEmerald : Colors.grey,
                    ),
                    if (user.expiryDate != null &&
                        user.expiryDate!.isNotEmpty &&
                        user.expiryDate != 'null')
                      _infoChip(
                        Icons.event_outlined,
                        'Exp: ${_formatDate(user.expiryDate)}',
                        _kAmber,
                      ),
                    if (user.paymentStatus != null &&
                        user.paymentStatus!.isNotEmpty &&
                        user.paymentStatus != 'null')
                      _infoChip(
                        Icons.payment_outlined,
                        user.paymentStatus!,
                        _kViolet,
                      ),
                    _infoChip(
                      Icons.verified_outlined,
                      user.isVerified == 1 ? 'Fully Verified' : 'Needs Review',
                      user.isVerified == 1 ? _kEmerald : _kRose,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _divider(isDark),
                const SizedBox(height: 10),

                // Activity board
                _buildActivityBoard(activity, isActivityLoading, isDark),

                const SizedBox(height: 12),
                _divider(isDark),
                const SizedBox(height: 10),

                // Action buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (hasPhone) ...[
                      _actionIconBtn(
                        Icons.chat_rounded,
                        'WhatsApp',
                        const Color(0xFF25D366),
                        () => _launchWhatsApp(cleanedPhone),
                      ),
                      _actionIconBtn(
                        Icons.videocam_rounded,
                        'Viber',
                        const Color(0xFF7360F2),
                        () => _launchViber(cleanedPhone),
                      ),
                    ],
                    if (user.email.isNotEmpty)
                      _actionIconBtn(
                        Icons.email_outlined,
                        'Send Email',
                        _kAmber,
                        () => _launchEmail(user.email),
                      ),
                    _actionIconBtn(
                      Icons.chat_bubble_outline,
                      'Direct Chat',
                      _kEmerald,
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
                    _actionIconBtn(
                      Icons.visibility_outlined,
                      'View Profile',
                      _kPrimary,
                      () => _navigateToUser(user),
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

  Widget _avatarIcon(bool isFemale) {
    return Center(
      child: Icon(
        isFemale ? Icons.face_2 : Icons.person,
        size: 24,
        color: isFemale ? Colors.pink.shade300 : _kPrimary.withOpacity(0.7),
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
      IconData icon, String title, Color color, VoidCallback onTap) {
    return Tooltip(
      message: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
    );
  }

  Widget _softChip(String label, {required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityPill({
    required String label,
    required IconData icon,
    required Color color,
    int? value,
    bool loading = false,
    double? width,
  }) {
    return Container(
      width: width ?? 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                loading
                    ? SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Text(
                        value != null ? value.toString() : '—',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBoard(ActivityStats? stats, bool loading, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileWidth = constraints.maxWidth < 680
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 24) / 3;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : _kPrimary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kPrimary.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.timeline_outlined, color: _kPrimary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Activity Snapshot',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _kPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (loading)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _activityPill(
                    label: 'Requests Sent',
                    icon: Icons.send_rounded,
                    color: _kPrimary,
                    value: stats?.requestsSent,
                    loading: loading && stats == null,
                    width: tileWidth,
                  ),
                  _activityPill(
                    label: 'Requests Received',
                    icon: Icons.inbox_outlined,
                    color: _kViolet,
                    value: stats?.requestsReceived,
                    loading: loading && stats == null,
                    width: tileWidth,
                  ),
                  _activityPill(
                    label: 'Chat Requests',
                    icon: Icons.chat_bubble_outline,
                    color: _kSky,
                    value: stats?.chatRequestsSent,
                    loading: loading && stats == null,
                    width: tileWidth,
                  ),
                  _activityPill(
                    label: 'Chats Accepted',
                    icon: Icons.check_circle_outline,
                    color: _kEmerald,
                    value: stats?.chatRequestsAccepted,
                    loading: loading && stats == null,
                    width: tileWidth,
                  ),
                  _activityPill(
                    label: 'Profile Views',
                    icon: Icons.visibility_outlined,
                    color: _kAmber,
                    value: stats?.profileViews,
                    loading: loading && stats == null,
                    width: tileWidth,
                  ),
                  _activityPill(
                    label: 'Matches',
                    icon: Icons.favorite_outline,
                    color: _kRose,
                    value: stats?.matchesCount,
                    loading: loading && stats == null,
                    width: tileWidth,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Filter chips row ────────────────────────────────────────────────────

  Widget _buildFilterRow(UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _selectAllChip(provider),
          _filterDivider(isDark),
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
            ];
          }),
          _filterDivider(isDark),
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
            ];
          }),
          if (provider.statusFilter != 'all' ||
              provider.userTypeFilter != 'all')
            _filterChip('✕ Clear', true, _kRose, provider.clearFilters),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return _kEmerald;
      case 'pending':
        return _kAmber;
      case 'rejected':
        return _kRose;
      case 'not_uploaded':
        return Colors.grey.shade600;
      default:
        return _kPrimaryDark;
    }
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'paid':
        return _kPrimary;
      case 'free':
        return _kSky;
      default:
        return _kPrimaryDark;
    }
  }

  Widget _filterDivider(bool isDark) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isDark
          ? Colors.white.withOpacity(0.16)
          : Colors.grey.shade300,
    );
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
          color: allSelected ? _kPrimary.withOpacity(0.12) : (isDark ? const Color(0xFF1C2339) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: allSelected ? _kPrimary.withOpacity(0.8) : (isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              size: 14,
              color: allSelected ? _kPrimary : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              'All',
              style: TextStyle(
                fontSize: 12,
                color: allSelected ? _kPrimary : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                color: isDark ? const Color(0xFF111827) : _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.selectedCount} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    final subtleFill =
        isDark ? Colors.white.withOpacity(0.04) : _kPrimary.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimaryDark, _kViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member Directory',
                      style: TextStyle(
                        color: isDark ? Colors.white : _kPrimaryDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search, filter and action on members in one place.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Refresh',
                child: InkWell(
                  onTap: () => provider.fetchUsers(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : _kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.14)
                            : _kPrimary.withOpacity(0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: isDark ? Colors.white : _kPrimaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: subtleFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade900,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, phone or ID…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: isDark ? Colors.white70 : _kPrimaryDark,
                          size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {});
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      provider.setSearchQuery(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statPill('Total', provider.totalCount,
                      isDark ? Colors.white70 : _kPrimaryDark),
                  _statPill('Shown', provider.filteredCount, _kEmerald),
                  if (provider.selectedCount > 0)
                    _statPill('Selected', provider.selectedCount, _kAmber),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFilterRow(provider),
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
