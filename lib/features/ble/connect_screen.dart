import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'ble_providers.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});
  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _isScanning = false;
  bool _isConnecting = false;
  List<ScanResult> _results = [];
  StreamSubscription? _scanSub;

  @override
  void dispose() {
    _scanSub?.cancel();
    ref.read(bleServiceProvider).stopScan();
    super.dispose();
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
      await ref.read(bleServiceProvider).connect(device);
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