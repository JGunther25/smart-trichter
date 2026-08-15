const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a UTC-stored timestamp for display in local time, e.g.
/// "Today, 14:32" / "Yesterday, 09:05" / "Aug 15, 14:32".
String formatChugTimestamp(DateTime loggedAt) {
  final local = loggedAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

  final dayDiff = today.difference(day).inDays;
  if (dayDiff == 0) return 'Today, $time';
  if (dayDiff == 1) return 'Yesterday, $time';
  return '${_months[local.month - 1]} ${local.day}, $time';
}
