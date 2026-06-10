import 'package:flutter/material.dart';
import 'package:smart_108_responders/pages/profile.dart';
import 'package:smart_108_responders/pages/request_history.dart';
import 'package:smart_108_responders/pages/settings.dart';

class SettingsRouter extends StatelessWidget {
  const SettingsRouter({super.key});

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
            page = RequestHistoryScreen();
            break;

          default:
            page = const SettingsHomePage();
        }

        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }
}
