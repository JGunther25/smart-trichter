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
