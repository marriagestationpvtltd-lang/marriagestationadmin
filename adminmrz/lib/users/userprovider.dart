import 'package:adminmrz/users/service/userservice.dart';
import 'package:flutter/material.dart';

import 'model/usermodel.dart';


class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  Set<int> _selectedUserIds = {}; // Store selected user IDs
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _userTypeFilter = 'all';
  bool _isSelectAll = false;

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
  Set<int> get selectedUserIds => _selectedUserIds;
  bool get isSelectAll => _isSelectAll;
  int get selectedCount => _selectedUserIds.length;

  // Check if all filtered users are selected
  bool get areAllFilteredSelected {
    if (_filteredUsers.isEmpty) return false;
    return _selectedUserIds.length == _filteredUsers.length &&
        _filteredUsers.every((user) => _selectedUserIds.contains(user.id));
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _userService.getUsers();
      _allUsers = response.data;
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
      // Deselect all filtered users
      _selectedUserIds.removeAll(_filteredUsers.map((user) => user.id));
    } else {
      // Select all filtered users
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
  Future<void> suspendSelectedUsers(BuildContext context) async {
    if (_selectedUserIds.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
        context,
        'Suspend Users',
        'Are you sure you want to suspend ${_selectedUserIds.length} user(s)?'
    );

    if (confirmed) {
      _isLoading = true;
      notifyListeners();

      // TODO: Implement API call to suspend users
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Update local state (for demo)
      for (var user in _allUsers) {
        if (_selectedUserIds.contains(user.id)) {
          // Update user status to indicate suspended
          // This is just for demo - implement your actual API logic
        }
      }

      clearSelection();
      _isLoading = false;
      notifyListeners();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedUserIds.length} user(s) suspended successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> deleteSelectedUsers(BuildContext context) async {
    if (_selectedUserIds.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
        context,
        'Delete Users',
        'Are you sure you want to delete ${_selectedUserIds.length} user(s)? This action cannot be undone.'
    );

    if (confirmed) {
      _isLoading = true;
      notifyListeners();

      // TODO: Implement API call to delete users
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Update local state (for demo)
      _allUsers.removeWhere((user) => _selectedUserIds.contains(user.id));
      _applyFilters();

      clearSelection();
      _isLoading = false;
      notifyListeners();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedUserIds.length} user(s) deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _applyFilters() {
    List<User> filtered = List<User>.from(_allUsers);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.fullName.toLowerCase().contains(_searchQuery) ||
            user.email.toLowerCase().contains(_searchQuery) ||
            user.id.toString().contains(_searchQuery);
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered.where((user) => user.status == _statusFilter).toList();
    }

    // Apply user type filter
    if (_userTypeFilter != 'all') {
      filtered = filtered.where((user) => user.usertype == _userTypeFilter).toList();
    }

    _filteredUsers = filtered;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _userTypeFilter = 'all';
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
      stats[user.usertype] = stats[user.usertype]! + 1;
    }

    return stats;
  }
}