import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/blocs/theme_cubit.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../expense/presentation/pages/expense_settings_page.dart';
import '../../../tasks/presentation/widgets/task_settings_body.dart';

class SettingsModulePage extends StatelessWidget {
  const SettingsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final theme = Theme.of(context);
          final isDarkMode = themeMode == ThemeMode.dark;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: <Widget>[
              Text(
                'Settings',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      theme.colorScheme.primary.withValues(alpha: 0.55),
                      theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: AppPanel(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Global Settings',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dark Mode',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isDarkMode
                                  ? 'Dark theme is active'
                                  : 'Light theme is active',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isDarkMode,
                        onChanged: (value) {
                          context.read<ThemeCubit>().setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const ExpenseSettingsBody(),
              const SizedBox(height: 18),
              const TaskSettingsBody(),
            ],
          );
        },
      ),
    );
  }
}
