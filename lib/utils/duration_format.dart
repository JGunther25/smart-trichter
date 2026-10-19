String formatChugDuration(int ms) {
  final totalSeconds = ms ~/ 1000;
  final millis = ms % 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  final millisStr = millis.toString().padLeft(3, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');

  if (minutes > 0) {
    return '$minutes:$secondsStr.${millisStr}s';
  }
  return '${seconds.toString()}.${millisStr}s';
}

/// How leaderboard times are shown; tapping a time cycles through these.
enum TimeDisplayMode { overall, gapToLeader, interval }

extension TimeDisplayModeCycle on TimeDisplayMode {
  TimeDisplayMode get next =>
      TimeDisplayMode.values[(index + 1) % TimeDisplayMode.values.length];
}

/// Formats a time difference as `+s.SSS` (e.g. `+0.200`).
String formatChugGap(int ms) {
  final formatted = formatChugDuration(ms);
  return '+${formatted.substring(0, formatted.length - 1)}';
}

/// Formats the time at [index] of [sortedDurationsMs] (ascending) for [mode].
/// The leader always shows its full time.
String formatLeaderboardTime(
  List<int> sortedDurationsMs,
  int index,
  TimeDisplayMode mode,
) {
  final ms = sortedDurationsMs[index];
  if (index == 0) return formatChugDuration(ms);
  return switch (mode) {
    TimeDisplayMode.overall => formatChugDuration(ms),
    TimeDisplayMode.gapToLeader => formatChugGap(ms - sortedDurationsMs.first),
    TimeDisplayMode.interval =>
      formatChugGap(ms - sortedDurationsMs[index - 1]),
  };
}
