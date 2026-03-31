import 'dart:async';
import 'package:adminmrz/adminchat/services/MatchedProfileService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chatprovider.dart';
import 'dart:html' as html;

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary      = Color(0xFFD81B60);
const _kPrimaryLight = Color(0xFFFCE4EC);
const _kText         = Color(0xFF1E293B);
const _kMuted        = Color(0xFF94A3B8);
const _kBorder       = Color(0xFFE2E8F0);
const _kOnline       = Color(0xFF22C55E);
const _kBg           = Color(0xFFF8FAFC);
const _kCardBg       = Colors.white;

const _kPaginationScrollThreshold = 200.0;

class ProfileSidebar extends StatefulWidget {
  final int selectedTab;
  final Function(int) onTabChange;

  const ProfileSidebar({
    Key? key,
    required this.selectedTab,
    required this.onTabChange,
  }) : super(key: key);

  @override
  _ProfileSidebarState createState() => _ProfileSidebarState();
}

class _ProfileSidebarState extends State<ProfileSidebar> {
  // ── filters & search ───────────────────────────────────────────────────────
  bool   _showFilters  = false;
  String _memberStatus = "All";
  String _onlineStatus = "All";
  String _sortBy       = "Match %";
  final  TextEditingController _searchController = TextEditingController();
  String _searchQuery  = "";

  // ── Firestore shared-profile tracking ─────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<int, Map<String, dynamic>> _sharedProfilesData = {};
  Set<int>      _sharedProfileIds    = {};
  Map<int, DateTime> _lastShareTimestamp = {};

  // ── track which user's matches we've loaded ───────────────────────────────
  int? _lastFetchedUserId;
  bool _matchesLoaded = false;

