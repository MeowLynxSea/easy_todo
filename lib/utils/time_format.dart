String formatMinutesAsHHmm(int minutes) {
  final clamped = minutes.clamp(0, 1440);
  if (clamped == 1440) return '24:00';
  final h = clamped ~/ 60;
  final m = clamped % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
