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

  Widget _buildProfileHeader(PersonalDetail personal) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade100, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade300, width: 3),
                ),
                child: ClipOval(
                  child: personal.hasProfilePicture
                      ? Image.network(
                    personal.profilePicture,
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
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.blue.shade50,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.blue.shade300,
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.blue.shade50,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Basic Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personal.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        if (personal.age != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.cake,
                                size: 18,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${personal.age} years',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              personal.city,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 18,
                              color: Colors.pink.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              personal.maritalStatusName,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Status Row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: personal.userType == 'paid'
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: personal.userType == 'paid'
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                personal.userType == 'paid'
                                    ? Icons.verified
                                    : Icons.person_outline,
                                size: 14,
                                color: personal.userType == 'paid'
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                personal.userType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: personal.userType == 'paid'
                                      ? Colors.green.shade800
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: personal.isVerified == 1
                                ? Colors.blue.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: personal.isVerified == 1
                                  ? Colors.blue.shade300
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                personal.isVerified == 1
                                    ? Icons.verified_user
                                    : Icons.pending_actions,
                                size: 14,
                                color: personal.isVerified == 1
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                personal.isVerified == 1
                                    ? 'Verified'
                                    : 'Pending Verification',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: personal.isVerified == 1
                                      ? Colors.blue.shade800
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // About Me
          if (personal.aboutMe.isNotEmpty && personal.aboutMe != 'Not available')
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Me',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    personal.aboutMe,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
    Color color = Colors.blue,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: highlight ? Colors.blue.shade800 : Colors.grey.shade900,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails(PersonalDetail personal) {
    return _buildSection(
      title: 'Personal Details',
      icon: Icons.person,
      color: const Color(0xFF1E40AF),
      content: Column(
        children: [
          _buildInfoRow('Height', personal.heightName, icon: Icons.height),
          _buildInfoRow('Religion', personal.religionName, icon: Icons.flag),
          _buildInfoRow('Blood Group', personal.bloodGroup, icon: Icons.water_drop),
          _buildInfoRow('Community', personal.communityName, icon: Icons.people),
          _buildInfoRow('Mother Tongue', personal.motherTongue, icon: Icons.language),
          _buildInfoRow('Sub Community', personal.subCommunityName, icon: Icons.people_outline),
          _buildInfoRow('Birth City', personal.birthcity, icon: Icons.place),
          _buildInfoRow('Disability', personal.disability, icon: Icons.accessible),
        ],
      ),
    );
  }

  Widget _buildEducationCareer(PersonalDetail personal) {
    return _buildSection(
      title: 'Education & Career',
      icon: Icons.school,
      color: const Color(0xFF065F46),
      content: Column(
        children: [
          _buildInfoRow('Education Type', personal.educationType, icon: Icons.school, highlight: true),
          _buildInfoRow('Degree', personal.degree, icon: Icons.school_outlined),
          _buildInfoRow('Faculty', personal.faculty, icon: Icons.book),
          _buildInfoRow('Education Medium', personal.educationMedium, icon: Icons.language),
          _buildInfoRow('Occupation', personal.occupationType, icon: Icons.work, highlight: true),
          _buildInfoRow('Company', personal.companyName, icon: Icons.business),
          _buildInfoRow('Designation', personal.designation, icon: Icons.badge),
          _buildInfoRow('Annual Income', personal.annualIncome, icon: Icons.attach_money),
        ],
      ),
    );
  }

  Widget _buildFamilyDetails(FamilyDetail family) {
    return _buildSection(
      title: 'Family Details',
      icon: Icons.family_restroom,
      color: const Color(0xFF7C3AED),
      content: Column(
        children: [
          _buildInfoRow('Family Type', family.familyType, icon: Icons.house),
          _buildInfoRow('Family Background', family.familyBackground, icon: Icons.history_edu),
          _buildInfoRow('Family Origin', family.familyOrigin, icon: Icons.public),
          _buildInfoRow('Father Status', family.fatherStatus, icon: Icons.person_outline),
          _buildInfoRow('Mother Status', family.motherStatus, icon: Icons.person_outline),
          _buildInfoRow('Mother Education', family.motherEducation, icon: Icons.school),
          _buildInfoRow('Mother Occupation', family.motherOccupation, icon: Icons.work_outline),
        ],
      ),
    );
  }

  Widget _buildLifestyle(Lifestyle lifestyle) {
    return _buildSection(
      title: 'Lifestyle',
      icon: Icons.emoji_food_beverage,
      color: const Color(0xFFEA580C),
      content: Column(
        children: [
          _buildInfoRow('Diet', lifestyle.diet, icon: Icons.restaurant, highlight: true),
          _buildInfoRow('Smoking', lifestyle.smoke, icon: Icons.smoking_rooms),
          _buildInfoRow('Drinking', lifestyle.drinks, icon: Icons.local_drink),
          _buildInfoRow('Smoke Type', lifestyle.smokeType, icon: Icons.smoke_free),
          _buildInfoRow('Drink Type', lifestyle.drinkType, icon: Icons.wine_bar),
        ],
      ),
    );
  }

  Widget _buildPartnerPreference(PartnerPreference partner) {
    return _buildSection(
      title: 'Partner Preferences',
      icon: Icons.favorite,
      color: const Color(0xFFBE185D),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Preferences
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Basic Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBE185D),
              ),
            ),
          ),
          _buildInfoRow('Age Range', partner.ageRange, icon: Icons.calendar_today),
          _buildInfoRow('Marital Status', partner.maritalStatus, icon: Icons.favorite_border),
          _buildInfoRow('Religion', partner.religion, icon: Icons.flag),
          _buildInfoRow('Caste', partner.caste, icon: Icons.people),
          _buildInfoRow('Country', partner.country, icon: Icons.public),
          _buildInfoRow('City', partner.city, icon: Icons.location_city),

          const SizedBox(height: 24),

          // Lifestyle & Physical
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Lifestyle & Physical',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBE185D),
              ),
            ),
          ),
          _buildInfoRow('Diet', partner.diet, icon: Icons.restaurant_menu),
          _buildInfoRow('Complexion', partner.complexion, icon: Icons.palette),
          _buildInfoRow('Body Type', partner.bodyType, icon: Icons.accessibility),
          _buildInfoRow('Smoke Accept', partner.smokeAccept, icon: Icons.smoking_rooms),
          _buildInfoRow('Drink Accept', partner.drinkAccept, icon: Icons.local_bar),
          _buildInfoRow('Disability Accept', partner.disabilityAccept, icon: Icons.accessible_forward),

          // Other Expectations
          if (partner.otherExpectation.isNotEmpty && partner.otherExpectation != 'Not available')
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Other Expectations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBE185D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    partner.otherExpectation,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.pink.shade900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Profile...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade500,
            ),
            const SizedBox(height: 20),
            Consumer<UserDetailsProvider>(
              builder: (context, provider, child) {
                return Text(
                  provider.error,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<UserDetailsProvider>().fetchUserDetails(
                  widget.userId,
                  widget.myId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserDetailsProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.fetchUserDetails(widget.userId, widget.myId);
            },
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
          children: [
            // Profile Header
            _buildProfileHeader(
                provider.userDetails!.personalDetail),

            // Personal Details
            _buildPersonalDetails(
                provider.userDetails!.personalDetail),

            // Education & Career
            _buildEducationCareer(
                provider.userDetails!.personalDetail),

            // Family Details
            _buildFamilyDetails(provider.userDetails!.familyDetail),

            // Lifestyle
            _buildLifestyle(provider.userDetails!.lifestyle),

            // Partner Preference
            _buildPartnerPreference(provider.userDetails!.partner),

            const SizedBox(height: 20),
          ],
        ),
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No User Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}