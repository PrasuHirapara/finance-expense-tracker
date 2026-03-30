import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/add_entry_screen.dart';
import '../../presentation/screens/analytics_screen.dart';
import '../../presentation/screens/categories_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: DashboardScreen.routePath,
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: DashboardScreen.routePath,
            name: DashboardScreen.routeName,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AnalyticsScreen.routePath,
            name: AnalyticsScreen.routeName,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: CategoriesScreen.routePath,
            name: CategoriesScreen.routeName,
            builder: (context, state) => const CategoriesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AddEntryScreen.routePath,
        name: AddEntryScreen.routeName,
        builder: (context, state) => const AddEntryScreen(),
      ),
    ],
  );
});
