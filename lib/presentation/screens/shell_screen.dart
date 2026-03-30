import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'add_entry_screen.dart';
import 'analytics_screen.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndex(location);

    void navigate(int index) {
      switch (index) {
        case 0:
          context.go(DashboardScreen.routePath);
        case 1:
          context.go(AnalyticsScreen.routePath);
        case 2:
          context.go(CategoriesScreen.routePath);
      }
    }

    if (width >= 900) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: navigate,
                  extended: width >= 1180,
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.space_dashboard_outlined),
                      selectedIcon: Icon(Icons.space_dashboard_rounded),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: Text('Analytics'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.category_outlined),
                      selectedIcon: Icon(Icons.category_rounded),
                      label: Text('Categories'),
                    ),
                  ],
                  trailing: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: FilledButton.icon(
                      onPressed: () => context.push(AddEntryScreen.routePath),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Entry'),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: SafeArea(child: child)),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: child),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AddEntryScreen.routePath),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Categories',
          ),
        ],
        onDestinationSelected: navigate,
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith(AnalyticsScreen.routePath)) {
      return 1;
    }
    if (location.startsWith(CategoriesScreen.routePath)) {
      return 2;
    }
    return 0;
  }
}
