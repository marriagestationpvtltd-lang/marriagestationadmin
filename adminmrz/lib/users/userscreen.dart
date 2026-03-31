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

  Widget _buildUserCard(User user, UserProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to UserDetailsScreen when tapped anywhere on the card
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (context) => UserDetailsProvider(),
                child: UserDetailsScreen(
                  userId: user.id,
                  myId: user.id, // Use the same user ID or admin ID if available
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with user info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox - Separate GestureDetector to prevent navigation on checkbox tap
                  GestureDetector(
                    onTap: () {
                      // Only handle checkbox tap, don't navigate
                      provider.toggleUserSelection(user.id);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Checkbox(
                        value: provider.isUserSelected(user.id),
                        onChanged: (value) {
                          provider.toggleUserSelection(user.id);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Profile Picture - Make it tappable for profile view
                  GestureDetector(
                    onTap: () {
                      // Navigate to UserDetailsScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                            create: (context) => UserDetailsProvider(),
                            child: UserDetailsScreen(
                              userId: user.id,
                              myId: user.id,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: user.hasProfilePicture
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(
                          user.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.blue,
                            );
                          },
                        ),
                      )
                          : const Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Name and Status - Make the name clickable too
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (context) => UserDetailsProvider(),
                              child: UserDetailsScreen(
                                userId: user.id,
                                myId: user.id,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user.statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: user.statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  user.formattedStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: user.statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user.usertype == 'paid'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user.usertype.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: user.usertype == 'paid'
                                        ? Colors.blue
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // User details row - Also make this area clickable
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (context) => UserDetailsProvider(),
                        child: UserDetailsScreen(
                          userId: user.id,
                          myId: user.id,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Gender
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gender',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  user.gender == 'Female'
                                      ? Icons.female
                                      : Icons.male,
                                  size: 16,
                                  color: user.gender == 'Female'
                                      ? Colors.pink
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user.gender,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Online Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: user.isOnline == 1
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  user.isOnline == 1 ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: user.isOnline == 1
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // User ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'User ID',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${user.id}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // View Profile Button
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.blue.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions Row
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View Full Profile Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (context) => UserDetailsProvider(),
                              child: UserDetailsScreen(
                                userId: user.id,
                                myId: user.id,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_outline, size: 16),
                      label: const Text('View Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick Actions Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('View Full Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'message',
                        child: Row(
                          children: [
                            Icon(Icons.message, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Send Message'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'email',
                        child: Row(
                          children: [
                            Icon(Icons.email, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Send Email'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (context) => UserDetailsProvider(),
                              child: UserDetailsScreen(
                                userId: user.id,
                                myId: user.id,
                              ),
                            ),
                          ),
                        );
                      } else if (value == 'message') {
                        // TODO: Implement send message
                      } else if (value == 'email') {
                        // TODO: Implement send email
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
  Widget _buildFilters(BuildContext context, UserProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (provider.statusFilter != 'all' ||
                    provider.userTypeFilter != 'all')
                  TextButton(
                    onPressed: provider.clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Status Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.statusFilter,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          provider.setStatusFilter(newValue);
                        }
                      },
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.filter_alt, size: 16),
                              SizedBox(width: 6),
                              Text('All Status'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'approved',
                          child: Text('Approved'),
                        ),
                        const DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        const DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Rejected'),
                        ),
                        const DropdownMenuItem(
                          value: 'not_uploaded',
                          child: Text('Not Uploaded'),
                        ),
                      ],
                    ),
                  ),
                ),

                // User Type Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.userTypeFilter,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          provider.setUserTypeFilter(newValue);
                        }
                      },
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.category, size: 16),
                              SizedBox(width: 6),
                              Text('All Types'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'paid',
                          child: Text('Paid'),
                        ),
                        const DropdownMenuItem(
                          value: 'free',
                          child: Text('Free'),
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
    );
  }

  Widget _buildStats(BuildContext context, UserProvider provider) {
    final statusStats = provider.getStatusStats();
    final typeStats = provider.getUserTypeStats();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Total Users',
                    provider.totalCount.toString(),
                    Icons.people_outline,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Filtered',
                    provider.filteredCount.toString(),
                    Icons.filter_alt_outlined,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Selected',
                    provider.selectedCount.toString(),
                    Icons.check_circle_outline,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMiniStatChip(
                  'Approved',
                  statusStats['approved'] ?? 0,
                  Colors.green,
                ),
                _buildMiniStatChip(
                  'Pending',
                  statusStats['pending'] ?? 0,
                  Colors.orange,
                ),
                _buildMiniStatChip(
                  'Rejected',
                  statusStats['rejected'] ?? 0,
                  Colors.red,
                ),
                _buildMiniStatChip(
                  'Not Uploaded',
                  statusStats['not_uploaded'] ?? 0,
                  Colors.grey,
                ),
                _buildMiniStatChip(
                  'Paid',
                  typeStats['paid'] ?? 0,
                  Colors.blue,
                ),
                _buildMiniStatChip(
                  'Free',
                  typeStats['free'] ?? 0,
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserProvider provider) {
    if (provider.selectedCount == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade500,
                      ),
                    ),
                    Text(
                      '${provider.selectedCount} selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: provider.clearSelection,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.suspendSelectedUsers(context),
                    icon: const Icon(Icons.pause_circle, size: 18),
                    label: const Text('Suspend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.deleteSelectedUsers(context),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllRow(BuildContext context, UserProvider provider) {
    if (provider.filteredUsers.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: provider.areAllFilteredSelected,
              onChanged: (value) {
                provider.selectAllUsers();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              provider.areAllFilteredSelected ? 'Deselect All' : 'Select All',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${provider.filteredCount} users',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            const Spacer(),
            if (provider.selectedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.selectedCount} selected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(UserProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.people_outline,
          size: 80,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 20),
        Text(
          provider.searchQuery.isNotEmpty
              ? 'No users found for "${provider.searchQuery}"'
              : 'No users available',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        if (provider.statusFilter != 'all' || provider.userTypeFilter != 'all')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: provider.clearFilters,
              child: const Text('Clear Filters'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchUsers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
                    : null,
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),

          // Main Content in ScrollView
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchUsers(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Statistics
                    _buildStats(context, provider),

                    // Filters
                    _buildFilters(context, provider),

                    // Action Buttons (if selected)
                    _buildActionButtons(context, provider),

                    // Select All Row
                    _buildSelectAllRow(context, provider),

                    // User List or Empty State
                    if (provider.filteredUsers.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: _buildEmptyState(provider),
                      )
                    else
                      Column(
                        children: [
                          // List Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Users List',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${provider.filteredUsers.length} users',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // User Cards
                          ...provider.filteredUsers.map((user) {
                            return _buildUserCard(user, provider);
                          }).toList(),

                          const SizedBox(height: 20),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}