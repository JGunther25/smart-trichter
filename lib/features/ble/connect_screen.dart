import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/chug_record.dart';
import '../../services/service_providers.dart';
import '../leaderboard/leaderboard_providers.dart';
import 'ble_providers.dart';
import 'ble_service.dart';
import 'legacy_import_service.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});
  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isImporting = false;
  List<ScanResult> _results = [];
  StreamSubscription? _scanSub;
  Future<List<ChugRecord>>? _legacyRecords;
  late final BleService _bleService;

  @override
  void initState() {
    super.initState();
    _legacyRecords = readLegacyRecords();
    // Cache the service now — ref can become unusable by the time dispose()
    // runs if the wider widget tree is tearing down at the same time.
    _bleService = ref.read(bleServiceProvider);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _bleService.stopScan();
    super.dispose();
  }

  Future<void> _importLegacyRecords(List<ChugRecord> records) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import local chugs?'),
        content: Text(
          'Found ${records.length} chug${records.length == 1 ? '' : 's'} saved '
          'on this device before Firestore. Copy them to Firestore now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isImporting = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      await importLegacyRecords(service, records);
      if (mounted) {
        setState(() {
          _isImporting = false;
          _legacyRecords = Future.value(const []);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Imported ${records.length} chugs to Firestore')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _startScan() async {
    _scanSub?.cancel();
    setState(() {
      _results = [];
      _isScanning = true;
    });
    final bleService = ref.read(bleServiceProvider);
    _scanSub = bleService.scanResults.listen((results) {
      if (mounted) setState(() => _results = results);
    });
    await bleService.startScan();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      final bleService = ref.read(bleServiceProvider);
      await bleService.connect(device);
      ref.read(browsingFunnelProvider.notifier).state = null;

      final id = bleService.connectedDeviceId;
      final name = bleService.connectedDeviceName;
      if (id != null && name != null) {
        // Best-effort — a failure here shouldn't block using the funnel.
        unawaited(
          ref.read(firestoreServiceProvider).saveFunnelName(id, name),
        );
      }

      if (mounted) context.go('/leaderboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Funnel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(_isScanning ? 'Scanning…' : 'Scan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go('/funnels'),
              icon: const Icon(Icons.leaderboard),
              label: const Text('Browse a funnel\'s leaderboard'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                            ? 'Looking for funnels…'
                            : 'Tap Scan to find nearby funnels.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        final name = r.device.platformName.isNotEmpty
                            ? r.device.platformName
                            : r.device.remoteId.str;
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(name),
                          subtitle: Text(r.device.remoteId.str),
                          trailing: Text('${r.rssi} dBm'),
                          onTap: () => _connect(r.device),
                        );
                      },
                    ),
            ),
            FutureBuilder<List<ChugRecord>>(
              future: _legacyRecords,
              builder: (context, snapshot) {
                final records = snapshot.data ?? const [];
                if (records.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: _isImporting
                        ? null
                        : () => _importLegacyRecords(records),
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                        'Import ${records.length} local chugs to Firestore'),
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () => context.go('/leaderboard'),
              child: const Text('Skip / no funnel'),
            ),
          ],
        ),
      ),
    );
  }
}
