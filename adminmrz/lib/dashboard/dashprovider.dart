import 'dart:async';
import 'package:adminmrz/core/app_constants.dart';
import 'package:flutter/material.dart';

import 'dashmodel.dart';
import 'dashservice.dart';


class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  DashboardData? _dashboardData;
  bool _isLoading = false;
  String _error = '';
  DateTime? _lastFetchTime;
  Timer? _refreshTimer;

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String get error => _error;

  bool get _isCacheValid =>
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < AppConstants.liveCacheDuration;

  /// Fetch dashboard data. Uses cache unless [forceRefresh] is true.
  Future<void> fetchDashboardData({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _dashboardData != null) return;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dashboardService.getDashboardData();
      if (response.success) {
        _dashboardData = response.dashboard;
        _lastFetchTime = DateTime.now();
      } else {
        _error = 'Failed to load dashboard data';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start auto-refreshing dashboard data every [AppConstants.autoRefreshInterval].
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppConstants.autoRefreshInterval, (_) {
      fetchDashboardData(forceRefresh: true);
    });
  }

  /// Stop the auto-refresh timer.
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}