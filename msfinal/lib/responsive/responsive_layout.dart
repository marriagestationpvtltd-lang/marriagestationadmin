import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

/// Responsive layout builder widget
/// Builds different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  /// Layout for mobile screens
  final Widget mobile;

  /// Optional layout for tablet screens (defaults to mobile if not provided)
  final Widget? tablet;

  /// Layout for desktop screens
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Adaptive scaffold that switches between mobile and desktop navigation
class AdaptiveScaffold extends StatelessWidget {
  /// The main content widget
  final Widget body;

  /// Current selected navigation index
  final int selectedIndex;

  /// Callback when navigation item is tapped
  final void Function(int) onNavigationChanged;

  /// Navigation items for bottom/side navigation
  final List<NavigationItem> navigationItems;

  /// Optional app bar title
  final String? title;

  /// Optional floating action button
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onNavigationChanged,
    required this.navigationItems,
    this.title,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= Breakpoints.tablet;

        if (isDesktop) {
          // Desktop layout with side navigation
          return Row(
            children: [
              // Side navigation
              _buildSideNavigation(context),
              // Main content
              Expanded(child: body),
            ],
          );
        } else {
          // Mobile layout with bottom navigation
          return Scaffold(
            appBar: title != null
                ? AppBar(
                    title: Text(title!),
                    centerTitle: true,
                  )
                : null,
            body: body,
            bottomNavigationBar: _buildBottomNavigation(context),
            floatingActionButton: floatingActionButton,
          );
        }
      },
    );
  }

  Widget _buildSideNavigation(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: navigationItems.length,
        itemBuilder: (context, index) {
          final item = navigationItems[index];
          final isSelected = selectedIndex == index;

          return ListTile(
            leading: Icon(
              item.icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onTap: () => onNavigationChanged(index),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onNavigationChanged,
      type: BottomNavigationBarType.fixed,
      items: navigationItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ))
          .toList(),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}
