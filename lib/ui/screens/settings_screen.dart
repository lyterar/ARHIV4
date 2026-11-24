import 'package:flutter/material.dart';

import '../../data/neo_cache.dart';
import '../../data/settings.dart';
import '../../logic/validators.dart';
import '../theme.dart';

/// Ключ NASA API и сведения о кэше.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings, required this.cache});

  final Settings settings;
  final NeoCache cache;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _ctrl = TextEditingController(text: widget.settings.rawKey);
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final err = validateApiKey(_ctrl.text);
    setState(() => _err = err);
    if (err != null) return;
    await widget.settings.setApiKey(_ctrl.text);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.settings.usesDemo ? 'Используется DEMO_KEY' : 'Ключ сохранён')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ctrl,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Ключ NASA API',
              hintText: 'пусто — DEMO_KEY',
              errorText: _err,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
          const SizedBox(height: 16),
          Text(
            widget.settings.usesDemo
                ? 'Сейчас используется DEMO_KEY: около 30 запросов в час. '
                    'Экран «Месяц» тратит 5 запросов, «Неделя» — 1. '
                    'Свой ключ бесплатно выдаётся на api.nasa.gov.'
                : 'Используется ваш ключ (до 1000 запросов в час).',
            style: const TextStyle(color: AppColors.muted),
          ),
          const Divider(height: 32),
          Text(
            'В кэше: ${widget.cache.size} дн.',
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await widget.cache.clear();
              if (mounted) setState(() {});
            },
            child: const Text('Очистить кэш'),
          ),
        ],
      ),
    );
  }
}
