import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/metric_tile.dart';
import '../blocs/task_analytics/task_analytics_bloc.dart';

class TaskAnalyticsPage extends StatelessWidget {
  const TaskAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Analytics')),
      body: BlocBuilder<TaskAnalyticsBloc, TaskAnalyticsState>(
        builder: (context, state) {
          final analytics = state.analytics;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: <Widget>[
              if (analytics != null) ...<Widget>[
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width >= 1100
                      ? 4
                      : 2,
                  childAspectRatio: 1.35,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: <Widget>[
                    MetricTile(
                      label: 'Completed',
                      value: analytics.completedCount.toString(),
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF1F8B4C),
                    ),
                    MetricTile(
                      label: 'Pending',
                      value: analytics.pendingCount.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFC0392B),
                    ),
                    MetricTile(
                      label: 'Daily Streak',
                      value: analytics.dailyTaskStreak.toString(),
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF2E86DE),
                    ),
                    MetricTile(
                      label: 'Tracked Categories',
                      value: analytics.categoryBreakdown.length.toString(),
                      icon: Icons.category_rounded,
                      color: const Color(0xFF8E44AD),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Priority Distribution',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...analytics.priorityDistribution.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Priority ${item.priority}: ${item.count}'),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: analytics.priorityDistribution.isEmpty
                                    ? 0
                                    : item.count /
                                          analytics.priorityDistribution
                                              .fold<int>(
                                                0,
                                                (sum, entry) =>
                                                    sum + entry.count,
                                              ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Category-wise Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...analytics.categoryBreakdown.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.category),
                          trailing: Text(item.count.toString()),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
