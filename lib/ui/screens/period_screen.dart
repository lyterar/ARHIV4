import 'package:flutter/material.dart';

import '../../data/neo_error.dart';
import '../../data/neo_repository.dart';
import '../../logic/date_utils.dart';
import '../../logic/period_stats.dart';
import '../../models/metric.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/fresh_banner.dart';
import '../widgets/line_chart.dart';
import '../widgets/stat_tile.dart';

/// Экран сравнения за период: [days] = 7 («Неделя») или 30 («Месяц»).
/// График, минимум, максимум, среднее, изменение (абс. и %), тенденция.
class PeriodScreen extends StatefulWidget {
  const PeriodScreen({super.key, required this.repo, required this.days, required this.title});

  final NeoRepository repo;
  final int days;
  final String title;

  @override
  State<PeriodScreen> createState() => _PeriodScreenState();
}

class _PeriodScreenState extends State<PeriodScreen> {
  Metric _metric = Metric.count;
  bool _loading = false;
  PeriodResult? _res;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await widget.repo.loadPeriod(widget.days);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<Metric>(
              segments: [
                for (final m in Metric.values) ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {_metric},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _metric = s.first),
            ),
            const SizedBox(height: 16),
            if (_loading && _res == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_loading && _res != null) const LinearProgressIndicator(),
            ..._body(),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (_err != null) return [ErrorView(message: _err!, onRetry: _load)];
    final r = _res;
    if (r == null) return const [];

    final points = <Point>[];
    for (final s in r.stats) {
      final v = _metric.valueOf(s);
      if (v != null) points.add(Point(s.day, v));
    }
    final st = computeStats(points);
    final digits = _metric == Metric.minDist ? 2 : 0;
    final avgDigits = _metric == Metric.minDist ? 2 : 1;
    final unit = _metric.unit;

    return [
      Text(
        '${ruDay(r.start)} — ${ruDay(r.end)} · ${_metric.label}, $unit',
        style: const TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 8),
      if (r.oldestFetch != null)
        FreshBanner(at: r.oldestFetch!, fromCache: r.fromCache, reason: r.warning),
      if (r.missing.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          'Нет данных за ${r.missing.length} дн. из ${widget.days} '
          '(${r.missing.take(3).map(ruShort).join(', ')}${r.missing.length > 3 ? '…' : ''}). '
          'Статистика посчитана по ${r.stats.length} дн.',
          style: const TextStyle(color: AppColors.warn, fontSize: 12),
        ),
      ],
      const SizedBox(height: 12),
      if (st == null)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Нет данных для расчёта за этот период',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        )
      else ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: LineChart(points: points, digits: digits),
          ),
        ),
        const SizedBox(height: 12),
        _TrendCard(stats: st, unit: unit, digits: digits),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.7,
          children: [
            StatTile(label: 'Минимум', value: '${fmtNum(st.min, digits: digits)} $unit', hint: ruDay(st.minDay)),
            StatTile(label: 'Максимум', value: '${fmtNum(st.max, digits: digits)} $unit', hint: ruDay(st.maxDay)),
            StatTile(label: 'Среднее', value: '${fmtNum(st.avg, digits: avgDigits)} $unit', hint: 'за ${st.count} дн.'),
            StatTile(
              label: 'Начало → конец',
              value: '${fmtNum(st.first, digits: digits)} → ${fmtNum(st.last, digits: digits)}',
              hint: unit,
            ),
          ],
        ),
      ],
    ];
  }
}

/// Изменение за период и явная тенденция: рост / падение / без изменений.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.stats, required this.unit, required this.digits});

  final PeriodStats stats;
  final String unit;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (stats.trend) {
      Trend.up => (Icons.trending_up, AppColors.up),
      Trend.down => (Icons.trending_down, AppColors.down),
      Trend.flat => (Icons.trending_flat, AppColors.muted),
    };
    final pct = stats.pctChange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Тенденция: ${stats.trend.label}',
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Изменение: ${fmtSigned(stats.absChange, digits: digits)} $unit'
                    ' · ${pct == null ? 'н/д %' : '${fmtSigned(pct, digits: 1)} %'}',
                    style: const TextStyle(color: AppColors.text),
                  ),
                  if (pct == null)
                    const Text(
                      'Процент не считается: в первый день значение было 0',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
