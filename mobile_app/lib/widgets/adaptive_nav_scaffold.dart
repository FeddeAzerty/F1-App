import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/news_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/standings_screen.dart';
import '../screens/tickets_screen.dart';

class _NavDestinationInfo {
  const _NavDestinationInfo({
    required this.label,
    required this.icon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final Widget screen;
}

final _destinations = [
  _NavDestinationInfo(
    label: 'Home',
    icon: Icons.home_outlined,
    screen: const HomeScreen(),
  ),
  _NavDestinationInfo(
    label: 'Schedule',
    icon: Icons.calendar_month_outlined,
    screen: const ScheduleScreen(),
  ),
  _NavDestinationInfo(
    label: 'Standings',
    icon: Icons.leaderboard_outlined,
    screen: const StandingsScreen(),
  ),
  _NavDestinationInfo(
    label: 'News',
    icon: Icons.newspaper_outlined,
    screen: const NewsScreen(),
  ),
  _NavDestinationInfo(
    label: 'Tickets',
    icon: Icons.confirmation_number_outlined,
    screen: const TicketsScreen(),
  ),
];

/// Wraps the five top-level screens in navigation that adapts to window
/// size: a bottom [NavigationBar] on narrow (mobile) widths, and a side
/// [NavigationRail] on wide (desktop) widths.
class AdaptiveNavScaffold extends StatefulWidget {
  const AdaptiveNavScaffold({super.key});

  static const wideBreakpoint = 700.0;

  @override
  State<AdaptiveNavScaffold> createState() => _AdaptiveNavScaffoldState();
}

class _AdaptiveNavScaffoldState extends State<AdaptiveNavScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AdaptiveNavScaffold.wideBreakpoint;

    final body = IndexedStack(
      index: _selectedIndex,
      children: [for (final d in _destinations) d.screen],
    );

    if (!isWide) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
