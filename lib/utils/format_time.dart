String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;

  if (m == 0) return "${s}s";
  return s == 0 ? "${m}m" : "${m}m ${s}s";
}
