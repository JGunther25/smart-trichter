import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/chug_record.dart';
import '../../models/liquid_option.dart';
import '../../services/service_providers.dart';
import '../../utils/date_format.dart';
import '../../utils/duration_format.dart';
import '../ble/ble_providers.dart';
import '../log_chug/log_chug_providers.dart';
import '../log_chug/log_chug_screen.dart';
import 'leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectedName = ref.watch(connectedDeviceNameProvider);
    final connectedId = ref.watch(connectedDeviceIdProvider);
    final browsingFunnel = ref.watch(browsingFunnelProvider);
    final isBrowsing = connectedId == null && browsingFunnel != null;

    ref.listen<int?>(pendingChugDurationProvider, (_, durationMs) async {
      if (durationMs == null) return;
      await showLogChugSheet(context, durationMs);
      ref.read(pendingChugDurationProvider.notifier).state = null;
    });

    // Keep BLE-to-pending bridge alive while leaderboard is shown.
    ref.watch(chugDurationListenerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          connectedName ??
              connectedId ??
              browsingFunnel?.name ??
              'Smart Funnel',
        ),
        actions: [
          if (isBrowsing)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Change funnel',
              onPressed: () => context.push('/funnels'),
            ),
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: 'Connect funnel',
            onPressed: () => context.go('/connect'),
          ),
        ],
      ),
      body: Column(
        children: [
          const _SearchField(),
          _FilterRow(),
          const Expanded(child: _LeaderboardList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Log chug manually',
        onPressed: () => showLogChugSheet(context, 0),
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search by name',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          isDense: true,
        ),
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLiquid = ref.watch(selectedLiquidProvider);
    final selectedQuantity = ref.watch(selectedQuantityProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Liquid filters
          _chip(
            label: 'All',
            selected: selectedLiquid == null,
            onTap: () => ref.read(selectedLiquidProvider.notifier).state = null,
          ),
          ...liquidOptions.map(
            (l) => _chip(
              label: l,
              selected: selectedLiquid == l,
              onTap: () => ref.read(selectedLiquidProvider.notifier).state = l,
            ),
          ),
          const SizedBox(width: 16),
          // Quantity filters
          _chip(
            label: 'All',
            selected: selectedQuantity == null,
            onTap: () =>
                ref.read(selectedQuantityProvider.notifier).state = null,
          ),
          ...quantityOptions.map(
            (q) => _chip(
              label: '$q ml',
              selected: selectedQuantity == q,
              onTap: () =>
                  ref.read(selectedQuantityProvider.notifier).state = q,
            ),
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

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(filteredLeaderboardProvider);
    final hasSearch = ref.watch(searchQueryProvider).trim().isNotEmpty;

    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error loading leaderboard',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(leaderboardProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Text(
              hasSearch
                  ? 'No chugs match your search.'
                  : 'No chugs yet. Get the funnel.',
            ),
          );
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final record = rows[i];
            final rank = i + 1;
            final rankWidget = rank <= 3
                ? Text(
                    ['🥇', '🥈', '🥉'][rank - 1],
                    style: const TextStyle(fontSize: 20),
                  )
                : SizedBox(
                    width: 36,
                    child: Text(
                      '$rank',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );

            return ListTile(
              leading: rankWidget,
              title: Text(record.name),
              subtitle: Text(
                '${record.liquid} · ${record.quantityMl} ml · '
                '${formatChugTimestamp(record.loggedAt)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatChugDuration(record.durationMs),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  PopupMenuButton<_RowAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _RowAction.edit:
                          showLogChugSheet(
                            context,
                            record.durationMs,
                            existing: record,
                          );
                        case _RowAction.delete:
                          _confirmDelete(context, ref, record);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _RowAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: _RowAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

enum _RowAction { edit, delete }

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  ChugRecord record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete entry?'),
      content: Text(
        "Remove ${record.name}'s ${formatChugDuration(record.durationMs)} "
        '${record.liquid} chug? This can\'t be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || record.id == null) return;

  final service = ref.read(firestoreServiceProvider);
  try {
    await service.deleteChug(record.id!);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }
}
