import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';

class SettingsModulePage extends StatelessWidget {
  const SettingsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: <Widget>[
          _buildNavigationTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'User Settings',
            routeName: AppRoutes.userSettingsInfo,
          ),
          const SizedBox(height: 16),
          _buildNavigationTile(
            context,
            icon: Icons.tune_rounded,
            title: 'App Settings',
            routeName: AppRoutes.appSettingsInfo,
          ),
          const SizedBox(height: 16),
          _buildNavigationTile(
            context,
            icon: Icons.backup_outlined,
            title: 'Backup Settings',
            routeName: AppRoutes.backupSettingsInfo,
          ),
          const SizedBox(height: 16),
          _buildNavigationTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            routeName: AppRoutes.privacyPolicy,
          ),
          const SizedBox(height: 16),
          _buildNavigationTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            routeName: AppRoutes.termsAndConditions,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    return AppPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 50,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pushNamed(routeName),
      ),
    );
  }
}
