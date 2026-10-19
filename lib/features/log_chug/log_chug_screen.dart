import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chug_record.dart';
import '../../models/liquid_option.dart';
import '../../services/service_providers.dart' show firestoreServiceProvider;
import '../../utils/duration_format.dart';
import '../ble/ble_providers.dart';

/// Renders a millisecond duration as the seconds text shown in the editable
/// "Duration (s)" field, e.g. 3235 -> "3.235".
String _msToSecondsText(int ms) => (ms / 1000).toStringAsFixed(3);

/// Parses the "Duration (s)" field's text back to whole milliseconds, e.g.
/// "3.235" -> 3235. Returns null if [text] isn't a valid non-negative number.
int? _secondsTextToMs(String text) {
  final seconds = double.tryParse(text.trim());
  if (seconds == null || seconds < 0) return null;
  return (seconds * 1000).round();
}

class LogChugSheet extends ConsumerStatefulWidget {
  final int durationMs;
  final ChugRecord? existing;

  const LogChugSheet({required this.durationMs, this.existing, super.key});

  bool get isEditing => existing != null;

  bool get isManualEntry => existing == null && durationMs == 0;

  /// Manual entries (opened with durationMs == 0, no Pico value to prefill)
  /// need an editable duration field too, same as editing an existing
  /// record — only a genuine Pico-triggered new chug hides it.
  bool get showDurationField => isEditing || isManualEntry;

  @override
  ConsumerState<LogChugSheet> createState() => _LogChugSheetState();
}

class _LogChugSheetState extends ConsumerState<LogChugSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _durationController = TextEditingController(
    text: _msToSecondsText(widget.existing?.durationMs ?? widget.durationMs),
  );

  late String _liquid = widget.existing?.liquid ?? liquidOptions.first;
  late int _quantityMl = widget.existing?.quantityMl ?? 500;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final durationMs = widget.showDurationField
        ? _secondsTextToMs(_durationController.text)!
        : widget.durationMs;

    final record = ChugRecord(
      id: existing?.id,
      funnelId: existing?.funnelId ??
          ref.read(connectedDeviceIdProvider) ??
          'unknown',
      name: _nameController.text.trim(),
      liquid: _liquid,
      quantityMl: _quantityMl,
      durationMs: durationMs,
      loggedAt: existing?.loggedAt ??
          DateTime
              .now(), // overwritten by serverTimestamp in toFirestore for new records
    );

    try {
      final service = ref.read(firestoreServiceProvider);
      if (existing != null) {
        await service.updateChug(record);
      } else {
        await service.saveChug(record);
      }
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
    final isEditing = widget.isEditing;

    // The entry must only be discarded via the Discard button — block the
    // system back gesture/button here too (isDismissible/enableDrag on
    // showModalBottomSheet only stop tap-outside and swipe dismissal).
    return PopScope(
      canPop: false,
      child: Padding(
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
                  isEditing
                      ? 'Edit chug'
                      : widget.durationMs == 0
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
              if (widget.showDurationField) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Duration (s)',
                    helperText: 'e.g. 3.235 = 3.235s',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_secondsTextToMs(v ?? '') == null) {
                      return 'Enter a number of seconds';
                    }
                    return null;
                  },
                ),
              ],
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
                          : Text(isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the log-chug bottom sheet. Call with [existing] to edit a record
/// in place instead of creating a new one. Call from the leaderboard screen
/// when pendingChugDurationProvider becomes non-null.
///
/// Never dismissible by tapping outside, swiping, or the back
/// gesture/button — only the Discard button inside the sheet may close it
/// without saving, so a chug result can't be lost by accident.
Future<void> showLogChugSheet(
  BuildContext context,
  int durationMs, {
  ChugRecord? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => LogChugSheet(durationMs: durationMs, existing: existing),
  );
}
