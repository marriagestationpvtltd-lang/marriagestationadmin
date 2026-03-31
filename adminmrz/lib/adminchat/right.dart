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
      color: Colors.grey[200],
      child: Column(
        children: [
          // 🔘 Matched Profile & All Profiles Tabs
          Row(
            children: [
              _tabButton("Matched ${filteredIndices.length}", 0),
              _tabButton("All Profiles", 1),
            ],
          ),

          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name, occupation...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // 📂 Filters Toggle Button
          ListTile(
            leading: Icon(Icons.filter_list),
            title: Text("Filters"),
            trailing: Icon(_showFilters ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),

          // 📌 Collapsible Filters
          if (_showFilters)
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Member Status", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _memberStatus,
                    isExpanded: true,
                    items: ["All Members", "Paid Members", "Unpaid Members"]
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _memberStatus = value!;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text("Online Status", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _onlineStatus,
                    isExpanded: true,
                    items: ["All Profiles", "Online Members", "Offline Members"]
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _onlineStatus = value!;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text("Sort By", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    items: ["Match %", "Name", "Age", "Recently Active", "Recently Shared"]
                        .map((sort) => DropdownMenuItem(value: sort, child: Text(sort)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  // Active filters summary
                  if (_memberStatus != "All Members" || _onlineStatus != "All Profiles")
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${filteredIndices.length} profiles match your filters',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _memberStatus = "All Members";
                                _onlineStatus = "All Profiles";
                                _sortBy = "Match %";
                              });
                            },
                            child: Text('Clear', style: TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // 📊 Shared Profiles Counter for current user
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
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.share,
                      value: sharedCount.toString(),
                      label: 'Total Shares',
                      color: Colors.blue,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.blue.shade200,
                    ),
                    _buildStatItem(
                      icon: Icons.people,
                      value: uniqueProfiles.toString(),
                      label: 'Unique Profiles',
                      color: Colors.green,
                    ),
                  ],
                ),
              );
            },
          ),

          // 🔄 Recently Shared Profiles Horizontal List for current user
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('profile_shares')
                .where('shared_by', isEqualTo: '1')
                .where('shared_to', isEqualTo: chatProvider.id?.toString() ?? '')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SizedBox.shrink();
              }

              return Container(
                height: 60,
                margin: EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Recently Shared with ${chatProvider.namee ?? "User"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var share = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          int profileId = share['profile_id'] as int;
                          int shareCount = _sharedProfilesData[profileId]?['share_count'] ?? 1;

                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.share, size: 12, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  share['profile_name'] ?? 'Profile',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (shareCount > 1)
                                  Container(
                                    margin: EdgeInsets.only(left: 4),
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$shareCount',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                SizedBox(width: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Shared',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
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

          // 📜 Profile List
          Expanded(
            child: Consumer<MatchedProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isloading) {
                  return Center(child: CircularProgressIndicator());
                }

                List<int> filteredIndices = _filterProfiles(provider);
                filteredIndices = _sortProfiles(filteredIndices, provider);

                if (filteredIndices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 48, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'No profiles found',
                          style: TextStyle(color: Colors.grey),
                        ),
                        if (_memberStatus != "All Members" || _onlineStatus != "All Profiles" || _searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _memberStatus = "All Members";
                                _onlineStatus = "All Profiles";
                                _sortBy = "Match %";
                                _searchController.clear();
                              });
                            },
                            child: Text('Clear filters'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredIndices.length,
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

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: isShared ? 2 : 1,
                      child: Container(
                        decoration: isShared ? BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.green, width: 3),
                          ),
                        ) : null,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(8),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                                    ? NetworkImage(profilePicture)
                                    : null,
                                child: profilePicture == null || profilePicture.isEmpty
                                    ? Icon(Icons.person, size: 30, color: Colors.grey[700])
                                    : null,
                              ),
                              // Online/Offline indicator
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                              // Paid member badge
                              if (isPaid)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${provider.firstNames[profileIndex]} ${provider.lastNames[profileIndex]}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isPaid ? Colors.amber[800] : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPaid ? Colors.pink : Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isPaid ? "Paid" : "Free",
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              // Shared badge with count and time
                              if (isShared)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 10),
                                            SizedBox(width: 2),
                                            Text(
                                              'Shared ${shareCount > 1 ? '$shareCount times' : ''}',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (lastShareTime != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Text(
                                            _getTimeAgo(lastShareTime),
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.work, size: 12, color: Colors.grey),
                                  SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      provider.occupation[profileIndex],
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.cake, size: 12, color: Colors.grey),
                                  SizedBox(width: 2),
                                  Text(
                                    'Age: ${provider.age[profileIndex]}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.wc, size: 12, color: Colors.grey),
                                  SizedBox(width: 2),
                                  Text(
                                    provider.gender[profileIndex],
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.badge, size: 12, color: Colors.grey),
                                  SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      "ID: ${provider.memberiddd[profileIndex]}",
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.favorite, color: Colors.red, size: 12),
                                        SizedBox(width: 2),
                                        Text(
                                          "${provider.matchingPercentages[profileIndex]}%",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.favorite_border, color: Colors.red, size: 18),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Liked ${provider.firstNames[profileIndex]}'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.share, color: Colors.blue, size: 18),
                                    onPressed: isShared ? null : () {
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
                                      ).then((_) {
                                        // Reload shared profiles after sharing
                                        _loadSharedProfilesForUser();
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChange(index),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.selectedTab == index ? Colors.pink : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: widget.selectedTab == index ? Colors.pink : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: widget.selectedTab == index ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}