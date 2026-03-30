import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/blocs/theme_cubit.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../expense/presentation/pages/expense_settings_page.dart';

class SettingsModulePage extends StatelessWidget {
  const SettingsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: <Widget>[
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Adjust app appearance and manage your saved banks.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<ThemeMode>(
                      groupValue: themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<ThemeCubit>().setThemeMode(value);
                        }
                      },
                      child: Column(
                        children: const <Widget>[
                          RadioListTile<ThemeMode>(
                            contentPadding: EdgeInsets.zero,
                            value: ThemeMode.light,
                            title: Text('Light'),
                          ),
                          RadioListTile<ThemeMode>(
                            contentPadding: EdgeInsets.zero,
                            value: ThemeMode.dark,
                            title: Text('Dark'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const ExpenseSettingsBody(),
            ],
          );
        },
      ),
    );
  }
}
