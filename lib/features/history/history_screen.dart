import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/liquid_option.dart';
import '../../utils/date_format.dart';
import '../../utils/duration_format.dart';
import 'history_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Column(
        children: [
          _FilterRow(),
          Expanded(child: _HistoryList()),
        ],
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLiquid = ref.watch(historyLiquidFilterProvider);
    final selectedDate = ref.watch(historyDateFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip(
            label: 'All',
            selected: selectedLiquid == null,
            onTap: () =>
                ref.read(historyLiquidFilterProvider.notifier).state = null,
          ),
          ...liquidOptions.map(
            (l) => _chip(
              label: l,
              selected: selectedLiquid == l,
              onTap: () =>
                  ref.read(historyLiquidFilterProvider.notifier).state = l,
            ),
          ),
          const SizedBox(width: 16),
          ActionChip(
            avatar: Icon(
              Icons.calendar_today,
              size: 16,
              color: selectedDate != null
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : null,
            ),
            label: Text(
              selectedDate == null
                  ? 'Any date'
                  : formatChugTimestamp(selectedDate).split(',').first,
            ),
            backgroundColor: selectedDate != null
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? now,
                firstDate: DateTime(now.year - 5),
                lastDate: now,
              );
              if (picked != null) {
                ref.read(historyDateFilterProvider.notifier).state = picked;
              }
            },
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Clear date filter',
              onPressed: () =>
                  ref.read(historyDateFilterProvider.notifier).state = null,
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(historyProvider);

    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error loading history',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(historyProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(child: Text('No chugs logged yet.'));
        }

        final bestByName = <String, int>{};
        for (final r in rows) {
          final best = bestByName[r.name];
          if (best == null || r.durationMs < best) {
            bestByName[r.name] = r.durationMs;
          }
        }

        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final record = rows[i];
            final isPersonalBest = record.durationMs == bestByName[record.name];

            return ListTile(
              leading: isPersonalBest
                  ? const Text('⭐', style: TextStyle(fontSize: 20))
                  : const SizedBox(width: 20),
              title: Text(record.name),
              subtitle: Text(
                '${formatChugTimestamp(record.loggedAt)} · ${record.liquid} · ${record.quantityMl} ml',
              ),
              trailing: Text(
                formatChugDuration(record.durationMs),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight:
                      isPersonalBest ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
