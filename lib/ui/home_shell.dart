import 'package:flutter/material.dart';

import '../data/neo_cache.dart';
import '../data/neo_repository.dart';
import '../data/settings.dart';
import 'screens/period_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';

/// Нижняя навигация: Поиск · Неделя · Месяц · Настройки.
/// IndexedStack держит открытые экраны живыми — данные не перезагружаются при переключении.
/// Экран создаётся только при первом открытии вкладки, чтобы не тратить лимит API на старте.
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
  final _opened = <int>{0};

  Widget _lazy(int i, Widget Function() make) => _opened.contains(i) ? make() : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          SearchScreen(repo: widget.repo),
          _lazy(1, () => PeriodScreen(repo: widget.repo, days: 7, title: 'Сравнение за неделю')),
          _lazy(2, () => PeriodScreen(repo: widget.repo, days: 30, title: 'Сравнение за месяц')),
          _lazy(3, () => SettingsScreen(settings: widget.settings, cache: widget.cache)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _opened.add(i);
        }),
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
