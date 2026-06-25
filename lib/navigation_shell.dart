import 'package:flutter/material.dart';
import 'theme/meditrack_theme.dart';
import 'screens/home_dashboard.dart';
import 'screens/vitals_history.dart';
import 'screens/medicines_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/profile_screen.dart';

class NavigationShell extends StatefulWidget {
  final int initialTab;
  const NavigationShell({super.key, this.initialTab = 0});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant NavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _currentIndex = widget.initialTab;
    }
  }

  final List<Widget> _screens = [
    const HomeDashboard(),
    const VitalsHistory(),
    const MedicinesScreen(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: context.colors.card,
              selectedIconTheme: IconThemeData(color: context.colors.primary),
              unselectedIconTheme: IconThemeData(color: context.colors.textSecondary),
              selectedLabelTextStyle: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: TextStyle(color: context.colors.textSecondary),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: Text('Vitals'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.medication_outlined),
                  selectedIcon: Icon(Icons.medication),
                  label: Text('Medicines'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: context.colors.primary,
        unselectedItemColor: context.colors.textSecondary,
        backgroundColor: context.colors.card,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 1 ? Icons.favorite : Icons.favorite_border),
            label: 'Vitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 2 ? Icons.medication : Icons.medication_outlined),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 3 ? Icons.bar_chart : Icons.bar_chart_outlined),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 4 ? Icons.person : Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
