import 'package:flutter/material.dart';
import '../core/responsive.dart';

/// Navigation item description for adaptive navigation (BottomBar vs. NavigationRail).
class AdaptiveNavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const AdaptiveNavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// An adaptive scaffold that automatically displays:
/// - BottomNavigationBar on mobile viewports (< 600dp)
/// - NavigationRail on tablet viewports (600dp - 1024dp)
/// - Extended NavigationRail / Sidebar on desktop viewports (>= 1024dp)
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<AdaptiveNavigationItem> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.destinations,
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    if (isMobile) {
      return Scaffold(
        appBar: appBar,
        drawer: drawer,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onNavigationChanged,
          destinations: destinations.map((d) {
            return NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: d.activeIcon != null ? Icon(d.activeIcon) : null,
              label: d.label,
            );
          }).toList(),
        ),
      );
    }

    // Tablet & Desktop layout with NavigationRail
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Row(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: currentIndex,
                      onDestinationSelected: onNavigationChanged,
                      extended: isDesktop,
                      minExtendedWidth: 190,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Icon(
                          Icons.medication_rounded,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      labelType: isDesktop
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      destinations: destinations.map((d) {
                        return NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: d.activeIcon != null ? Icon(d.activeIcon) : null,
                          label: Text(d.label),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
