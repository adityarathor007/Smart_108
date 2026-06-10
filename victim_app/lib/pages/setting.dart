import 'package:flutter/material.dart';
import 'package:smart_108/pages/profile.dart';
import 'package:smart_108/pages/requestHistory.dart';
import 'package:smart_108/pages/settings_home.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        Widget page;

        switch (settings.name) {
          case '/profile':
            page = const ProfileScreen();
            break;

          case '/e_requests':
            page=RequestHistoryPage();
            break;

          default:
            page = const SettingsHomePage();
        }

        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }
}
