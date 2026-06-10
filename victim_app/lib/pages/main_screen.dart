import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_108/pages/LocationPicker.dart';
import 'package:smart_108/pages/profile_extra.dart';
import 'package:smart_108/pages/home.dart';
import 'package:smart_108/pages/profile.dart';
import 'package:smart_108/pages/setting.dart';
import 'package:smart_108/pages/settings_home.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex=0;

  final List<Widget> _pages = [
    const HomeScreen(),
    // const ProfileScreen(),
    const SettingsPage(),
    // const LocationPickerPage(),
    // const DemoPage(),
    // const ChatPage(),
  ];

  void goToHomeTab() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: _pages[_currentIndex],
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF009688).withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF009688)),
              label: 'Home'),

            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF009688)),
              label: 'Settings'),
          ],
        )
        ),
    );
  }
}
