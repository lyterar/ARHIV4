import 'package:flutter/material.dart';

import '../theme.dart';

/// Небольшая карточка «подпись — значение».
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.hint, this.color});

  final String label;
  final String value;
  final String? hint;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color ?? AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(hint!, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
