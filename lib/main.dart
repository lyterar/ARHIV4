import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/kv_store.dart';
import 'data/neo_api.dart';
import 'data/neo_cache.dart';
import 'data/neo_repository.dart';
import 'data/settings.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

/// Точка входа: собираем зависимости вручную (без DI-фреймворков) и запускаем UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = PrefsStore(prefs);

  final settings = Settings(store);
  final cache = NeoCache(store);
  final repo = NeoRepository(api: NeoApi(), cache: cache, apiKey: () => settings.apiKey);

  runApp(NeoApp(repo: repo, settings: settings, cache: cache));
}

class NeoApp extends StatelessWidget {
  const NeoApp({super.key, required this.repo, required this.settings, required this.cache});

  final NeoRepository repo;
  final Settings settings;
  final NeoCache cache;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEO Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeShell(repo: repo, settings: settings, cache: cache),
    );
  }
}
