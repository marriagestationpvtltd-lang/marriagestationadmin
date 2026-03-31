import 'package:adminmrz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dashmodel.dart';
import 'dashservice.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String _error = '';
  final DashboardService _dashboardService = DashboardService();
  final DateFormat _dateFormat = DateFormat('EEEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData({bool forceRefresh = false}) async {
    if (!forceRefresh && _dashboardData != null) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await _dashboardService.getDashboardData();
      setState(() {
        _dashboardData = response.data;
      });
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: AppTheme.radiusSm,
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUsersTable(List<RecentUser> users) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Recent Registrations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No recent users', style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBg),
                columns: const [
                  DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Joined', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                rows: users.map((user) {
                  final isActive = user.isActive == 1;
                  return DataRow(cells: [
                    DataCell(Text('#${user.id}')),
                    DataCell(Text(user.fullName.isEmpty ? '—' : user.fullName)),
                    DataCell(Text(user.email ?? '—')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: user.gender?.toLowerCase() == 'female'
                              ? const Color(0xFFFCE4EC)
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.gender ?? '—',
                          style: TextStyle(
                            fontSize: 11,
                            color: user.gender?.toLowerCase() == 'female'
                                ? const Color(0xFFC2185B)
                                : const Color(0xFF1565C0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.successLight : AppTheme.errorLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? AppTheme.success : AppTheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      user.createdDate != null && user.createdDate!.length >= 10
                          ? user.createdDate!.substring(0, 10)
                          : user.createdDate ?? '—',
                    )),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _fetchDashboardData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      );
    }

    final data = _dashboardData;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => _fetchDashboardData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  _dateFormat.format(DateTime.now()),
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _fetchDashboardData(forceRefresh: true),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    _buildKpiCard(
                      title: "Today's Registrations",
                      value: data.todayRegistration.toString(),
                      icon: Icons.person_add_outlined,
                      gradient: AppTheme.primaryGradient,
                      subtitle: 'New members today',
                    ),
                    _buildKpiCard(
                      title: 'Monthly Registrations',
                      value: data.monthlyRegistration.toString(),
                      icon: Icons.group_add_outlined,
                      gradient: AppTheme.blueGradient,
                      subtitle: 'This month',
                    ),
                    _buildKpiCard(
                      title: "Today's Proposals",
                      value: data.todayProposal.toString(),
                      icon: Icons.favorite_outline,
                      gradient: AppTheme.goldGradient,
                      subtitle: 'Sent today',
                    ),
                    _buildKpiCard(
                      title: 'Monthly Proposals',
                      value: data.monthlyProposal.toString(),
                      icon: Icons.favorite_border,
                      gradient: AppTheme.greenGradient,
                      subtitle: 'This month',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Users Table
            _buildRecentUsersTable(data.recentUsers),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
