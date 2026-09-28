import 'package:flutter/material.dart';

import 'favorites_page.dart';
import 'home_page.dart';
import 'placeholder_page.dart';

/// Hosts the bottom navigation. IndexedStack keeps each tab's scroll
/// position and state alive when switching.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_border_rounded),
      selectedIcon: Icon(Icons.favorite_rounded),
      label: 'Favorites',
    ),
    NavigationDestination(
      icon: Icon(Icons.edit_note_outlined),
      selectedIcon: Icon(Icons.edit_note_rounded),
      label: 'Notes',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  static const _pages = <Widget>[
    HomePage(),
    FavoritesPage(),
    PlaceholderPage(
      icon: Icons.edit_note_rounded,
      title: 'Notes',
      message: 'Your highlights and notes will live here.',
    ),
    PlaceholderPage(
      icon: Icons.person_rounded,
      title: 'Profile',
      message: 'Your profile and reading stats are coming soon.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
