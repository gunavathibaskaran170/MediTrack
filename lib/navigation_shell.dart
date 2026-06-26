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
              destinations: [
                NavigationRailDestination(
                  icon: _AnimatedTabIcon(
                    icon: Icons.home_outlined,
                    isSelected: _currentIndex == 0,
                    activeColor: context.colors.primary,
                    inactiveColor: context.colors.textSecondary,
                  ),
                  label: const Text('Home'),
                ),
                NavigationRailDestination(
                  icon: _AnimatedTabIcon(
                    icon: Icons.favorite_border,
                    isSelected: _currentIndex == 1,
                    activeColor: context.colors.primary,
                    inactiveColor: context.colors.textSecondary,
                  ),
                  label: const Text('Vitals'),
                ),
                NavigationRailDestination(
                  icon: _AnimatedTabIcon(
                    icon: Icons.medication_outlined,
                    isSelected: _currentIndex == 2,
                    activeColor: context.colors.primary,
                    inactiveColor: context.colors.textSecondary,
                  ),
                  label: const Text('Medicines'),
                ),
                NavigationRailDestination(
                  icon: _AnimatedTabIcon(
                    icon: Icons.bar_chart_outlined,
                    isSelected: _currentIndex == 3,
                    activeColor: context.colors.primary,
                    inactiveColor: context.colors.textSecondary,
                  ),
                  label: const Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: _AnimatedTabIcon(
                    icon: Icons.person_outline,
                    isSelected: _currentIndex == 4,
                    activeColor: context.colors.primary,
                    inactiveColor: context.colors.textSecondary,
                  ),
                  label: const Text('Profile'),
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
            icon: _AnimatedTabIcon(
              icon: Icons.home_outlined,
              isSelected: _currentIndex == 0,
              activeColor: context.colors.primary,
              inactiveColor: context.colors.textSecondary,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedTabIcon(
              icon: Icons.favorite_border,
              isSelected: _currentIndex == 1,
              activeColor: context.colors.primary,
              inactiveColor: context.colors.textSecondary,
            ),
            label: 'Vitals',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedTabIcon(
              icon: Icons.medication_outlined,
              isSelected: _currentIndex == 2,
              activeColor: context.colors.primary,
              inactiveColor: context.colors.textSecondary,
            ),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedTabIcon(
              icon: Icons.bar_chart_outlined,
              isSelected: _currentIndex == 3,
              activeColor: context.colors.primary,
              inactiveColor: context.colors.textSecondary,
            ),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedTabIcon(
              icon: Icons.person_outline,
              isSelected: _currentIndex == 4,
              activeColor: context.colors.primary,
              inactiveColor: context.colors.textSecondary,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _AnimatedTabIcon extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const _AnimatedTabIcon({
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<_AnimatedTabIcon> createState() => _AnimatedTabIconState();
}

class _AnimatedTabIconState extends State<_AnimatedTabIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.icon,
        color: widget.isSelected ? widget.activeColor : widget.inactiveColor,
      ),
    );
  }
}
