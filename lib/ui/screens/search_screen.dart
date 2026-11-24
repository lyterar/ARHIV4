import 'package:flutter/material.dart';

import '../../data/neo_error.dart';
import '../../data/neo_repository.dart';
import '../../logic/date_utils.dart';
import '../../logic/validators.dart';
import '../../models/asteroid.dart';
import '../../models/day_stat.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/fresh_banner.dart';
import '../widgets/stat_tile.dart';

/// Базовая функциональность (как в Лаб 3): сближения астероидов за выбранную дату.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.repo});

  final NeoRepository repo;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _ctrl = TextEditingController(text: isoDay(widget.repo.today));
  String? _inputErr;
  bool _loading = false;
  DayResult? _res;
  String? _err;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final err = validateDate(_ctrl.text);
    setState(() => _inputErr = err);
    if (err != null || _loading) return; // невалидный ввод — в сеть не идём

    final day = parseIsoDay(_ctrl.text)!;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await widget.repo.loadDay(day);
      if (!mounted) return;
      setState(() => _res = r);
    } on NeoError catch (e) {
      if (!mounted) return;
      setState(() {
        _res = null;
        _err = e.message;
      });
    } catch (_) {
      // Страховка: любая непредвиденная ошибка — сообщение, а не красный экран.
      if (!mounted) return;
      setState(() {
        _res = null;
        _err = 'Непредвиденная ошибка при загрузке данных';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final cur = parseIsoDay(_ctrl.text) ?? widget.repo.today;
    final d = await showDatePicker(
      context: context,
      initialDate: cur.isBefore(minDate) || cur.isAfter(maxDate) ? widget.repo.today : cur,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (d == null) return;
    _ctrl.text = isoDay(d);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NEO Tracker')),
      body: RefreshIndicator(
        onRefresh: _search,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Сближения астероидов с Землёй',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Дата',
                      hintText: 'ГГГГ-ММ-ДД',
                      errorText: _inputErr,
                      suffixIcon: IconButton(
                        tooltip: 'Календарь',
                        icon: const Icon(Icons.calendar_month),
                        onPressed: _pickDate,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton(
                    onPressed: () {
                      _ctrl.text = isoDay(widget.repo.today);
                      _search();
                    },
                    child: const Text('Сегодня'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Найти астероиды'),
            ),
            const SizedBox(height: 16),
            ..._body(),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (_err != null) return [ErrorView(message: _err!, onRetry: _search)];
    final r = _res;
    if (r == null) return const [];

    final s = DayStat.of(r.day, r.items);
    return [
      FreshBanner(at: r.fetchedAt, fromCache: r.fromCache, reason: r.warning),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: StatTile(label: 'Сближений', value: '${s.count}')),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              label: 'Опасных',
              value: '${s.hazardous}',
              color: s.hazardous > 0 ? AppColors.down : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              label: 'Ближе всех',
              value: s.minDistKm == null ? '—' : fmtNum(s.minDistKm! / 1e6, digits: 2),
              hint: 'млн км',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (r.items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'За эту дату NASA не сообщает о сближениях',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      for (final a in r.items) ...[_AsteroidCard(a), const SizedBox(height: 8)],
    ];
  }
}

class _AsteroidCard extends StatelessWidget {
  const _AsteroidCard(this.a);

  final Asteroid a;

  @override
  Widget build(BuildContext context) {
    final haz = a.hazardous;
    final (hazText, hazColor) = switch (haz) {
      true => ('Опасен', AppColors.down),
      false => ('Не опасен', AppColors.up),
      null => ('Неизвестно', AppColors.muted),
    };
    final diam = a.diamMinM == null || a.diamMaxM == null
        ? 'нет данных'
        : '${fmtNum(a.diamMinM)}–${fmtNum(a.diamMaxM)} м';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.name,
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hazColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(hazText, style: TextStyle(color: hazColor, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _row('Диаметр', diam),
            _row('Скорость', a.speedKms == null ? 'нет данных' : '${fmtNum(a.speedKms, digits: 2)} км/с'),
            _row('Расстояние', a.distKm == null ? 'нет данных' : '${fmtNum(a.distKm)} км'),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(k, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
            Expanded(child: Text(v, style: const TextStyle(color: AppColors.text, fontSize: 13))),
          ],
        ),
      );
}
