import 'package:adminmrz/core/app_constants.dart';
import 'package:adminmrz/users/service/userservice.dart';
import 'package:flutter/material.dart';

import 'model/usermodel.dart';


class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  Set<int> _selectedUserIds = {};
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _userTypeFilter = 'all';
  String _genderFilter = 'all';
  String _statFilter = 'all'; // quick-filter from stat cards
  bool _isSelectAll = false;

  // Cache tracking
  DateTime? _lastFetchTime;

  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < AppConstants.cacheDuration;

  // Getters
  List<User> get filteredUsers => _filteredUsers;
  List<User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalCount => _allUsers.length;
  int get filteredCount => _filteredUsers.length;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get userTypeFilter => _userTypeFilter;
  String get genderFilter => _genderFilter;
  String get statFilter => _statFilter;
  Set<int> get selectedUserIds => _selectedUserIds;
  bool get isSelectAll => _isSelectAll;
  int get selectedCount => _selectedUserIds.length;

  // Check if all filtered users are selected
  bool get areAllFilteredSelected {
    if (_filteredUsers.isEmpty) return false;
    return _selectedUserIds.length == _filteredUsers.length &&
        _filteredUsers.every((user) => _selectedUserIds.contains(user.id));
  }

  Future<void> fetchUsers({bool forceRefresh = false}) async {
    // Serve from cache if data is fresh
    if (!forceRefresh && _isCacheValid && _allUsers.isNotEmpty) return;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userService.getUsers();
      _allUsers = response.data;
      _lastFetchTime = DateTime.now();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Selection methods
  void toggleUserSelection(int userId) {
    if (_selectedUserIds.contains(userId)) {
      _selectedUserIds.remove(userId);
    } else {
      _selectedUserIds.add(userId);
    }
    _updateSelectAllState();
    notifyListeners();
  }

  void selectAllUsers() {
    if (areAllFilteredSelected) {
      _selectedUserIds.removeAll(_filteredUsers.map((user) => user.id));
    } else {
      _selectedUserIds.addAll(_filteredUsers.map((user) => user.id));
    }
    _updateSelectAllState();
    notifyListeners();
  }

  void _updateSelectAllState() {
    _isSelectAll = areAllFilteredSelected;
  }

  void clearSelection() {
    _selectedUserIds.clear();
    _isSelectAll = false;
    notifyListeners();
  }

  bool isUserSelected(int userId) {
    return _selectedUserIds.contains(userId);
  }

  // Action methods
  /// Suspend a single user by [userId]. Shows no dialog – caller is responsible
  /// for prior confirmation.
  Future<bool> suspendUser(int userId) async {
    try {
      final success = await _userService.suspendUsers([userId]);
      if (success) {
        _lastFetchTime = null; // Invalidate cache
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> suspendSelectedUsers(BuildContext context) async {
    if (_selectedUserIds.isEmpty) return;

    final count = _selectedUserIds.length;
    final confirmed = await _showConfirmationDialog(
        context,
        'Suspend Users',
        'Are you sure you want to suspend $count user(s)?'
    );

    if (!confirmed) return;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _userService.suspendUsers(_selectedUserIds.toList());
      if (success) {
        // Invalidate cache so next fetch reflects new status
        _lastFetchTime = null;
        clearSelection();
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count user(s) suspended successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _error = 'Failed to suspend users';
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to suspend users. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteSelectedUsers(BuildContext context) async {
    if (_selectedUserIds.isEmpty) return;

    final count = _selectedUserIds.length;
    final confirmed = await _showConfirmationDialog(
        context,
        'Delete Users',
        'Are you sure you want to delete $count user(s)? This action cannot be undone.'
    );

    if (!confirmed) return;

    _isLoading = true;
    notifyListeners();

    try {
      final idsToDelete = _selectedUserIds.toList();
      final success = await _userService.deleteUsers(idsToDelete);
      if (success) {
        // Remove deleted users from local lists immediately
        _allUsers.removeWhere((user) => idsToDelete.contains(user.id));
        _lastFetchTime = DateTime.now(); // mark cache fresh after mutation
        _applyFilters();
        clearSelection();
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count user(s) deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        _error = 'Failed to delete users';
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete users. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: title.contains('Delete') ? Colors.red : Colors.orange,
            ),
            child: Text(title.contains('Delete') ? 'Delete' : 'Suspend'),
          ),
        ],
      ),
    ) ?? false;
  }

  void setStatFilter(String key) {
    // Tapping the active card (or 'all') clears the quick-filter
    _statFilter = _statFilter == key ? 'all' : key;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setUserTypeFilter(String userType) {
    _userTypeFilter = userType;
    _applyFilters();
  }

  void setGenderFilter(String gender) {
    _genderFilter = gender;
    _applyFilters();
  }

  void _applyFilters() {
    List<User> filtered = List<User>.from(_allUsers);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.fullName.toLowerCase().contains(_searchQuery) ||
            user.email.toLowerCase().contains(_searchQuery) ||
            user.id.toString().contains(_searchQuery);
      }).toList();
    }

    if (_statusFilter != 'all') {
      filtered = filtered.where((user) => user.status == _statusFilter).toList();
    }

    if (_userTypeFilter != 'all') {
      filtered = filtered.where((user) => user.usertype == _userTypeFilter).toList();
    }

    if (_genderFilter != 'all') {
      filtered = filtered.where((user) => user.gender == _genderFilter).toList();
    }

    // ── Quick-filter from stat cards ────────────────────────────────────────
    switch (_statFilter) {
      case 'verified':
        filtered = filtered.where((u) => u.isVerified == 1).toList();
        break;
      case 'pending':
        filtered = filtered.where((u) => u.status == 'pending').toList();
        break;
      case 'approved':
        filtered = filtered.where((u) => u.status == 'approved').toList();
        break;
      case 'paid':
        filtered = filtered.where((u) => u.usertype == 'paid').toList();
        break;
      case 'online':
        filtered = filtered.where((u) => u.isOnline == 1).toList();
        break;
      default:
        break; // 'all' — no extra filter
    }

    _filteredUsers = filtered;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _userTypeFilter = 'all';
    _genderFilter = 'all';
    _statFilter = 'all';
    _applyFilters();
  }

  Map<String, int> getStatusStats() {
    Map<String, int> stats = {
      'approved': 0,
      'pending': 0,
      'rejected': 0,
      'not_uploaded': 0,
    };

    for (var user in _allUsers) {
      if (stats.containsKey(user.status)) {
        stats[user.status] = stats[user.status]! + 1;
      }
    }

    return stats;
  }

  Map<String, int> getUserTypeStats() {
    Map<String, int> stats = {
      'paid': 0,
      'free': 0,
    };

    for (var user in _allUsers) {
      stats[user.usertype] = (stats[user.usertype] ?? 0) + 1;
    }

    return stats;
  }
}