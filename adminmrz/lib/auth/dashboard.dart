import 'package:adminmrz/auth/service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../adminchat/left.dart';
import '../adminchat/loading.dart';
import '../dashboard/dashboardhome.dart';
import '../dashboard/dashmodel.dart';
import '../dashboard/dashservice.dart';
import '../document/screens/docscreen.dart';
import '../package/packageScreen.dart';
import '../payment/paymentscreen.dart';
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

  final List<Widget> _pages = [
    const DashboardHome(),
    const UsersPage(),
    const DocumentsPage(),
    const PackagesPage(),
    const PaymentsPage(),
     Loading(),
  ];

  final List<String> _pageTitles = [
    'Dashboard',
    'Users',
    'Documents',
    'Packages',
    'Payments',
    'Chat'
  ];

  final List<IconData> _navIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.analytics,
    Icons.settings,
    Icons.money,
    Icons.chat,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageTitle = _pageTitles[index];
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
      body: Row(
        children: [
          // Sidebar Navigation - Minimizable
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarExpanded ? 260 : 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFe9ecef))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo/Header with toggle button
                Container(
                  padding: EdgeInsets.all(_isSidebarExpanded ? 20 : 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFe9ecef))),
                  ),
                  child: Row(
                    children: [
                      if (!_isSidebarExpanded)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: _toggleSidebar,
                          color: const Color(0xFF667eea),
                        )
                      else
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: Color(0xFF667eea),
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _toggleSidebar,
                                color: Colors.grey[600],
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                if (_isSidebarExpanded) ...[
                  const SizedBox(height: 20),
                  // Admin Info - Only show when expanded
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminData?['name'] ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminData?['email'] ?? 'admin@email.com',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            adminData?['role']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ADMIN',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: const Color(0xFF667eea),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ] else
                  const SizedBox(height: 20),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: _isSidebarExpanded ? 0 : 8),
                    itemCount: _navIcons.length,
                    itemBuilder: (context, index) {
                      return _buildNavItem(
                        _navIcons[index],
                        _pageTitles[index],
                        index,
                      );
                    },
                  ),
                ),

                // Logout Button
                Container(
                  padding: EdgeInsets.all(_isSidebarExpanded ? 20 : 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFe9ecef))),
                  ),
                  child: _isSidebarExpanded
                      ? ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Logout'),
                  )
                      : IconButton(
                    onPressed: () async {
                      await authProvider.logout();
                    },
                    icon: const Icon(Icons.logout),
                    color: Colors.red,
                    tooltip: 'Logout',
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area - Takes remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFe9ecef))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Show menu button when sidebar is collapsed
                      if (!_isSidebarExpanded)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: _toggleSidebar,
                          color: Colors.grey[600],
                        ),
                      Text(
                        _pageTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    color: const Color(0xFFf8f9fa),
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

  Widget _buildNavItem(IconData icon, String title, int index) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isSidebarExpanded ? 12 : 8,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarExpanded ? 16 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _selectedIndex == index
                  ? const Color(0xFFf0f4ff)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: _selectedIndex == index
                      ? const Color(0xFF667eea)
                      : Colors.grey[600],
                  size: 22,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: _selectedIndex == index
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedIndex == index
                            ? const Color(0xFF667eea)
                            : Colors.grey[700],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}