import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chug_record.dart';
import '../../models/liquid_option.dart';
import '../../services/service_providers.dart';
import '../../utils/duration_format.dart';
import '../ble/ble_providers.dart';

class LogChugSheet extends ConsumerStatefulWidget {
  final int durationMs;

  const LogChugSheet({required this.durationMs, super.key});

  @override
  ConsumerState<LogChugSheet> createState() => _LogChugSheetState();
}

class _LogChugSheetState extends ConsumerState<LogChugSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _liquid = liquidOptions.first;
  int _quantityMl = 330;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final funnelId = ref.read(connectedDeviceIdProvider) ?? 'unknown';
    final record = ChugRecord(
      funnelId: funnelId,
      name: _nameController.text.trim(),
      liquid: _liquid,
      quantityMl: _quantityMl,
      durationMs: widget.durationMs,
      loggedAt: DateTime.now(), // overwritten by serverTimestamp in toFirestore
    );

    try {
      await ref.read(firestoreServiceProvider).saveChug(record);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.durationMs == 0
                    ? 'Manual entry'
                    : 'Chug recorded: ${formatChugDuration(widget.durationMs)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            Text('Liquid', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: liquidOptions.map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: _liquid == option,
                  onSelected: (_) => setState(() => _liquid = option),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Quantity', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: quantityOptions.map((ml) {
                return ChoiceChip(
                  label: Text('$ml ml'),
                  selected: _quantityMl == ml,
                  onSelected: (_) => setState(() => _quantityMl = ml),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the log-chug bottom sheet. Call from the leaderboard screen when
/// pendingChugDurationProvider becomes non-null.
Future<void> showLogChugSheet(BuildContext context, int durationMs) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => LogChugSheet(durationMs: durationMs),
  );
}
