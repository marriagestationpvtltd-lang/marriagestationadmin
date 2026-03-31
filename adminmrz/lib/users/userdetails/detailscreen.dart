import 'package:adminmrz/theme/app_theme.dart';
import 'package:adminmrz/users/userdetails/userdetailprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'detailmodel.dart';

class UserDetailsScreen extends StatefulWidget {
  final int userId;
  final int myId;

  const UserDetailsScreen({
    super.key,
    required this.userId,
    required this.myId,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserDetailsProvider>().fetchUserDetails(
            widget.userId,
            widget.myId,
          );
    });
  }

  @override
  void dispose() {
    context.read<UserDetailsProvider>().clearData();
    super.dispose();
  }

  // ─── Profile Completeness ────────────────────────────────────────────────────

  double _calculateProfileCompletion(UserDetailsData data) {
    final personal = data.personalDetail;
    final fields = [
      personal.firstName != 'Not available',
      personal.lastName != 'Not available',
      personal.hasProfilePicture,
      personal.birthDate.isNotEmpty,
      personal.city != 'Not available',
      personal.country != 'Not available',
      personal.heightName != 'Not available',
      personal.religionName != 'Not available',
      personal.communityName != 'Not available',
      personal.motherTongue != 'Not available',
      personal.educationType != 'Not available',
      personal.degree != 'Not available',
      personal.occupationType != 'Not available',
      personal.annualIncome != 'Not available',
      personal.aboutMe.isNotEmpty && personal.aboutMe != 'Not available',
      data.familyDetail.familyType != 'Not available',
      data.familyDetail.fatherStatus != 'Not available',
      data.familyDetail.motherStatus != 'Not available',
      data.lifestyle.diet != 'Not available',
      data.partner.religion != 'Not available',
    ];
    final filled = fields.where((v) => v).length;
    return filled / fields.length;
  }

  // ─── Hero / Profile Header ───────────────────────────────────────────────────

  Widget _buildHeroHeader(PersonalDetail personal) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppTheme.primaryLight.withOpacity(0.3),
              child: personal.hasProfilePicture
                  ? ClipOval(
                      child: Image.network(
                        personal.profilePicture,
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 52,
                            color: Colors.white70,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.person, size: 52, color: Colors.white70),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            personal.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 6),

          // Member ID + location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.badge_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                personal.memberId,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${personal.city}, ${personal.country}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status badges
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildHeroBadge(
                label: personal.userType.toUpperCase(),
                icon: personal.userType == 'paid'
                    ? Icons.workspace_premium
                    : Icons.person_outline,
                color: personal.userType == 'paid'
                    ? AppTheme.accent
                    : Colors.white54,
                textColor: personal.userType == 'paid'
                    ? AppTheme.accentDark
                    : Colors.white70,
                bgColor: personal.userType == 'paid'
                    ? const Color(0xFFFFF8E1)
                    : Colors.white12,
              ),
              _buildHeroBadge(
                label: personal.isVerified == 1
                    ? 'Verified'
                    : 'Pending Verification',
                icon: personal.isVerified == 1
                    ? Icons.verified_user
                    : Icons.pending_actions,
                color: personal.isVerified == 1
                    ? AppTheme.success
                    : AppTheme.warning,
                textColor: personal.isVerified == 1
                    ? AppTheme.success
                    : AppTheme.warning,
                bgColor: personal.isVerified == 1
                    ? AppTheme.successLight
                    : AppTheme.warningLight,
              ),
              if (personal.age != null)
                _buildHeroBadge(
                  label: '${personal.age} yrs · ${personal.maritalStatusName}',
                  icon: Icons.favorite_outline,
                  color: AppTheme.primaryLight,
                  textColor: Colors.white,
                  bgColor: Colors.white12,
                ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroBadge({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppTheme.radiusSm,
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
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Profile Completion Card ─────────────────────────────────────────────────

  Widget _buildCompletionCard(UserDetailsData data) {
    final pct = _calculateProfileCompletion(data);
    final pctInt = (pct * 100).round();
    final Color barColor = pct >= 0.75
        ? AppTheme.success
        : pct >= 0.5
            ? AppTheme.accent
            : AppTheme.error;

    return _buildCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Circle percentage indicator
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
                Center(
                  child: Text(
                    '$pctInt%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: AppTheme.radiusSm,
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pct >= 0.75
                      ? 'Great profile! Highly visible to matches.'
                      : pct >= 0.5
                          ? 'Good start — add more details to boost matches.'
                          : 'Profile needs more information.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────────────────────

  Widget _buildActionButtons(PersonalDetail personal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Approve',
              icon: Icons.check_circle_outline,
              gradient: AppTheme.greenGradient,
              shadows: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              label: 'Suspend',
              icon: Icons.pause_circle_outline,
              gradient: AppTheme.goldGradient,
              shadows: [
                BoxShadow(
                  color: AppTheme.warning.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              label: 'Reject',
              icon: Icons.cancel_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shadows: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required List<BoxShadow> shadows,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppTheme.radiusSm,
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Document Status Card ────────────────────────────────────────────────────

  Widget _buildDocumentStatusCard(PersonalDetail personal) {
    final isVerified = personal.isVerified == 1;
    final hasPhoto = personal.hasProfilePicture;
    final photoReqPending =
        personal.photoRequest.isNotEmpty && personal.photoRequest != '0';

    return _buildCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Document Status', Icons.folder_open_outlined,
              AppTheme.info),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDocBadge(
                  label: 'Identity',
                  status: isVerified ? 'Verified' : 'Pending',
                  icon: isVerified
                      ? Icons.verified_user
                      : Icons.pending_actions,
                  statusColor: isVerified ? AppTheme.success : AppTheme.warning,
                  statusBg: isVerified
                      ? AppTheme.successLight
                      : AppTheme.warningLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDocBadge(
                  label: 'Photo',
                  status: hasPhoto ? 'Uploaded' : 'Missing',
                  icon: hasPhoto ? Icons.photo_camera : Icons.no_photography,
                  statusColor: hasPhoto ? AppTheme.success : AppTheme.error,
                  statusBg:
                      hasPhoto ? AppTheme.successLight : AppTheme.errorLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDocBadge(
                  label: 'Photo Req',
                  status: photoReqPending ? 'Pending' : 'None',
                  icon: photoReqPending
                      ? Icons.hourglass_top_outlined
                      : Icons.check_circle_outline,
                  statusColor:
                      photoReqPending ? AppTheme.warning : AppTheme.textMuted,
                  statusBg: photoReqPending
                      ? AppTheme.warningLight
                      : const Color(0xFFF3F4F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocBadge({
    required String label,
    required String status,
    required IconData icon,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: statusColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── About Me ────────────────────────────────────────────────────────────────

  Widget _buildAboutMeCard(PersonalDetail personal) {
    if (personal.aboutMe.isEmpty || personal.aboutMe == 'Not available') {
      return const SizedBox.shrink();
    }
    return _buildCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('About Me', Icons.format_quote, AppTheme.primary),
          const SizedBox(height: 12),
          Text(
            personal.aboutMe,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Generic section card ────────────────────────────────────────────────────

  Widget _buildCard({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> rows,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _buildSectionHeader(title, icon, accentColor),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: AppTheme.radiusSm,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value,
      {IconData? icon, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: highlight ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.borderLight,
      );

  List<Widget> _rows(List<Widget> entries) {
    final widgets = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      widgets.add(entries[i]);
      if (i < entries.length - 1) widgets.add(_buildDivider());
    }
    return widgets;
  }

  // ─── Section builders ────────────────────────────────────────────────────────

  Widget _buildPersonalDetails(PersonalDetail personal) {
    return _buildSectionCard(
      title: 'Personal Details',
      icon: Icons.person_outline,
      accentColor: AppTheme.primary,
      rows: _rows([
        _buildInfoRow('Height', personal.heightName, icon: Icons.height),
        _buildInfoRow('Religion', personal.religionName, icon: Icons.flag_outlined),
        _buildInfoRow('Blood Group', personal.bloodGroup, icon: Icons.water_drop_outlined),
        _buildInfoRow('Community', personal.communityName, icon: Icons.people_outline),
        _buildInfoRow('Mother Tongue', personal.motherTongue, icon: Icons.language),
        _buildInfoRow('Sub Community', personal.subCommunityName, icon: Icons.group_outlined),
        _buildInfoRow('Manglik', personal.manglik, icon: Icons.star_outline),
        _buildInfoRow('Birth City', personal.birthcity, icon: Icons.place_outlined),
        _buildInfoRow('Disability', personal.disability, icon: Icons.accessible_outlined),
      ]),
    );
  }

  Widget _buildEducationCareer(PersonalDetail personal) {
    return _buildSectionCard(
      title: 'Education & Career',
      icon: Icons.school_outlined,
      accentColor: AppTheme.info,
      rows: _rows([
        _buildInfoRow('Education Type', personal.educationType, icon: Icons.school_outlined, highlight: true),
        _buildInfoRow('Degree', personal.degree, icon: Icons.workspace_premium_outlined),
        _buildInfoRow('Faculty', personal.faculty, icon: Icons.menu_book_outlined),
        _buildInfoRow('Medium', personal.educationMedium, icon: Icons.language),
        _buildInfoRow('Occupation', personal.occupationType, icon: Icons.work_outline, highlight: true),
        _buildInfoRow('Company', personal.companyName, icon: Icons.business_outlined),
        _buildInfoRow('Designation', personal.designation, icon: Icons.badge_outlined),
        _buildInfoRow('Annual Income', personal.annualIncome, icon: Icons.currency_rupee),
      ]),
    );
  }

  Widget _buildFamilyDetails(FamilyDetail family) {
    return _buildSectionCard(
      title: 'Family Details',
      icon: Icons.family_restroom,
      accentColor: const Color(0xFF7C3AED),
      rows: _rows([
        _buildInfoRow('Family Type', family.familyType, icon: Icons.home_outlined),
        _buildInfoRow('Family Background', family.familyBackground, icon: Icons.history_edu_outlined),
        _buildInfoRow('Family Origin', family.familyOrigin, icon: Icons.public_outlined),
        _buildInfoRow('Father Status', family.fatherStatus, icon: Icons.person_outline),
        _buildInfoRow('Father Name', family.fatherName, icon: Icons.person_pin_outlined),
        _buildInfoRow('Father Education', family.fatherEducation, icon: Icons.school_outlined),
        _buildInfoRow('Father Occupation', family.fatherOccupation, icon: Icons.work_outline),
        _buildInfoRow('Mother Status', family.motherStatus, icon: Icons.person_outline),
        _buildInfoRow('Mother Education', family.motherEducation, icon: Icons.school_outlined),
        _buildInfoRow('Mother Occupation', family.motherOccupation, icon: Icons.work_outline),
      ]),
    );
  }

  Widget _buildLifestyle(Lifestyle lifestyle) {
    return _buildSectionCard(
      title: 'Lifestyle',
      icon: Icons.emoji_food_beverage_outlined,
      accentColor: AppTheme.accentDark,
      rows: _rows([
        _buildInfoRow('Diet', lifestyle.diet, icon: Icons.restaurant_outlined, highlight: true),
        _buildInfoRow('Smoking', lifestyle.smoke, icon: Icons.smoking_rooms_outlined),
        _buildInfoRow('Smoke Type', lifestyle.smokeType, icon: Icons.smoke_free_outlined),
        _buildInfoRow('Drinking', lifestyle.drinks, icon: Icons.local_drink_outlined),
        _buildInfoRow('Drink Type', lifestyle.drinkType, icon: Icons.wine_bar_outlined),
      ]),
    );
  }

  Widget _buildPartnerPreference(PartnerPreference partner) {
    return Column(
      children: [
        // Basic Preferences
        _buildSectionCard(
          title: 'Partner Preferences — Basic',
          icon: Icons.favorite_outline,
          accentColor: AppTheme.primary,
          rows: _rows([
            _buildInfoRow('Age Range', partner.ageRange, icon: Icons.calendar_today_outlined),
            _buildInfoRow('Marital Status', partner.maritalStatus, icon: Icons.favorite_border),
            _buildInfoRow('Religion', partner.religion, icon: Icons.flag_outlined),
            _buildInfoRow('Caste', partner.caste, icon: Icons.people_outline),
            _buildInfoRow('Mother Tongue', partner.motherTongue, icon: Icons.language),
            _buildInfoRow('Manglik', partner.manglik, icon: Icons.star_outline),
            _buildInfoRow('Country', partner.country, icon: Icons.public_outlined),
            _buildInfoRow('State', partner.state, icon: Icons.map_outlined),
            _buildInfoRow('City', partner.city, icon: Icons.location_city_outlined),
          ]),
        ),
        // Lifestyle & Education Preferences
        _buildSectionCard(
          title: 'Partner Preferences — Lifestyle',
          icon: Icons.tune_outlined,
          accentColor: AppTheme.accentDark,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          rows: _rows([
            _buildInfoRow('Qualification', partner.qualification, icon: Icons.school_outlined),
            _buildInfoRow('Profession', partner.profession, icon: Icons.work_outline),
            _buildInfoRow('Annual Income', partner.annualIncome, icon: Icons.currency_rupee),
            _buildInfoRow('Diet', partner.diet, icon: Icons.restaurant_outlined),
            _buildInfoRow('Complexion', partner.complexion, icon: Icons.palette_outlined),
            _buildInfoRow('Body Type', partner.bodyType, icon: Icons.accessibility_outlined),
            _buildInfoRow('Smoke Accept', partner.smokeAccept, icon: Icons.smoking_rooms_outlined),
            _buildInfoRow('Drink Accept', partner.drinkAccept, icon: Icons.local_bar_outlined),
            _buildInfoRow('Disability Accept', partner.disabilityAccept, icon: Icons.accessible_outlined),
          ]),
        ),
        // Other Expectations
        if (partner.otherExpectation.isNotEmpty &&
            partner.otherExpectation != 'Not available')
          _buildCard(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                    'Other Expectations', Icons.notes_outlined, AppTheme.primary),
                const SizedBox(height: 12),
                Text(
                  partner.otherExpectation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Loading / Error / Empty states ─────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Profile…',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Consumer<UserDetailsProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.error,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<UserDetailsProvider>().fetchUserDetails(
                      widget.userId,
                      widget.myId,
                    );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_off_outlined,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No User Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The profile could not be loaded.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserDetailsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Member Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: () =>
                provider.fetchUserDetails(widget.userId, widget.myId),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: provider.isLoading
          ? _buildLoadingState()
          : provider.error.isNotEmpty
              ? _buildErrorState()
              : provider.userDetails != null
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Gradient hero header
                          _buildHeroHeader(
                              provider.userDetails!.personalDetail),

                          // Profile completion
                          _buildCompletionCard(provider.userDetails!),

                          // Action buttons
                          _buildActionButtons(
                              provider.userDetails!.personalDetail),

                          // Document status
                          _buildDocumentStatusCard(
                              provider.userDetails!.personalDetail),

                          // About Me
                          _buildAboutMeCard(
                              provider.userDetails!.personalDetail),

                          // Personal details
                          _buildPersonalDetails(
                              provider.userDetails!.personalDetail),

                          // Education & Career
                          _buildEducationCareer(
                              provider.userDetails!.personalDetail),

                          // Family details
                          _buildFamilyDetails(
                              provider.userDetails!.familyDetail),

                          // Lifestyle
                          _buildLifestyle(provider.userDetails!.lifestyle),

                          // Partner preferences
                          _buildPartnerPreference(provider.userDetails!.partner),

                          const SizedBox(height: 32),
                        ],
                      ),
                    )
                  : _buildEmptyState(),
    );
  }
}