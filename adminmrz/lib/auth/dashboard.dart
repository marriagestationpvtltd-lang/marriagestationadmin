import 'package:adminmrz/auth/service.dart';
import 'package:adminmrz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../adminchat/left.dart';
import '../adminchat/loading.dart';
import '../dashboard/dashboardhome.dart';
import '../document/screens/docscreen.dart';
import '../masterdata/masterdata_screen.dart';
import '../package/packageScreen.dart';
import '../payment/paymentscreen.dart';
import '../reports/reports_screen.dart';
import '../users/userscreen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  String _pageTitle = 'Dashboard';
  String _pageSubtitle = 'Overview & Analytics';

  final List<Widget> _pages = [
    const DashboardHome(),
    const UsersPage(),
    const DocumentsPage(),
    const PackagesPage(),
    const PaymentsPage(),
    Loading(),
    const MasterDataScreen(),
    const ReportsScreen(),
  ];

  final List<String> _pageTitles = [
    'Dashboard',
    'Members',
    'Documents',
    'Packages',
    'Payments',
    'Chat',
    'Master Data',
    'Reports',
  ];

  final List<String> _pageSubtitles = [
    'Overview & Analytics',
    'Manage Member Profiles',
    'Document Verification',
    'Subscription Packages',
    'Payment History',
    'Support Chat',
    'Manage Lookup Values',
    'Analytics & Reports',
  ];

  final List<IconData> _navIcons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.folder_open_outlined,
    Icons.card_membership_outlined,
    Icons.receipt_long_outlined,
    Icons.chat_bubble_outline,
    Icons.list_alt_outlined,
    Icons.bar_chart_outlined,
  ];

  final List<IconData> _navIconsFilled = [
    Icons.dashboard,
    Icons.people,
    Icons.folder,
    Icons.card_membership,
    Icons.receipt_long,
    Icons.chat_bubble,
    Icons.list_alt,
    Icons.bar_chart,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageTitle = _pageTitles[index];
      _pageSubtitle = _pageSubtitles[index];
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminData = authProvider.adminData;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            width: _isSidebarExpanded ? 256 : 76,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.sidebarGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo area ───────────────────────────────────────────
                  Container(
                    height: 72,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isSidebarExpanded ? 20 : 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: AppTheme.radiusSm,
                            boxShadow: AppTheme.primaryShadow,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (_isSidebarExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Marriage Station',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Admin Portal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.50),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 18),
                            onPressed: _toggleSidebar,
                            color: Colors.white.withOpacity(0.50),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Admin info ──────────────────────────────────────────
                  if (_isSidebarExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: AppTheme.radiusMd,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                (adminData?['name'] ?? 'A')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    adminData?['name'] ?? 'Admin',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.30),
                                      borderRadius: AppTheme.radiusSm,
                                    ),
                                    child: Text(
                                      adminData?['role']
                                              ?.toString()
                                              .replaceAll('_', ' ')
                                              .toUpperCase() ??
                                          'ADMIN',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.primaryLight,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          (adminData?['name'] ?? 'A')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Navigation section label ────────────────────────────
                  if (_isSidebarExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Text(
                        'MAIN MENU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.30),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                  // ── Nav items ───────────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isSidebarExpanded ? 10 : 10,
                        vertical: 4,
                      ),
                      itemCount: _navIcons.length,
                      itemBuilder: (context, index) {
                        return _buildNavItem(index);
                      },
                    ),
                  ),

                  // ── Logout ──────────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(_isSidebarExpanded ? 16 : 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    child: _isSidebarExpanded
                        ? InkWell(
                            onTap: () async => await authProvider.logout(),
                            borderRadius: AppTheme.radiusSm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.10),
                                borderRadius: AppTheme.radiusSm,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.logout,
                                      size: 18,
                                      color: Colors.red.shade300),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: () async => await authProvider.logout(),
                            icon: Icon(Icons.logout,
                                color: Colors.red.shade300, size: 20),
                            tooltip: 'Sign Out',
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar ───────────────────────────────────────────────
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: AppTheme.topBarBg,
                    border: const Border(
                      bottom: BorderSide(color: AppTheme.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Toggle sidebar button (when collapsed)
                      if (!_isSidebarExpanded)
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: _toggleSidebar,
                          color: AppTheme.textSecondary,
                          iconSize: 22,
                        ),
                      if (!_isSidebarExpanded) const SizedBox(width: 8),

                      // Page title
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pageTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            _pageSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Notification bell
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight,
                          borderRadius: AppTheme.radiusSm,
                        ),
                        child: Stack(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notifications_outlined,
                                size: 22,
                              ),
                              color: AppTheme.textSecondary,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Page Content ─────────────────────────────────────────
                Expanded(
                  child: Container(
                    color: AppTheme.scaffoldBg,
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: _isSidebarExpanded ? '' : _pageTitles[index],
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onItemTapped(index),
            borderRadius: AppTheme.radiusSm,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarExpanded ? 14 : 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: AppTheme.radiusSm,
                border: isSelected
                    ? Border.all(
                        color: AppTheme.primary.withOpacity(0.30), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: _isSidebarExpanded
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? _navIconsFilled[index]
                        : _navIcons[index],
                    color: isSelected
                        ? AppTheme.primaryLight
                        : Colors.white.withOpacity(0.45),
                    size: 20,
                  ),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _pageTitles[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}