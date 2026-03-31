import 'dart:convert';
import 'package:adminmrz/adminchat/services/MatchedProfileService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chatprovider.dart';
import 'constant.dart';
import 'package:http/http.dart' as http;

class ProfileSidebar extends StatefulWidget {
  final int selectedTab;
  final Function(int) onTabChange;
  final id;

  ProfileSidebar({required this.selectedTab, required this.onTabChange, required this.id});

  @override
  _ProfileSidebarState createState() => _ProfileSidebarState();
}

class _ProfileSidebarState extends State<ProfileSidebar> {
  bool _showFilters = false;
  String _memberStatus = "All Members";
  String _onlineStatus = "All Profiles";
  String _sortBy = "Match %";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<dynamic> profiles = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Track shared profiles with count per user and timestamp
  Map<int, Map<String, dynamic>> _sharedProfilesData = {};
  Set<int> _sharedProfileIds = {};
  int _totalSharedCount = 0;

  // Track last share timestamp for sorting
  Map<int, DateTime> _lastShareTimestamp = {};

  // Track current receiver ID to filter shares
  String? _currentReceiverId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    // Don't load immediately, wait for provider
  }

  @override
  void didUpdateWidget(ProfileSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected user (receiver) changed, reload shared profiles
    if (oldWidget.id != widget.id) {
      _loadSharedProfilesForUser();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load shared profiles for the current selected user
  Future<void> _loadSharedProfilesForUser() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    String receiverId = chatProvider.id?.toString() ?? widget.id?.toString() ?? '';

    if (receiverId.isEmpty) return;

    _currentReceiverId = receiverId;

    try {
      final snapshot = await _firestore
          .collection('profile_shares')
          .where('shared_by', isEqualTo: '1')
          .where('shared_to', isEqualTo: receiverId)
          .orderBy('timestamp', descending: true)
          .get();

      Map<int, Map<String, dynamic>> sharedData = {};
      Set<int> sharedIds = {};
      Map<int, DateTime> lastShareTimestamps = {};

      for (var doc in snapshot.docs) {
        int profileId = doc['profile_id'] as int;
        DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();

        if (!sharedData.containsKey(profileId)) {
          sharedData[profileId] = {
            'profile_name': doc['profile_name'],
            'timestamp': timestamp,
            'shared_to': doc['shared_to'],
            'profile_member_id': doc['profile_member_id'],
            'share_count': 1,
          };
          sharedIds.add(profileId);
          lastShareTimestamps[profileId] = timestamp;
        } else {
          // Increment share count if shared multiple times
          sharedData[profileId]!['share_count'] =
              (sharedData[profileId]!['share_count'] ?? 0) + 1;
          // Update with latest timestamp
          if (timestamp.isAfter(lastShareTimestamps[profileId] ?? DateTime(1970))) {
            lastShareTimestamps[profileId] = timestamp;
          }
        }
      }

      setState(() {
        _sharedProfilesData = sharedData;
        _sharedProfileIds = sharedIds;
        _totalSharedCount = snapshot.docs.length;
        _lastShareTimestamp = lastShareTimestamps;
      });
    } catch (e) {
      debugPrint('Error loading shared profiles for user $receiverId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFFD81B60);
    const kPrimaryLight = Color(0xFFFCE4EC);
    const kText = Color(0xFF1E293B);
    const kMuted = Color(0xFF64748B);
    const kBorder = Color(0xFFE2E8F0);
    const kOnline = Color(0xFF22C55E);

    final matchedProfilesProvider = Provider.of<MatchedProfileProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    // Load shared profiles when provider is ready and user changes
    if (chatProvider.id != null && _currentReceiverId != chatProvider.id?.toString()) {
      _loadSharedProfilesForUser();
    }

    List<int> filteredIndices = _filterProfiles(matchedProfilesProvider);
    filteredIndices = _sortProfiles(filteredIndices, matchedProfilesProvider);

    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          // ── TABS ──────────────────────────────────────────────────────
          Row(
            children: [
              _tabButton("Matched ${filteredIndices.length}", 0),
              _tabButton("All Profiles", 1),
            ],
          ),

          // ── SEARCH BAR ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by name, occupation...",
                  hintStyle: const TextStyle(fontSize: 12, color: kMuted),
                  prefixIcon: const Icon(Icons.search, size: 18, color: kMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: kBorder, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: kBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: kPrimary, width: 1),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  isDense: true,
                ),
              ),
            ),
          ),

          // ── FILTERS TOGGLE ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 16, color: kMuted),
                  const SizedBox(width: 8),
                  const Text("Filters", style: TextStyle(fontSize: 12, color: kMuted)),
                  const Spacer(),
                  Icon(
                    _showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: kMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── COLLAPSIBLE FILTERS ─────────────────────────────────────
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Member Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _memberStatus,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: kText),
                    items: ["All Members", "Paid Members", "Unpaid Members"]
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) => setState(() => _memberStatus = value!),
                  ),
                  const SizedBox(height: 8),
                  const Text("Online Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _onlineStatus,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: kText),
                    items: ["All Profiles", "Online Members", "Offline Members"]
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) => setState(() => _onlineStatus = value!),
                  ),
                  const SizedBox(height: 8),
                  const Text("Sort By", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: kText),
                    items: ["Match %", "Name", "Age", "Recently Active", "Recently Shared"]
                        .map((sort) => DropdownMenuItem(value: sort, child: Text(sort)))
                        .toList(),
                    onChanged: (value) => setState(() => _sortBy = value!),
                  ),
                  if (_memberStatus != "All Members" || _onlineStatus != "All Profiles")
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _memberStatus = "All Members";
                          _onlineStatus = "All Profiles";
                          _sortBy = "Match %";
                        }),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Clear filters', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                ],
              ),
            ),

          // ── SHARED STATS ─────────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('profile_shares')
                .where('shared_by', isEqualTo: '1')
                .where('shared_to', isEqualTo: chatProvider.id?.toString() ?? '')
                .snapshots(),
            builder: (context, snapshot) {
              int sharedCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              int uniqueProfiles = _sharedProfileIds.length;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.share,
                      value: sharedCount.toString(),
                      label: 'Total Shares',
                      color: const Color(0xFF16A34A),
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFFBBF7D0)),
                    _buildStatItem(
                      icon: Icons.people,
                      value: uniqueProfiles.toString(),
                      label: 'Unique Profiles',
                      color: const Color(0xFF0284C7),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── RECENTLY SHARED ───────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('profile_shares')
                .where('shared_by', isEqualTo: '1')
                .where('shared_to', isEqualTo: chatProvider.id?.toString() ?? '')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

              return Container(
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Recently Shared with ${chatProvider.namee ?? "User"}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var share = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          int profileId = share['profile_id'] as int;
                          int shareCount = _sharedProfilesData[profileId]?['share_count'] ?? 1;

                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.share, size: 10, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  share['profile_name'] ?? 'Profile',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                                if (shareCount > 1)
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$shareCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Container(height: 1, color: kBorder),

          // ── PROFILE LIST ─────────────────────────────────────────────
          Expanded(
            child: Consumer<MatchedProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isloading) {
                  return const Center(child: CircularProgressIndicator(color: kPrimary));
                }

                List<int> filteredIndices = _filterProfiles(provider);
                filteredIndices = _sortProfiles(filteredIndices, provider);

                if (filteredIndices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text('No profiles found', style: TextStyle(color: kMuted, fontSize: 13)),
                        if (_memberStatus != "All Members" || _onlineStatus != "All Profiles" || _searchQuery.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: kPrimary),
                            onPressed: () => setState(() {
                              _memberStatus = "All Members";
                              _onlineStatus = "All Profiles";
                              _sortBy = "Match %";
                              _searchController.clear();
                            }),
                            child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredIndices.length,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemBuilder: (context, index) {
                    final profileIndex = filteredIndices[index];
                    bool isPaid = provider.isPaidList[profileIndex];
                    bool isOnline = provider.isOnlineList[profileIndex];
                    int profileId = provider.ids[profileIndex];
                    bool isShared = _sharedProfileIds.contains(profileId);
                    int shareCount = _sharedProfilesData[profileId]?['share_count'] ?? 0;
                    DateTime? lastShareTime = _lastShareTimestamp[profileId];

                    String? profilePicture = provider.profilePictures.isNotEmpty
                        ? provider.profilePictures[profileIndex]
                        : null;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color: isShared ? const Color(0xFF22C55E) : Colors.transparent,
                            width: 3,
                          ),
                          right: BorderSide(color: kBorder),
                          top: BorderSide(color: kBorder),
                          bottom: BorderSide(color: kBorder),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── AVATAR ──
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                                      ? NetworkImage(profilePicture)
                                      : null,
                                  child: profilePicture == null || profilePicture.isEmpty
                                      ? Icon(Icons.person, size: 24, color: Colors.grey[400])
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isOnline ? kOnline : const Color(0xFFCBD5E1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                                if (isPaid)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(Icons.star, size: 9, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),

                            // ── CONTENT ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${provider.firstNames[profileIndex]} ${provider.lastNames[profileIndex]}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: isPaid ? kPrimary : kText,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isPaid ? kPrimaryLight : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isPaid ? "Paid" : "Free",
                                          style: TextStyle(
                                            color: isPaid ? kPrimary : const Color(0xFF2563EB),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isShared) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFBBF7D0)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 9),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Shared${shareCount > 1 ? ' ×$shareCount' : ''}',
                                                style: const TextStyle(
                                                  color: Color(0xFF16A34A),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (lastShareTime != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            _getTimeAgo(lastShareTime),
                                            style: const TextStyle(fontSize: 9, color: kMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.work_outline, size: 11, color: kMuted),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          provider.occupation[profileIndex],
                                          style: const TextStyle(fontSize: 11, color: kMuted),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.cake_outlined, size: 11, color: kMuted),
                                      const SizedBox(width: 2),
                                      Text('${provider.age[profileIndex]}y', style: const TextStyle(fontSize: 11, color: kMuted)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.wc, size: 11, color: kMuted),
                                      const SizedBox(width: 2),
                                      Text(provider.gender[profileIndex], style: const TextStyle(fontSize: 11, color: kMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.badge_outlined, size: 11, color: kMuted),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          "ID: ${provider.memberiddd[profileIndex]}",
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: kMuted),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: kPrimaryLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.favorite, color: kPrimary, size: 10),
                                            const SizedBox(width: 2),
                                            Text(
                                              "${provider.matchingPercentages[profileIndex]}%",
                                              style: const TextStyle(
                                                color: kPrimary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.favorite_border, color: kPrimary, size: 16),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Liked ${provider.firstNames[profileIndex]}'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(
                                          Icons.share,
                                          color: isShared ? const Color(0xFF22C55E) : const Color(0xFF2563EB),
                                          size: 16,
                                        ),
                                        onPressed: isShared
                                            ? null
                                            : () {
                                                _sendMessage(
                                                  provider.lastNames[profileIndex],
                                                  provider.matchingPercentages[profileIndex].toString(),
                                                  provider.memberiddd[profileIndex].toString(),
                                                  provider.gender[profileIndex],
                                                  provider.occupation[profileIndex],
                                                  provider.education[profileIndex],
                                                  provider.marit[profileIndex],
                                                  provider.age[profileIndex].toString(),
                                                  provider.ids[profileIndex],
                                                  provider.firstNames[profileIndex],
                                                  provider.lastNames[profileIndex],
                                                  profilePicture,
                                                ).then((_) => _loadSharedProfilesForUser());
                                              },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  List<int> _filterProfiles(MatchedProfileProvider provider) {
    List<int> filteredIndices = [];

    for (int i = 0; i < provider.ids.length; i++) {
      bool memberStatusMatch = true;
      bool onlineStatusMatch = true;
      bool searchMatch = true;

      if (_memberStatus == "Paid Members") {
        memberStatusMatch = provider.isPaidList[i];
      } else if (_memberStatus == "Unpaid Members") {
        memberStatusMatch = !provider.isPaidList[i];
      }

      if (_onlineStatus == "Online Members") {
        onlineStatusMatch = provider.isOnlineList[i];
      } else if (_onlineStatus == "Offline Members") {
        onlineStatusMatch = !provider.isOnlineList[i];
      }

      if (_searchQuery.isNotEmpty) {
        String fullName = "${provider.firstNames[i]} ${provider.lastNames[i]}".toLowerCase();
        String occupation = provider.occupation[i].toLowerCase();
        String memberId = provider.memberiddd[i].toString().toLowerCase();

        searchMatch = fullName.contains(_searchQuery) ||
            occupation.contains(_searchQuery) ||
            memberId.contains(_searchQuery);
      }

      if (memberStatusMatch && onlineStatusMatch && searchMatch) {
        filteredIndices.add(i);
      }
    }

    return filteredIndices;
  }

  List<int> _sortProfiles(List<int> indices, MatchedProfileProvider provider) {
    List<int> sortedIndices = List.from(indices);

    switch (_sortBy) {
      case "Match %":
        sortedIndices.sort((a, b) {
          double aMatch = double.tryParse(provider.matchingPercentages[a].toString()) ?? 0;
          double bMatch = double.tryParse(provider.matchingPercentages[b].toString()) ?? 0;
          return bMatch.compareTo(aMatch);
        });
        break;
      case "Name":
        sortedIndices.sort((a, b) {
          String aName = "${provider.firstNames[a]} ${provider.lastNames[a]}";
          String bName = "${provider.firstNames[b]} ${provider.lastNames[b]}";
          return aName.compareTo(bName);
        });
        break;
      case "Age":
        sortedIndices.sort((a, b) {
          int aAge = provider.age[a];
          int bAge = provider.age[b];
          return aAge.compareTo(bAge);
        });
        break;
      case "Recently Active":
        sortedIndices.sort((a, b) {
          bool aOnline = provider.isOnlineList[a];
          bool bOnline = provider.isOnlineList[b];

          if (aOnline && !bOnline) return -1;
          if (!aOnline && bOnline) return 1;

          return provider.ids[a].compareTo(provider.ids[b]);
        });
        break;
      case "Recently Shared":
        sortedIndices.sort((a, b) {
          bool aShared = _sharedProfileIds.contains(provider.ids[a]);
          bool bShared = _sharedProfileIds.contains(provider.ids[b]);

          if (aShared && !bShared) return -1;
          if (!aShared && bShared) return 1;

          if (aShared && bShared) {
            DateTime aTime = _lastShareTimestamp[provider.ids[a]] ?? DateTime(1970);
            DateTime bTime = _lastShareTimestamp[provider.ids[b]] ?? DateTime(1970);
            return bTime.compareTo(aTime);
          }

          double aMatch = double.tryParse(provider.matchingPercentages[a].toString()) ?? 0;
          double bMatch = double.tryParse(provider.matchingPercentages[b].toString()) ?? 0;
          return bMatch.compareTo(aMatch);
        });
        break;
    }

    return sortedIndices;
  }

  Future<void> _sendMessage(
      String lastname,
      String matched,
      String memberid,
      String gender,
      String occupation,
      String education,
      String marit,
      String age,
      int id,
      String first,
      String last,
      String? profilePicture,
      ) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      Map<String, dynamic> profileData = {
        'id': id,
        'name': '$first $last',
        'profileImage': profilePicture ?? 'https://via.placeholder.com/150',
        'bio': '$matched% Matched',
        'Member ID': memberid,
        'occupation': occupation,
        'marit': marit,
        'education': education,
        'gender': gender,
        'age': age,
        'last': last,
        'first': first,
        'is_paid': chatProvider.ispaid,
      };

      await _firestore.collection('adminchat').add({
        'message': 'Profile Shared',
        'liked': false,
        'replyto': '',
        'senderid': '1',
        'receiverid': chatProvider.id.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'profile_card',
        'profileData': profileData,
      });

      await _firestore.collection('profile_shares').add({
        'shared_by': '1',
        'shared_to': chatProvider.id.toString(),
        'profile_id': id,
        'profile_name': '$first $last',
        'profile_member_id': memberid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      String conversationId = _getConversationId('1', chatProvider.id.toString());
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .set({
        'participants': ['1', chatProvider.id.toString()],
        'lastMessage': 'Shared a profile: $first $last',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSharedProfileId': id,
        'lastSharedProfileName': '$first $last',
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile shared successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share profile: $e'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getConversationId(String a, String b) {
    return (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';
  }

  Widget _tabButton(String title, int index) {
    const kPrimary = Color(0xFFD81B60);
    const kMuted = Color(0xFF64748B);
    final isSelected = widget.selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChange(index),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? kPrimary : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? kPrimary : kMuted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}