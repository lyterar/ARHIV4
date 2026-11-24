import 'package:flutter/material.dart';

import '../../logic/date_utils.dart';
import '../theme.dart';

/// Плашка актуальности данных.
/// Свежие данные — спокойная строка «Обновлено …».
/// Данные из кэша — жёлтая плашка с датой и причиной (например, нет сети).
class FreshBanner extends StatelessWidget {
  const FreshBanner({super.key, required this.at, required this.fromCache, this.reason});

  final DateTime at;
  final bool fromCache;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    if (!fromCache) {
      return Text(
        'Обновлено ${ruStamp(at)} · NASA NeoWs',
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.warn.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.warn, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сохранённые данные, актуальны на ${ruStamp(at)}',
                  style: const TextStyle(color: AppColors.warn, fontWeight: FontWeight.w600),
                ),
                if (reason != null)
                  Text(reason!, style: const TextStyle(color: AppColors.text, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
