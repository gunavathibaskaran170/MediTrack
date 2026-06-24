import 'package:flutter/material.dart';
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
