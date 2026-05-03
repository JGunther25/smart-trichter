# CLAUDE.md

Guidance for Claude Code working in this repo.

## Project Overview

Smart Funnel is a Flutter app for the **funnel owner**. The owner connects their phone to a Raspberry Pi Pico W mounted on their beer funnel via BLE. After each chug, the Pico sends the measured chugging time to the app. The owner then enters who just chugged, what they drank, and the quantity. The result is saved locally on the device under that funnel's leaderboard.

The app's default state is the leaderboard for the connected funnel, filterable by liquid type and quantity. There are no user accounts — the funnel is the identity.

This is a hobby/party project. Keep it simple.

## Stack

- **Flutter** (Dart) — iOS + Android from a single codebase.
- **flutter_blue_plus** — BLE. Receives the chugging time from the Pico after each chug.
- **shared_preferences** — Local persistence. Chug records stored as a JSON list under a single key.
- **Riverpod** (`flutter_riverpod`) — lightweight state management. Use it where it earns its keep; don't over-provider.
- **go_router** — routing.

No Firebase, no SQLite, no Dio, no custom backend, no build flavors.

## Architecture

Feature folders, flat. No domain/repository/usecase layering.

```
lib/
  main.dart
  app.dart                  # MaterialApp + router
  router.dart
  theme.dart
  models/
    chug_record.dart        # Plain Dart class + JSON serialization
  services/
    local_storage_service.dart  # Save + watch chug records (shared_preferences)
    service_providers.dart      # Riverpod FutureProvider for LocalStorageService
  features/
    ble/                    # BLE scan, connect, receive chug time
    log_chug/               # Post-chug form (name, liquid, quantity)
    leaderboard/            # Default screen; filterable ranked list
```

## BLE Protocol (contract with firmware)

The Pico W advertises a custom GATT service. Keep UUIDs in sync with the firmware repo.

- **Service UUID**: `0000FUN1-0000-1000-8000-00805F9B34FB` (placeholder — replace before first hardware test)
- **Chug Result characteristic** (notify): the Pico sends a single payload after chugging ends.
  - Format: 4-byte little-endian unsigned int = duration in milliseconds.
  - Example: `0xA3 0x0C 0x00 0x00` = 3235 ms.

App behavior:
1. Scan filtered by service UUID.
2. On connect, subscribe to notifications on the Chug Result characteristic.
3. On receiving a payload, decode the duration and open the log-chug form.
4. The BLE device address is the **funnel ID** — used as the local storage partition key.
5. On disconnect, show a reconnect prompt. No auto-reconnect logic.

## Chug Logging Flow

1. Pico sends chug duration → app receives it via BLE notification.
2. App immediately opens the log-chug form (modal bottom sheet or separate screen — bottom sheet preferred).
3. Owner fills in:
   - **Name** — free text, required.
   - **Liquid** — dropdown or chip selector (e.g., Beer, Wine, Prosecco, Other). Required.
   - **Quantity (ml)** — number input. Required. Suggested values: 250, 330, 500, 1000.
4. Owner taps "Save" → written to local storage → form closes → leaderboard updates.
5. "Discard" dismisses without saving.

## Local Storage Data Model

Records are stored as a JSON list in `shared_preferences` under the key `chug_records`.

Each record:
```json
{
  "id": "string",        // microsecondsSinceEpoch, assigned on save
  "funnelId": "string",  // BLE device address of the funnel
  "name": "string",      // Who chugged
  "liquid": "string",    // e.g. "Beer"
  "quantityMl": 330,
  "durationMs": 3210,
  "loggedAt": "2024-06-01T12:00:00.000"  // ISO 8601 UTC
}
```

All records in one flat list, filtered by `funnelId` in queries.

## LocalStorageService

`LocalStorageService` wraps `SharedPreferences` and exposes:
- `saveChug(ChugRecord)` — appends a record (assigns id, persists).
- `watchLeaderboard({funnelId, liquid?, quantityMl?})` → `Stream<List<ChugRecord>>` — filtered + sorted ascending by `durationMs`.
- `watchAllLeaderboard({liquid?, quantityMl?})` → `Stream<List<ChugRecord>>` — same, no funnel filter.

Streams emit current state on subscribe, then re-emit after each `saveChug`.

The service is exposed via `localStorageServiceProvider` (`FutureProvider`) — await it before use.

## Leaderboard (Default Screen)

- Shows all chugs for the **currently connected funnel** (filter by `funnelId`).
- Sorted by `durationMs` ascending (fastest at the top).
- Filter controls at the top:
  - **Liquid** — "All" + the distinct liquid types in the dataset. Chip-style selector.
  - **Quantity** — "All" + distinct quantities. Chip-style selector.
- Each row: rank, name, duration (formatted as `ss.SSS`s), liquid, quantity.
- If no funnel is connected, show all chugs across all funnels or a "Connect a funnel" prompt.
- Leaderboard updates reactively via `StreamProvider`.

## devcontainers Note

BLE is on the **host** Bluetooth stack, not inside the container. Flutter's BLE plugin (`flutter_blue_plus`) calls the host OS's BLE APIs at runtime — this only matters when running the app **on a real device**. The code compiles and the emulator runs normally from inside the container.

However:
- `flutter run` targeting a **physical device** via USB/ADB must be run from the host, not the container, unless USB passthrough is configured (via `usbipd` on Windows/WSL2 or `--device-cgroup-rules` on Linux).
- Emulator/simulator targets work from inside the container as normal.
- Hot reload and `flutter analyze` work inside the container regardless.
- Document the host-side run steps in the README so the workflow is clear.

## Common Commands

```bash
# Inside devcontainer
flutter pub get
flutter analyze
dart format .
flutter test
flutter build apk --release
flutter build ipa --release
```

## Conventions

- `flutter_lints` — fix all warnings, don't suppress them.
- `dart format .` before committing.
- `debugPrint` for logging. No logger package.
- `StatefulWidget` is fine when it's simpler than a provider. Don't over-Riverpod.
- Handle errors where recovery is possible; let the rest surface visibly. No `Result<T,E>`.

## Testing

- Unit test JSON serialization (ChugRecord round-trip).
- Unit test `LocalStorageService` save + query logic using `SharedPreferences.setMockInitialValues({})`.
- Unit test BLE byte-decoding (4-byte little-endian → int).
- Skip widget tests for simple screens.
- BLE integration: manual, on real hardware.

## What NOT to do

- Don't add Firebase or any cloud backend.
- Don't add SQLite — `shared_preferences` JSON is sufficient for this scale.
- Don't add user accounts or auth.
- Don't add build flavors or env files.
- Don't add analytics, crash reporting, or remote config.
- Don't add a `domain/` layer, repository interfaces, or use-cases.
- Don't auto-reconnect BLE — show a prompt instead.
- Don't measure chug duration on the phone — trust the Pico's value.

## Open Questions

- Final GATT UUIDs and exact byte format (confirm with firmware).
- Liquid options list — hardcoded for now; make it configurable later if needed.
- Should the leaderboard persist across funnel sessions (all-time), or only show the current session? Default: all-time, filterable.
- Recent-names UX in the log-chug form — helpful at parties, implement if time allows.
