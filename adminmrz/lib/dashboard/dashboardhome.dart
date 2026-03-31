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

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await _dashboardService.getDashboardData();
      if (response.success) {
        setState(() => _dashboardData = response.dashboard);
      } else {
        setState(() => _error = 'Failed to load dashboard data');
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── KPI Card ─────────────────────────────────────────────────────────────
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
    String? subtitle,
    String? badge,
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
          // Top gradient banner
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: AppTheme.radiusSm,
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: AppTheme.radiusSm,
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title,
      {String? subtitle, Widget? action}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: AppTheme.radiusSm,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  // ─── Info Card wrapper ─────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: child,
    );
  }

  // ─── User Stats ────────────────────────────────────────────────────────────
  Widget _buildUserStats() {
    final users = _dashboardData?.users;
    if (users == null) return const SizedBox.shrink();

    final cards = [
      (
        'Total Members',
        users.total.toString(),
        Icons.people_alt_outlined,
        AppTheme.primaryGradient,
        'All registered',
      ),
      (
        'Active Members',
        users.active.toString(),
        Icons.check_circle_outline,
        AppTheme.greenGradient,
        'Currently active',
      ),
      (
        'Online Now',
        users.online.toString(),
        Icons.wifi_rounded,
        AppTheme.blueGradient,
        'Live users',
      ),
      (
        'Verified',
        users.verified.toString(),
        Icons.verified_outlined,
        AppTheme.purpleGradient,
        'ID verified',
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: cards
          .map((c) => _buildKpiCard(
                title: c.$1,
                value: c.$2,
                icon: c.$3,
                gradient: c.$4,
                subtitle: c.$5,
              ))
          .toList(),
    );
  }

  // ─── Payment Stats ─────────────────────────────────────────────────────────
  Widget _buildPaymentStats() {
    final payments = _dashboardData?.payments;
    if (payments == null) return const SizedBox.shrink();

    final cards = [
      (
        'Total Revenue',
        payments.totalEarning,
        Icons.account_balance_wallet_outlined,
        AppTheme.greenGradient,
        'All time earnings',
      ),
      (
        "Today's Revenue",
        payments.todayEarning,
        Icons.today_outlined,
        AppTheme.primaryGradient,
        'Earned today',
      ),
      (
        'Monthly Revenue',
        payments.thisMonthEarning,
        Icons.bar_chart_outlined,
        AppTheme.blueGradient,
        'This month',
      ),
      (
        'Total Sales',
        payments.totalSold.toString(),
        Icons.shopping_bag_outlined,
        AppTheme.goldGradient,
        'Packages sold',
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      children: cards
          .map((c) => _buildKpiCard(
                title: c.$1,
                value: c.$2,
                icon: c.$3,
                gradient: c.$4,
                subtitle: c.$5,
              ))
          .toList(),
    );
  }

  // ─── Best Selling Package ──────────────────────────────────────────────────
  Widget _buildPackageStats() {
    final payments = _dashboardData?.payments;
    if (payments == null) return const SizedBox.shrink();

    final best = payments.bestSellingPackage;

    return _buildCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: AppTheme.radiusMd,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_outlined,
                size: 36, color: Colors.white),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best Selling Package',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  best.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${best.total} packages sold',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: AppTheme.radiusXl,
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Top Seller',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── User Distribution ─────────────────────────────────────────────────────
  Widget _buildUserDistribution() {
    final users = _dashboardData?.users;
    if (users == null) return const SizedBox.shrink();

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Member Analytics',
              subtitle: 'Distribution by type & gender'),
          const SizedBox(height: 20),
          Row(
            children: [
              // By Type
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.infoLight,
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 16, color: AppTheme.info),
                          const SizedBox(width: 8),
                          Text(
                            'By Membership Type',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...users.byType.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                type.usertype.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withOpacity(0.12),
                                  borderRadius: AppTheme.radiusSm,
                                ),
                                child: Text(
                                  '${type.total}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // By Gender
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wc_outlined,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'By Gender',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...users.byGender.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                g.gender,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  borderRadius: AppTheme.radiusSm,
                                ),
                                child: Text(
                                  '${g.total}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  // ─── Payment Methods ───────────────────────────────────────────────────────
  Widget _buildPaymentMethodDistribution() {
    final payments = _dashboardData?.payments;
    if (payments == null || payments.byMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    final methodColors = [
      AppTheme.primaryGradient,
      AppTheme.blueGradient,
      AppTheme.goldGradient,
      AppTheme.greenGradient,
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Payment Methods',
              subtitle: 'Transaction breakdown by method'),
          const SizedBox(height: 20),
          ...payments.byMethod.asMap().entries.map((entry) {
            final method = entry.value;
            final idx = entry.key % methodColors.length;
            final pct = payments.totalSold > 0
                ? (method.total / payments.totalSold * 100)
                : 0.0;
            final gradient = methodColors[idx];

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: gradient,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            method.paidby,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${method.total} (${pct.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: AppTheme.radiusSm,
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          gradient.colors.first),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Address Info ──────────────────────────────────────────────────────────
  Widget _buildAddressInfo() {
    final address = _dashboardData?.permanentAddress;
    if (address == null) return const SizedBox.shrink();

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Geographic Distribution',
              subtitle: 'Member location analytics'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Members with Address',
                  value: address.totalWithAddress.toString(),
                  icon: Icons.location_on_outlined,
                  gradient: AppTheme.purpleGradient,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildKpiCard(
                  title: 'Residential Types',
                  value: address.byResidentialStatus.length.toString(),
                  icon: Icons.home_outlined,
                  gradient: AppTheme.blueGradient,
                  subtitle: 'distinct types',
                ),
              ),
            ],
          ),
          if (address.byCountry.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Top Countries',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: address.byCountry
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: AppTheme.radiusSm,
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.20)),
                      ),
                      child: Text(
                        '${c.country} · ${c.total}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Recent Activity ───────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    final items = [
      (
        Icons.person_add_outlined,
        AppTheme.greenGradient,
        'New Member Registration',
        'A new profile was created and is pending verification',
        '2 min ago',
      ),
      (
        Icons.payment_outlined,
        AppTheme.blueGradient,
        'Payment Received',
        'Gold package subscription payment confirmed',
        '15 min ago',
      ),
      (
        Icons.verified_outlined,
        AppTheme.primaryGradient,
        'Document Verified',
        'ID document approved for profile matching',
        '1 hour ago',
      ),
      (
        Icons.favorite_outline,
        AppTheme.goldGradient,
        'Match Suggested',
        'Compatible profiles matched by the system',
        '2 hours ago',
      ),
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recent Activity',
              subtitle: 'Latest platform events'),
          const SizedBox(height: 18),
          ...items.asMap().entries.map(
                (entry) {
                  final icon = entry.value.$1;
                  final gradient = entry.value.$2;
                  final title = entry.value.$3;
                  final description = entry.value.$4;
                  final time = entry.value.$5;
                  return Column(
                    children: [
                      if (entry.key > 0) ...[
                        Divider(color: AppTheme.borderLight, height: 1),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: AppTheme.radiusSm,
                            ),
                            child: Icon(icon, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
        ],
      ),
    );
  }

  // ─── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: AppTheme.radiusXl,
            ),
            child: const CircularProgressIndicator(color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading dashboard data...',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.errorLight,
              borderRadius: AppTheme.radiusXl,
            ),
            child: const Icon(Icons.error_outline,
                size: 48, color: AppTheme.error),
          ),
          const SizedBox(height: 20),
          Text(
            _error,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchDashboardData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ─── Main Content ──────────────────────────────────────────────────────────
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Banner ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.radiusLg,
              boxShadow: AppTheme.primaryShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to Marriage Station',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dateFormat.format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildBannerBadge(
                              Icons.people, 'Members Management'),
                          const SizedBox(width: 10),
                          _buildBannerBadge(
                              Icons.favorite, 'Matchmaking Platform'),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: AppTheme.radiusLg,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Member Stats ────────────────────────────────────────────────
          Row(
            children: [
              _buildSectionHeader('Member Overview',
                  subtitle: 'Real-time member statistics'),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _fetchDashboardData,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUserStats(),

          const SizedBox(height: 28),

          // ── Revenue ─────────────────────────────────────────────────────
          _buildSectionHeader('Revenue Overview',
              subtitle: 'Financial performance metrics'),
          const SizedBox(height: 16),
          _buildPaymentStats(),

          const SizedBox(height: 28),

          // ── Best Package + Analytics (side by side) ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Package Performance'),
                    const SizedBox(height: 16),
                    _buildPackageStats(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Payment Methods',
                        subtitle: 'Transaction breakdown'),
                    const SizedBox(height: 16),
                    _buildPaymentMethodDistribution(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Recent Activity',
                        subtitle: 'Latest events'),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Member Analytics ────────────────────────────────────────────
          _buildSectionHeader('Member Analytics',
              subtitle: 'Distribution insights'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildUserDistribution()),
              const SizedBox(width: 20),
              Expanded(child: _buildAddressInfo()),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBannerBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: AppTheme.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? _buildLoadingState()
        : _error.isNotEmpty
            ? _buildErrorState()
            : _buildDashboardContent();
  }
}
