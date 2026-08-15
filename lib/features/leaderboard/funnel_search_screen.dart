import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/known_funnel.dart';
import 'leaderboard_providers.dart';

/// Lets the owner find a previously-connected funnel by name and view its
/// leaderboard without an active BLE connection.
class FunnelSearchScreen extends ConsumerStatefulWidget {
  const FunnelSearchScreen({super.key});

  @override
  ConsumerState<FunnelSearchScreen> createState() => _FunnelSearchScreenState();
}

class _FunnelSearchScreenState extends ConsumerState<FunnelSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(KnownFunnel funnel) {
    ref.read(browsingFunnelProvider.notifier).state = funnel;
    context.go('/leaderboard');
  }

  @override
  Widget build(BuildContext context) {
    final funnels = ref.watch(knownFunnelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Funnels')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search funnel name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: funnels.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading funnels: $e')),
                data: (all) {
                  final results = _query.isEmpty
                      ? all
                      : all
                          .where((f) => f.name.toLowerCase().contains(_query))
                          .toList();
                  if (results.isEmpty) {
                    return Center(
                      child: Text(
                        all.isEmpty
                            ? 'No funnels connected yet.'
                            : 'No funnel matches "$_query".',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final funnel = results[i];
                      return ListTile(
                        leading: const Icon(Icons.local_bar),
                        title: Text(funnel.name),
                        onTap: () => _select(funnel),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
