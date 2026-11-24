import 'package:flutter/material.dart';

import '../data/neo_cache.dart';
import '../data/neo_repository.dart';
import '../data/settings.dart';
import 'screens/period_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';

/// Нижняя навигация: Поиск · Неделя · Месяц · Настройки.
/// IndexedStack держит все экраны живыми — данные не перезагружаются при переключении.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.repo, required this.settings, required this.cache});

  final NeoRepository repo;
  final Settings settings;
  final NeoCache cache;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          SearchScreen(repo: widget.repo),
          PeriodScreen(repo: widget.repo, days: 7, title: 'Сравнение за неделю'),
          PeriodScreen(repo: widget.repo, days: 30, title: 'Сравнение за месяц'),
          SettingsScreen(settings: widget.settings, cache: widget.cache),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Поиск'),
          NavigationDestination(icon: Icon(Icons.date_range), label: 'Неделя'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Месяц'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
