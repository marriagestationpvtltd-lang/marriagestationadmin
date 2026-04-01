import 'package:adminmrz/users/userdetails/userdetailprovider.dart';
import 'package:adminmrz/document/docprovider/docmodel.dart';
import 'package:adminmrz/document/docprovider/docservice.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'detailmodel.dart';

// ─────────────────────────── colour palette ───────────────────────────────────
const _kPrimary   = Color(0xFF6366F1);
const _kPersonal  = Color(0xFF6366F1);
const _kEducation = Color(0xFF059669);
const _kFamily    = Color(0xFF7C3AED);
const _kLifestyle = Color(0xFFF59E0B);
const _kPartner   = Color(0xFFDB2777);
const _kDocs      = Color(0xFF0EA5E9);
const _kPageBg    = Color(0xFFF1F5F9);

// ──────────────────────────── Screen ─────────────────────────────────────────
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
  String? _editingKey;
  final TextEditingController _editCtrl = TextEditingController();
  final TextEditingController _rejectDocCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<UserDetailsProvider>()
          .fetchUserDetails(widget.userId, widget.myId);
      // Load documents for this user if not yet initialized
      final docProvider = context.read<DocumentsProvider>();
      if (!docProvider.isInitialized && !docProvider.isLoading) {
        docProvider.fetchDocuments();
      }
    });
  }

  @override
  void dispose() {
    context.read<UserDetailsProvider>().clearData();
    _editCtrl.dispose();
    _rejectDocCtrl.dispose();
    super.dispose();
  }

  // ── edit helpers ────────────────────────────────────────────────────────────

  void _startEdit(String key, String currentValue) {
    setState(() {
      _editingKey = key;
      _editCtrl.text =
          (currentValue == 'Not available' || currentValue == 'null')
              ? ''
              : currentValue;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingKey = null;
      _editCtrl.clear();
    });
  }

  Future<void> _saveEdit(String key, String section, String apiField) async {
    final newValue = _editCtrl.text.trim();
    setState(() => _isSaving = true);

    final ok = await context.read<UserDetailsProvider>().updateField(
          section: section,
          field: apiField,
          value: newValue,
        );

    setState(() {
      _isSaving = false;
      _editingKey = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Updated successfully' : 'Update failed — please try again'),
          backgroundColor:
              ok ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── reusable editable row ────────────────────────────────────────────────────

  Widget _row(
    String key,
    String label,
    String rawValue, {
    required String section,
    required String apiField,
    IconData? icon,
    bool highlight = false,
  }) {
    final displayValue =
        (rawValue.isEmpty || rawValue == 'null') ? '—' : rawValue;
    final isEditing = _editingKey == key;
    final faded = displayValue == 'Not available' || displayValue == '—';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            child: icon != null
                ? Icon(icon, size: 15, color: Colors.blueGrey.shade300)
                : null,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: TextField(
                            controller: _editCtrl,
                            autofocus: true,
                            onSubmitted: (_) =>
                                _saveEdit(key, section, apiField),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                    color: _kPrimary.withOpacity(0.4)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: _kPrimary, width: 1.5),
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _btn(
                        'Save',
                        bg: _kPrimary,
                        fg: Colors.white,
                        loading: _isSaving,
                        onPressed: _isSaving
                            ? null
                            : () => _saveEdit(key, section, apiField),
                      ),
                      const SizedBox(width: 4),
                      _btn(
                        'Cancel',
                        bg: Colors.white,
                        fg: Colors.grey.shade700,
                        border: Colors.grey.shade300,
                        onPressed: _isSaving ? null : _cancelEdit,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayValue,
                          style: TextStyle(
                            fontSize: 14,
                            color: faded
                                ? Colors.grey.shade400
                                : highlight
                                    ? _kPrimary
                                    : Colors.grey.shade900,
                            fontWeight: faded
                                ? FontWeight.w400
                                : highlight
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _startEdit(key, rawValue),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(Icons.edit_outlined,
                              size: 13, color: Colors.blueGrey.shade300),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _btn(
    String label, {
    required Color bg,
    required Color fg,
    Color? border,
    VoidCallback? onPressed,
    bool loading = false,
  }) =>
      SizedBox(
        height: 30,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(52, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: border != null ? BorderSide(color: border) : BorderSide.none,
            ),
          ),
          child: loading
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );

  // ── section wrapper ──────────────────────────────────────────────────────────

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: color.withOpacity(0.05),
            child: Row(
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(children: rows),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── profile header ───────────────────────────────────────────────────────────

  Widget _buildHeader(PersonalDetail p) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade200, width: 3),
                  color: Colors.blue.shade50,
                ),
                child: ClipOval(
                  child: p.hasProfilePicture
                      ? Image.network(
                          p.profilePicture,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, prog) => prog == null
                              ? child
                              : Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: prog.expectedTotalBytes != null
                                        ? prog.cumulativeBytesLoaded /
                                            prog.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Icon(Icons.person,
                              size: 40, color: Colors.blue.shade300),
                        )
                      : Icon(Icons.person, size: 40, color: Colors.blue.shade300),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 18,
                      runSpacing: 4,
                      children: [
                        if (p.age != null)
                          _metaChip(Icons.cake, '${p.age} yrs', Colors.blue.shade700),
                        _metaChip(Icons.location_on, p.city, Colors.blue.shade700),
                        if (p.country != 'Not available')
                          _metaChip(Icons.public, p.country, Colors.teal.shade700),
                        _metaChip(Icons.favorite, p.maritalStatusName, Colors.pink.shade600),
                        _metaChip(Icons.badge, 'ID: ${p.memberId}', Colors.grey.shade600),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _badge(
                          label: p.userType.isEmpty ? 'FREE' : p.userType.toUpperCase(),
                          icon: p.userType == 'paid' ? Icons.workspace_premium : Icons.person_outline,
                          bg: p.userType == 'paid' ? Colors.amber.shade50 : Colors.grey.shade100,
                          border: p.userType == 'paid' ? Colors.amber.shade400 : Colors.grey.shade300,
                          fg: p.userType == 'paid' ? Colors.amber.shade900 : Colors.grey.shade700,
                        ),
                        _badge(
                          label: p.isVerified == 1 ? 'Verified' : 'Pending Verification',
                          icon: p.isVerified == 1 ? Icons.verified_user : Icons.pending_actions,
                          bg: p.isVerified == 1 ? Colors.green.shade50 : Colors.orange.shade50,
                          border: p.isVerified == 1 ? Colors.green.shade300 : Colors.orange.shade300,
                          fg: p.isVerified == 1 ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                        if (p.privacy.isNotEmpty)
                          _badge(
                            label: p.privacy,
                            icon: Icons.lock_outline,
                            bg: Colors.indigo.shade50,
                            border: Colors.indigo.shade200,
                            fg: Colors.indigo.shade800,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (p.aboutMe.isNotEmpty && p.aboutMe != 'Not available') ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About Me',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const SizedBox(height: 6),
                  Text(p.aboutMe,
                      style: TextStyle(
                          fontSize: 14, color: Colors.blueGrey.shade800, height: 1.6)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _badge({
    required String label,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color fg,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
            Text(label,
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      );

  // ── section builders ─────────────────────────────────────────────────────────

  Widget _buildPersonal(PersonalDetail p) => _section(
        title: 'Personal Details',
        icon: Icons.person_outline,
        color: _kPersonal,
        rows: [
          _row('p_height', 'Height', p.heightName, section: 'personal', apiField: 'height_name', icon: Icons.height, highlight: true),
          _row('p_dob', 'Birth Date', p.birthDate, section: 'personal', apiField: 'birthDate', icon: Icons.cake),
          _row('p_birthtime', 'Birth Time', p.birthtime, section: 'personal', apiField: 'birthtime', icon: Icons.access_time),
          _row('p_birthcity', 'Birth City', p.birthcity, section: 'personal', apiField: 'birthcity', icon: Icons.place),
          _row('p_religion', 'Religion', p.religionName, section: 'personal', apiField: 'religionName', icon: Icons.flag),
          _row('p_community', 'Community', p.communityName, section: 'personal', apiField: 'communityName', icon: Icons.people),
          _row('p_subcomm', 'Sub Community', p.subCommunityName, section: 'personal', apiField: 'subCommunityName', icon: Icons.people_outline),
          _row('p_tongue', 'Mother Tongue', p.motherTongue, section: 'personal', apiField: 'motherTongue', icon: Icons.language),
          _row('p_blood', 'Blood Group', p.bloodGroup, section: 'personal', apiField: 'bloodGroup', icon: Icons.water_drop),
          _row('p_marital', 'Marital Status', p.maritalStatusName, section: 'personal', apiField: 'maritalStatusName', icon: Icons.favorite_border),
          _row('p_manglik', 'Manglik', p.manglik, section: 'personal', apiField: 'manglik', icon: Icons.star_border),
          _row('p_disability', 'Disability', p.disability, section: 'personal', apiField: 'Disability', icon: Icons.accessible),
          _row('p_photo', 'Photo Request', p.photoRequest, section: 'personal', apiField: 'photo_request', icon: Icons.photo_camera_outlined),
          _row('p_privacy', 'Privacy Setting', p.privacy, section: 'personal', apiField: 'privacy', icon: Icons.lock_outline),
        ],
      );

  Widget _buildEducation(PersonalDetail p) => _section(
        title: 'Education & Career',
        icon: Icons.school_outlined,
        color: _kEducation,
        rows: [
          _row('e_type', 'Education Type', p.educationType, section: 'personal', apiField: 'educationtype', icon: Icons.school, highlight: true),
          _row('e_degree', 'Degree', p.degree, section: 'personal', apiField: 'degree', icon: Icons.military_tech_outlined),
          _row('e_faculty', 'Faculty', p.faculty, section: 'personal', apiField: 'faculty', icon: Icons.book_outlined),
          _row('e_medium', 'Education Medium', p.educationMedium, section: 'personal', apiField: 'educationmedium', icon: Icons.translate),
          _row('e_working', 'Are You Working?', p.areYouWorking, section: 'personal', apiField: 'areyouworking', icon: Icons.work_outline),
          _row('e_occ', 'Occupation Type', p.occupationType, section: 'personal', apiField: 'occupationtype', icon: Icons.business_center_outlined, highlight: true),
          _row('e_workwith', 'Working With', p.workingWith, section: 'personal', apiField: 'workingwith', icon: Icons.corporate_fare),
          _row('e_company', 'Company Name', p.companyName, section: 'personal', apiField: 'companyname', icon: Icons.business),
          _row('e_designation', 'Designation', p.designation, section: 'personal', apiField: 'designation', icon: Icons.badge_outlined),
          _row('e_business', 'Business Name', p.businessName, section: 'personal', apiField: 'businessname', icon: Icons.store_outlined),
          _row('e_income', 'Annual Income', p.annualIncome, section: 'personal', apiField: 'annualincome', icon: Icons.currency_rupee, highlight: true),
        ],
      );

  Widget _buildFamily(FamilyDetail f) => _section(
        title: 'Family Details',
        icon: Icons.family_restroom,
        color: _kFamily,
        rows: [
          _row('f_type', 'Family Type', f.familyType, section: 'family', apiField: 'familytype', icon: Icons.home_outlined, highlight: true),
          _row('f_background', 'Family Background', f.familyBackground, section: 'family', apiField: 'familybackground', icon: Icons.history_edu),
          _row('f_origin', 'Family Origin', f.familyOrigin, section: 'family', apiField: 'familyorigin', icon: Icons.public),
          _row('f_father_status', 'Father Status', f.fatherStatus, section: 'family', apiField: 'fatherstatus', icon: Icons.person_outline),
          _row('f_father_name', 'Father Name', f.fatherName, section: 'family', apiField: 'fathername', icon: Icons.person),
          _row('f_father_edu', 'Father Education', f.fatherEducation, section: 'family', apiField: 'fathereducation', icon: Icons.school_outlined),
          _row('f_father_occ', 'Father Occupation', f.fatherOccupation, section: 'family', apiField: 'fatheroccupation', icon: Icons.work_outline),
          _row('f_mother_status', 'Mother Status', f.motherStatus, section: 'family', apiField: 'motherstatus', icon: Icons.person_outline),
          _row('f_mother_caste', 'Mother Caste', f.motherCaste, section: 'family', apiField: 'mothercaste', icon: Icons.people_outline),
          _row('f_mother_edu', 'Mother Education', f.motherEducation, section: 'family', apiField: 'mothereducation', icon: Icons.school_outlined),
          _row('f_mother_occ', 'Mother Occupation', f.motherOccupation, section: 'family', apiField: 'motheroccupation', icon: Icons.work_outline),
        ],
      );

  Widget _buildLifestyle(Lifestyle ls) => _section(
        title: 'Lifestyle',
        icon: Icons.emoji_food_beverage,
        color: _kLifestyle,
        rows: [
          _row('l_diet', 'Diet', ls.diet, section: 'lifestyle', apiField: 'diet', icon: Icons.restaurant, highlight: true),
          _row('l_smoke', 'Smoking', ls.smoke, section: 'lifestyle', apiField: 'smoke', icon: Icons.smoking_rooms),
          _row('l_smoke_type', 'Smoke Type', ls.smokeType, section: 'lifestyle', apiField: 'smoketype', icon: Icons.smoke_free),
          _row('l_drinks', 'Drinking', ls.drinks, section: 'lifestyle', apiField: 'drinks', icon: Icons.local_drink),
          _row('l_drink_type', 'Drink Type', ls.drinkType, section: 'lifestyle', apiField: 'drinktype', icon: Icons.wine_bar),
        ],
      );

  Widget _buildPartner(PartnerPreference pp) => _section(
        title: 'Partner Preferences',
        icon: Icons.favorite,
        color: _kPartner,
        rows: [
          _row('pp_age', 'Age Range', pp.ageRange, section: 'partner', apiField: 'age_range', icon: Icons.calendar_today, highlight: true),
          _row('pp_weight', 'Weight Range', pp.weightRange, section: 'partner', apiField: 'weight_range', icon: Icons.monitor_weight_outlined),
          _row('pp_marital', 'Marital Status', pp.maritalStatus, section: 'partner', apiField: 'maritalstatus', icon: Icons.favorite_border),
          _row('pp_child', 'Profile With Child', pp.profileWithChild, section: 'partner', apiField: 'profilewithchild', icon: Icons.child_care),
          _row('pp_family', 'Family Type', pp.familyType, section: 'partner', apiField: 'familytype', icon: Icons.home_outlined),
          _row('pp_religion', 'Religion', pp.religion, section: 'partner', apiField: 'religion', icon: Icons.flag),
          _row('pp_caste', 'Caste', pp.caste, section: 'partner', apiField: 'caste', icon: Icons.people),
          _row('pp_tongue', 'Mother Tongue', pp.motherTongue, section: 'partner', apiField: 'mothertoungue', icon: Icons.language),
          _row('pp_country', 'Country', pp.country, section: 'partner', apiField: 'country', icon: Icons.public),
          _row('pp_state', 'State', pp.state, section: 'partner', apiField: 'state', icon: Icons.map_outlined),
          _row('pp_city', 'City', pp.city, section: 'partner', apiField: 'city', icon: Icons.location_city),
          _row('pp_qual', 'Qualification', pp.qualification, section: 'partner', apiField: 'qualification', icon: Icons.school_outlined),
          _row('pp_edu_medium', 'Education Medium', pp.educationMedium, section: 'partner', apiField: 'educationmedium', icon: Icons.translate),
          _row('pp_profession', 'Profession', pp.profession, section: 'partner', apiField: 'proffession', icon: Icons.business_center_outlined),
          _row('pp_workwith', 'Working With', pp.workingWith, section: 'partner', apiField: 'workingwith', icon: Icons.corporate_fare),
          _row('pp_income', 'Annual Income', pp.annualIncome, section: 'partner', apiField: 'annualincome', icon: Icons.currency_rupee),
          _row('pp_diet', 'Diet', pp.diet, section: 'partner', apiField: 'diet', icon: Icons.restaurant_menu),
          _row('pp_smoke', 'Smoke Acceptable', pp.smokeAccept, section: 'partner', apiField: 'smokeaccept', icon: Icons.smoking_rooms),
          _row('pp_drink', 'Drink Acceptable', pp.drinkAccept, section: 'partner', apiField: 'drinkaccept', icon: Icons.local_bar),
          _row('pp_disability', 'Disability Acceptable', pp.disabilityAccept, section: 'partner', apiField: 'disabilityaccept', icon: Icons.accessible_forward),
          _row('pp_complexion', 'Complexion', pp.complexion, section: 'partner', apiField: 'complexion', icon: Icons.palette_outlined),
          _row('pp_body', 'Body Type', pp.bodyType, section: 'partner', apiField: 'bodytype', icon: Icons.accessibility_new),
          _row('pp_manglik', 'Manglik', pp.manglik, section: 'partner', apiField: 'manglik', icon: Icons.star_border),
          _row('pp_herscope', 'Hers Cope Belief', pp.hersCopeBelief, section: 'partner', apiField: 'herscopeblief', icon: Icons.psychology_outlined),
          if (pp.otherExpectation.isNotEmpty && pp.otherExpectation != 'Not available')
            _row('pp_other', 'Other Expectations', pp.otherExpectation, section: 'partner', apiField: 'otherexpectation', icon: Icons.notes),
        ],
      );

  // ── documents section ────────────────────────────────────────────────────────

  Widget _buildDocumentsSection() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _kDocs, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: _kDocs.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 17, color: _kDocs),
                const SizedBox(width: 10),
                const Text(
                  'Submitted Documents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kDocs,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Consumer<DocumentsProvider>(
                  builder: (_, dp, __) => dp.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          color: _kDocs,
                          tooltip: 'Refresh documents',
                          onPressed: () => dp.fetchDocuments(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Consumer<DocumentsProvider>(
              builder: (_, dp, __) {
                if (dp.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final docs = dp.documentsForUser(widget.userId);
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_outlined,
                              size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No documents submitted',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) => _docCard(doc)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _docCard(Document doc) {
    final statusColor = doc.isApproved
        ? const Color(0xFF10B981)
        : doc.isRejected
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final statusIcon = doc.isApproved
        ? Icons.verified_outlined
        : doc.isRejected
            ? Icons.cancel_outlined
            : Icons.pending_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            GestureDetector(
              onTap: () => _showDocPreview(doc.fullPhotoUrl),
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        doc.fullPhotoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, prog) {
                          if (prog == null) return child;
                          return const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.insert_drive_file_outlined,
                              size: 28, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomRight: Radius.circular(7),
                        ),
                      ),
                      child: const Icon(Icons.zoom_in,
                          size: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 14, color: _kDocs),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          doc.documentType.isNotEmpty
                              ? doc.documentType
                              : '—',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.numbers_outlined,
                          size: 13, color: Colors.teal.shade400),
                      const SizedBox(width: 6),
                      Text(
                        doc.documentIdNumber.isNotEmpty
                            ? doc.documentIdNumber
                            : '—',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: statusColor.withOpacity(0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          doc.status.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions for pending docs
            if (doc.isPending)
              Consumer<DocumentsProvider>(
                builder: (_, dp, __) => dp.isActionLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _docActionBtn(
                            icon: Icons.check_circle_outline,
                            label: 'Approve',
                            color: const Color(0xFF10B981),
                            onTap: () => _approveDocFromProfile(doc, dp),
                          ),
                          const SizedBox(height: 6),
                          _docActionBtn(
                            icon: Icons.cancel_outlined,
                            label: 'Reject',
                            color: const Color(0xFFEF4444),
                            onTap: () => _rejectDocFromProfile(doc, dp),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _docActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      );

  void _showDocPreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, prog) {
                            if (prog == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: prog.expectedTotalBytes != null
                                    ? prog.cumulativeBytesLoaded /
                                        prog.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Image not available',
                                      style:
                                          TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveDocFromProfile(
      Document doc, DocumentsProvider dp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Approve Document',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Approve this document?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await dp.updateDocumentStatus(
        userId: doc.userId, action: 'approve');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? 'Document approved' : 'Failed: ${dp.error}'),
        backgroundColor:
            ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  Future<void> _rejectDocFromProfile(
      Document doc, DocumentsProvider dp) async {
    _rejectDocCtrl.clear();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reject Document',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for rejection:',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _rejectDocCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_rejectDocCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              if (!mounted) return;
              final ok = await dp.updateDocumentStatus(
                userId: doc.userId,
                action: 'reject',
                rejectReason: _rejectDocCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Document rejected' : 'Failed: ${dp.error}'),
                  backgroundColor: ok
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ── loading / error ───────────────────────────────────────────────────────────

  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
              ),
            ),
            SizedBox(height: 16),
            Text('Loading Profile…',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildError(UserDetailsProvider prov) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(prov.error,
                  style: const TextStyle(fontSize: 15, color: Colors.red),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                onPressed: () => prov.fetchUserDetails(widget.userId, widget.myId),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );

  // ── build ────────────────────────────────────────────────────────────────────

  Widget _buildBody(UserDetailsData data) {
    final p = data.personalDetail;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(p),
                const Divider(height: 1, thickness: 1),
                _buildPersonal(p),
                const Divider(height: 1, thickness: 1),
                _buildEducation(p),
                const Divider(height: 1, thickness: 1),
                _buildFamily(data.familyDetail),
                const Divider(height: 1, thickness: 1),
                _buildLifestyle(data.lifestyle),
                const Divider(height: 1, thickness: 1),
                _buildPartner(data.partner),
                const Divider(height: 1, thickness: 1),
                _buildDocumentsSection(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserDetailsProvider>();

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        title: const Text('User Profile',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => provider.fetchUserDetails(widget.userId, widget.myId),
          ),
        ],
      ),
      body: provider.isLoading
          ? _buildLoading()
          : provider.error.isNotEmpty
              ? _buildError(provider)
              : provider.userDetails != null
                  ? _buildBody(provider.userDetails!)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No data available',
                              style: TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                    ),
    );
  }
}
