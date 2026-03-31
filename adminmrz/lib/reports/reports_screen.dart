import 'dart:convert';
import 'package:adminmrz/core/app_constants.dart';
import 'package:adminmrz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportTab {
  final String label;
  final String endpoint;
  final IconData icon;

  const _ReportTab({required this.label, required this.endpoint, required this.icon});
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<_ReportTab> _tabs = [
    _ReportTab(
      label: 'User Report',
      endpoint: '/admin/report/getApplicationUserReport',
      icon: Icons.people_outline,
    ),
    _ReportTab(
      label: 'Monthly Reg.',
      endpoint: '/admin/report/getMasterEntryData',
      icon: Icons.calendar_month_outlined,
    ),
    _ReportTab(
      label: 'Send Proposals',
      endpoint: '/admin/report/getMonthlySendProposalUser',
      icon: Icons.send_outlined,
    ),
    _ReportTab(
      label: 'Receive Proposals',
      endpoint: '/admin/report/getMonthlyReceiveProposalUser',
      icon: Icons.inbox_outlined,
    ),
    _ReportTab(
      label: 'Top Senders',
      endpoint: '/admin/report/getTopProposalSendReqReport',
      icon: Icons.trending_up_outlined,
    ),
    _ReportTab(
      label: 'Top Receivers',
      endpoint: '/admin/report/getTopProposalReceiveReqReport',
      icon: Icons.trending_down_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.cardBg,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: _tabs.map((t) => Tab(icon: Icon(t.icon, size: 16), text: t.label)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) => _ReportTabView(tab: tab)).toList(),
          ),
        ),
      ],
    );
  }
}

class _ReportTabView extends StatefulWidget {
  final _ReportTab tab;
  const _ReportTabView({required this.tab});

  @override
  State<_ReportTabView> createState() => _ReportTabViewState();
}

class _ReportTabViewState extends State<_ReportTabView>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}${widget.tab.endpoint}'),
            headers: await _authHeaders(),
            body: json.encode({}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        if (status == 200 || status?.toString() == '200') {
          final records = (data['recordList'] ?? []) as List;
          setState(() {
            _records = records.map((r) => Map<String, dynamic>.from(r)).toList();
          });
        } else {
          setState(() => _error = data['message']?.toString() ?? 'Failed to load report');
        }
      } else {
        setState(() => _error = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      );
    }

    if (_records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text('No data available', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    final columns = _records.first.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_records.length} records',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: AppTheme.radiusMd,
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.cardShadow,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.scaffoldBg),
                    columnSpacing: 24,
                    columns: columns
                        .map((col) => DataColumn(
                              label: Text(
                                _formatColumnName(col),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ))
                        .toList(),
                    rows: _records.map((row) {
                      return DataRow(
                        cells: columns.map((col) {
                          final val = row[col];
                          return DataCell(
                            Text(
                              val?.toString() ?? '—',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatColumnName(String col) {
    return col
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