  // ── scroll ────────────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ── online status polling ─────────────────────────────────────────────────
  Timer? _onlineStatusTimer;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _scrollController.addListener(_onScroll);
    // Poll online status for matched profiles every 30 seconds
    _onlineStatusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted || !_matchesLoaded) return;
        Provider.of<MatchedProfileProvider>(context, listen: false)
            .refreshOnlineStatuses();
      },
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _kPaginationScrollThreshold) {
      final provider = Provider.of<MatchedProfileProvider>(
          context, listen: false);
      provider.fetchMoreProfiles();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userId = chatProvider.id;
    if (userId != null && userId != _lastFetchedUserId) {
      _lastFetchedUserId = userId;
      _matchesLoaded = true;
      final matchProvider =
          Provider.of<MatchedProfileProvider>(context, listen: false);
      matchProvider.clearData();
      // Fetch Firestore share history and matched profiles automatically
      _loadSharedProfilesForUser(userId.toString());
      matchProvider.fetchMatchedProfiles(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _onlineStatusTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMatches() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userId = chatProvider.id;
    if (userId == null) return;
    setState(() => _matchesLoaded = true);
    Provider.of<MatchedProfileProvider>(context, listen: false)
        .fetchMatchedProfiles(userId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadSharedProfilesForUser(String receiverId) async {
    if (receiverId.isEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('profile_shares')
          .where('shared_by', isEqualTo: '1')
          .where('shared_to', isEqualTo: receiverId)
          .orderBy('timestamp', descending: true)
          .get();

      Map<int, Map<String, dynamic>> sharedData = {};
      Set<int> sharedIds = {};
      Map<int, DateTime> lastTs = {};

      for (var doc in snapshot.docs) {
        final profileId = doc['profile_id'] as int;
        final ts        = (doc['timestamp'] as Timestamp).toDate();
        if (!sharedData.containsKey(profileId)) {
          sharedData[profileId] = {
            'profile_name':      doc['profile_name'],
            'timestamp':         ts,
            'shared_to':         doc['shared_to'],
            'profile_member_id': doc['profile_member_id'],
            'share_count':       1,
          };
          sharedIds.add(profileId);
          lastTs[profileId] = ts;
        } else {
          sharedData[profileId]!['share_count'] =
              (sharedData[profileId]!['share_count'] ?? 0) + 1;
          if (ts.isAfter(lastTs[profileId] ?? DateTime(1970))) {
            lastTs[profileId] = ts;
          }
        }
      }

      if (mounted) {
        setState(() {
          _sharedProfilesData    = sharedData;
          _sharedProfileIds      = sharedIds;
          _lastShareTimestamp    = lastTs;
        });
      }
    } catch (e) {
      debugPrint('Error loading shared profiles: $e');
    }
  }

  String _toggleFilter(String current, String target) =>
      current == target ? 'All' : target;

  // ─────────────────────────────────────────────────────────────────────────
  List<int> _filterProfiles(MatchedProfileProvider p) {
    final List<int> out = [];
    for (int i = 0; i < p.ids.length; i++) {
      if (_memberStatus == "Paid"   && !p.isPaidList[i])  continue;
      if (_memberStatus == "Free"   &&  p.isPaidList[i])  continue;
      if (_onlineStatus == "Online" && !p.isOnlineList[i]) continue;
      if (_onlineStatus == "Offline" &&  p.isOnlineList[i]) continue;
      if (_searchQuery.isNotEmpty) {
        final fullName = "${p.firstNames[i]} ${p.lastNames[i]}".toLowerCase();
        final occ      = p.occupation[i].toLowerCase();
        final mid      = p.memberiddd[i].toLowerCase();
        if (!fullName.contains(_searchQuery) &&
            !occ.contains(_searchQuery) &&
            !mid.contains(_searchQuery)) continue;
      }
      out.add(i);
    }
    return out;
  }

  List<int> _sortProfiles(List<int> indices, MatchedProfileProvider p) {
    final sorted = List<int>.from(indices);
    switch (_sortBy) {
      case "Match %":
        sorted.sort((a, b) =>
            p.matchingPercentages[b].compareTo(p.matchingPercentages[a]));
        break;
      case "Name":
        sorted.sort((a, b) =>
            "${p.firstNames[a]} ${p.lastNames[a]}"
                .compareTo("${p.firstNames[b]} ${p.lastNames[b]}"));
        break;
      case "Age":
        sorted.sort((a, b) => p.age[a].compareTo(p.age[b]));
        break;
      case "Online First":
        sorted.sort((a, b) {
          if (p.isOnlineList[a] && !p.isOnlineList[b]) return -1;
          if (!p.isOnlineList[a] && p.isOnlineList[b]) return 1;
          return p.matchingPercentages[b].compareTo(p.matchingPercentages[a]);
        });
        break;
      case "Recently Shared":
        sorted.sort((a, b) {
          final aShared = _sharedProfileIds.contains(p.ids[a]);
          final bShared = _sharedProfileIds.contains(p.ids[b]);
          if (aShared && !bShared) return -1;
          if (!aShared && bShared) return 1;
          if (aShared && bShared) {
            final aTs = _lastShareTimestamp[p.ids[a]] ?? DateTime(1970);
            final bTs = _lastShareTimestamp[p.ids[b]] ?? DateTime(1970);
            return bTs.compareTo(aTs);
          }
          return p.matchingPercentages[b].compareTo(p.matchingPercentages[a]);
        });
        break;
    }
    return sorted;
  }

  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _sendMessage(
    String matched,
    String memberid,
    String gender,
    String occupation,
    String education,
    String marit,
    String age,
    int profileId,
    String firstName,
    String lastName,
    String? profilePicture,
    String country,
  ) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      final profileData = {
        'id':           profileId,
        'name':         '$firstName $lastName',
        'profileImage': profilePicture ?? 'https://via.placeholder.com/150',
        'bio':          '$matched% Matched',
        'Member ID':    memberid,
        'occupation':   occupation,
        'marit':        marit,
        'education':    education,
        'gender':       gender,
        'age':          age,
        'last':         lastName,
        'first':        firstName,
        'is_paid':      chatProvider.ispaid,
        'country':      country,
      };

      await _firestore.collection('adminchat').add({
        'message':     'Profile Shared',
        'liked':       false,
        'replyto':     '',
        'senderid':    '1',
        'receiverid':  chatProvider.id.toString(),
        'timestamp':   FieldValue.serverTimestamp(),
        'type':        'profile_card',
        'profileData': profileData,
      });

      await _firestore.collection('profile_shares').add({
        'shared_by':        '1',
        'shared_to':        chatProvider.id.toString(),
        'profile_id':       profileId,
        'profile_name':     '$firstName $lastName',
        'profile_member_id': memberid,
        'timestamp':        FieldValue.serverTimestamp(),
        'status':           'sent',
      });

      final convId = _getConversationId('1', chatProvider.id.toString());
      await _firestore.collection('conversations').doc(convId).set({
        'participants':          ['1', chatProvider.id.toString()],
        'lastMessage':           'Shared a profile: $firstName $lastName',
        'lastTimestamp':         FieldValue.serverTimestamp(),
        'lastSharedProfileId':   profileId,
        'lastSharedProfileName': '$firstName $lastName',
      }, SetOptions(merge: true));

      // Refresh share data
      await _loadSharedProfilesForUser(chatProvider.id.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile shared successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: _kOnline,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to share profile: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _getConversationId(String a, String b) =>
      (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';

  String _timeAgo(DateTime ts) {
    final d = DateTime.now().difference(ts);
    if (d.inMinutes < 1)  return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours   < 24) return '${d.inHours}h';
    if (d.inDays    < 7)  return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Container(
      width: 300,
      color: _kCardBg,
      child: Column(
        children: [
          _buildHeader(chatProvider),
          _buildTabs(),
          _buildSearchBar(),
          _buildFilterRow(),
          if (_showFilters) _buildFilterPanel(),
          _buildStatsRow(chatProvider),
          const Divider(height: 1, color: _kBorder),
          Expanded(child: _buildProfileList()),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(ChatProvider chat) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: _kPrimary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Match Profiles',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                if (chat.namee != null)
                  Text('for ${chat.namee}',
                      style: const TextStyle(fontSize: 10, color: _kMuted),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Consumer<MatchedProfileProvider>(
            builder: (_, p, __) {
              if (_matchesLoaded && !p.isloading && chat.id != null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${p.ids.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _loadMatches,
                      child: const Tooltip(
                        message: 'Refresh matches',
                        child: Icon(Icons.refresh, size: 16, color: _kMuted),
                      ),
                    ),
                  ],
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${p.ids.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Row(
      children: [
        _tabBtn('Matched', 0),
        _tabBtn('All Profiles', 1),
      ],
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = widget.selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChange(index),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _kCardBg,
            border: Border(
              bottom: BorderSide(
                color: active ? _kPrimary : _kBorder,
                width: active ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _kPrimary : _kMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── Search ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search name, occupation, ID…',
            hintStyle: const TextStyle(fontSize: 11, color: _kMuted),
            prefixIcon: const Icon(Icons.search, size: 16, color: _kMuted),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14, color: _kMuted),
                    padding: EdgeInsets.zero,
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
            filled: true,
            fillColor: _kBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            isDense: true,
          ),
        ),
      ),
    );
  }

  // ── Filter row (chips) ───────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Row(
        children: [
          _filterChip('Paid',   _memberStatus == 'Paid',   () => setState(() => _memberStatus = _toggleFilter(_memberStatus, 'Paid'))),
          const SizedBox(width: 4),
          _filterChip('Online', _onlineStatus == 'Online', () => setState(() => _onlineStatus = _toggleFilter(_onlineStatus, 'Online'))),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _showFilters ? _kPrimaryLight : _kBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _showFilters ? _kPrimary : _kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 12,
                      color: _showFilters ? _kPrimary : _kMuted),
                  const SizedBox(width: 3),
                  Text('Sort',
                      style: TextStyle(
                          fontSize: 10,
                          color: _showFilters ? _kPrimary : _kMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? _kPrimaryLight : _kBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? _kPrimary : _kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? _kPrimary : _kMuted),
        ),
      ),
    );
  }

  // ── Collapsible sort/filter panel ────────────────────────────────────────
  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sort By',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: ['Match %', 'Name', 'Age', 'Online First', 'Recently Shared']
                .map((s) => GestureDetector(
                      onTap: () => setState(() => _sortBy = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _sortBy == s ? _kPrimary : _kCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _sortBy == s ? _kPrimary : _kBorder),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _sortBy == s
                                  ? Colors.white
                                  : _kMuted),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────────────────
  Widget _buildStatsRow(ChatProvider chat) {
    return StreamBuilder<QuerySnapshot>(
      stream: chat.id == null
          ? Stream.empty()
          : _firestore
              .collection('profile_shares')
              .where('shared_by', isEqualTo: '1')
              .where('shared_to', isEqualTo: chat.id.toString())
              .snapshots(),
      builder: (context, snap) {
        final total   = snap.hasData ? snap.data!.docs.length : 0;
        final unique  = _sharedProfileIds.length;
        return Container(
          margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(Icons.share_outlined, '$total', 'Total Shares',
                  const Color(0xFF16A34A)),
              Container(width: 1, height: 24,
                  color: const Color(0xFFBBF7D0)),
              _statItem(Icons.people_outline, '$unique', 'Unique Profiles',
                  const Color(0xFF0284C7)),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 1),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: const TextStyle(fontSize: 8, color: _kMuted)),
      ],
    );
  }

  // ── Profile list ─────────────────────────────────────────────────────────
  Widget _buildProfileList() {
    return Consumer<MatchedProfileProvider>(
      builder: (context, provider, _) {
        // ── Loading skeleton (first load) ──────────────────────────────
        if (provider.isloading) {
          return _buildSkeletonLoader();
        }

        // ── No user selected ──────────────────────────────────────────
        final chatProvider =
            Provider.of<ChatProvider>(context, listen: false);
        if (chatProvider.id == null) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Select a conversation',
            subtitle: 'Choose a user from the left panel to view matching profiles',
          );
        }

        // ── Show Match button (not yet loaded) ─────────────────────────
        if (!_matchesLoaded) {
          return _buildShowMatchButton(chatProvider);
        }

        final indices = _sortProfiles(
            _filterProfiles(provider), provider);

        // ── No results after filter ────────────────────────────────────
        if (provider.ids.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No matches yet',
            subtitle: 'No matching profiles found for this user',
            showRefetch: true,
          );
        }

        if (indices.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No results',
            subtitle: 'Try adjusting your search or filters',
            showClear: true,
          );
        }

        // ── Profile cards with scroll pagination ──────────────────────
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 6, bottom: 16),
          itemCount: indices.length + (provider.hasMore || provider.isLoadingMore ? 1 : 0),
          cacheExtent: 300,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, i) {
            // Pagination footer
            if (i == indices.length) {
              return _buildPaginationFooter(provider);
            }

            final idx       = indices[i];
            final profileId = provider.ids[idx];
            final isPaid    = provider.isPaidList[idx];
            final isOnline  = provider.isOnlineList[idx];
            final isShared  = _sharedProfileIds.contains(profileId);
            final shareCount = _sharedProfilesData[profileId]?['share_count'] ?? 0;
            final lastShareTs = _lastShareTimestamp[profileId];
            final pic       = provider.profilePictures.isNotEmpty
                ? provider.profilePictures[idx]
                : null;
            final matchPct  = provider.matchingPercentages[idx];
            final fullName  =
                '${provider.firstNames[idx]} ${provider.lastNames[idx]}';

            return _ProfileCard(
              key: ValueKey(profileId),
              profileId:   profileId,
              fullName:    fullName,
              firstName:   provider.firstNames[idx],
              lastName:    provider.lastNames[idx],
              memberid:    provider.memberiddd[idx],
              occupation:  provider.occupation[idx],
              age:         provider.age[idx],
              gender:      provider.gender[idx],
              matchPct:    matchPct,
              isPaid:      isPaid,
              isOnline:    isOnline,
              isShared:    isShared,
              shareCount:  shareCount,
              lastShareTs: lastShareTs,
              profilePicture: pic,
              onShare: () => _sendMessage(
                matchPct.toString(),
                provider.memberiddd[idx],
                provider.gender[idx],
                provider.occupation[idx],
                provider.education[idx],
                provider.marit[idx],
                provider.age[idx].toString(),
                profileId,
                provider.firstNames[idx],
                provider.lastNames[idx],
                pic,
                provider.country[idx],
              ),
              timeAgo: _timeAgo,
            );
          },
        );
      },
    );
  }

  // ── Show Match button ────────────────────────────────────────────────────
  Widget _buildShowMatchButton(ChatProvider chat) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.manage_search_rounded,
                  size: 30, color: _kPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              chat.namee != null
                  ? '${chat.namee} को म्याच हेर्नुहोस्'
                  : 'Match profiles',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText),
            ),
            const SizedBox(height: 6),
            const Text(
              'यस युजरसँग मिल्दो प्रोफाइलहरू लोड गर्न तलको बटन थिच्नुहोस्',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: _kMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _loadMatches,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD81B60), Color(0xFFAD1457)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Show Match',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pagination footer ────────────────────────────────────────────────────
  Widget _buildPaginationFooter(MatchedProfileProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
        ),
      );
    }
    if (provider.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: provider.fetchMoreProfiles,
            icon: const Icon(Icons.expand_more, size: 16, color: _kPrimary),
            label: const Text('Load more',
                style: TextStyle(fontSize: 11, color: _kPrimary)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'सबै ${provider.ids.length} म्याच देखाइयो',
          style: const TextStyle(fontSize: 10, color: _kMuted),
        ),
      ),
    );
  }

  // ── Skeleton loader ───────────────────────────────────────────────────────
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showClear = false,
    bool showRefetch = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: _kPrimary),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: _kMuted, height: 1.5)),
            if (showClear) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _memberStatus = 'All';
                  _onlineStatus = 'All';
                  _sortBy       = 'Match %';
                  _searchController.clear();
                }),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
                child: const Text('Clear filters',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
            if (showRefetch) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadMatches,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Retry',
                    style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Profile Card widget (extracted for performance via const constructor)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final int     profileId;
  final String  fullName;
  final String  firstName;
  final String  lastName;
  final String  memberid;
  final String  occupation;
  final int     age;
  final String  gender;
  final double  matchPct;
  final bool    isPaid;
  final bool    isOnline;
  final bool    isShared;
  final int     shareCount;
  final DateTime? lastShareTs;
  final String? profilePicture;
  final VoidCallback onShare;
  final String Function(DateTime) timeAgo;

  const _ProfileCard({
    Key? key,
    required this.profileId,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.memberid,
    required this.occupation,
    required this.age,
    required this.gender,
    required this.matchPct,
    required this.isPaid,
    required this.isOnline,
    required this.isShared,
    required this.shareCount,
    required this.lastShareTs,
    required this.profilePicture,
    required this.onShare,
    required this.timeAgo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPic = profilePicture != null && profilePicture!.isNotEmpty;
    final matchColor = matchPct >= 70
        ? const Color(0xFF16A34A)
        : matchPct >= 50
            ? _kPrimary
            : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isShared ? _kOnline : Colors.transparent,
            width: 3,
          ),
          right: const BorderSide(color: _kBorder),
          top:   const BorderSide(color: _kBorder),
          bottom: const BorderSide(color: _kBorder),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _kBg,
                  backgroundImage:
                      hasPic ? NetworkImage(profilePicture!) : null,
                  child: !hasPic
                      ? Icon(Icons.person, size: 22,
                          color: Colors.grey[400])
                      : null,
                ),
                // Online dot
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: isOnline ? _kOnline : const Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
                // Paid star
                if (isPaid)
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.star, size: 8,
                          color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 9),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row + match badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isPaid ? _kPrimary : _kText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: matchColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite,
                                size: 8, color: matchColor),
                            const SizedBox(width: 2),
                            Text(
                              '${matchPct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: matchColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Tags row
                  Row(
                    children: [
                      // Paid/Free badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isPaid ? _kPrimaryLight
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid ? 'Paid' : 'Free',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: isPaid ? _kPrimary
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      if (isShared) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 7,
                                  color: _kOnline),
                              const SizedBox(width: 2),
                              Text(
                                shareCount > 1
                                    ? 'Shared ×$shareCount'
                                    : 'Shared',
                                style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A)),
                              ),
                              if (lastShareTs != null) ...[
                                const SizedBox(width: 3),
                                Text(timeAgo(lastShareTs!),
                                    style: const TextStyle(
                                        fontSize: 7, color: _kMuted)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Occupation + age/gender row
                  Row(
                    children: [
                      const Icon(Icons.work_outline, size: 10,
                          color: _kMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          occupation.isNotEmpty ? occupation : '—',
                          style: const TextStyle(
                              fontSize: 10, color: _kMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${age}y · $gender',
                        style: const TextStyle(
                            fontSize: 10, color: _kMuted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // User ID + Member ID row
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 10,
                          color: _kMuted),
                      const SizedBox(width: 3),
                      Text(
                        '$profileId',
                        style: const TextStyle(
                            fontSize: 9,
                            color: _kMuted,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.badge_outlined, size: 10,
                          color: _kMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          memberid,
                          style: const TextStyle(
                              fontSize: 9,
                              color: _kMuted,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // View Profile + Share buttons
                  Row(
                    children: [
                      // View Profile button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => html.window.open(
                            'https://digitallami.com/profile.php?id=$profileId',
                            '_blank',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: _kPrimary, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded,
                                    size: 9, color: _kPrimary),
                                SizedBox(width: 3),
                                Text(
                                  'View Profile',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Share button
                      GestureDetector(
                        onTap: isShared ? null : onShare,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isShared
                                ? const Color(0xFFF0FDF4)
                                : _kPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isShared
                                    ? Icons.check
                                    : Icons.send_outlined,
                                size: 10,
                                color: isShared
                                    ? _kOnline
                                    : Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isShared ? 'Sent' : 'Share',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isShared
                                      ? _kOnline
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton loader card
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _kBg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(120, 10),
                const SizedBox(height: 6),
                _shimmerBox(80, 8),
                const SizedBox(height: 6),
                _shimmerBox(160, 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h) => Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
