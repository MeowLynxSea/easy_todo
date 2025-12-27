DateTime localDay(DateTime dateTime) {
  final local = dateTime.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool isSameLocalDay(DateTime a, DateTime b) {
  final aLocal = a.toLocal();
  final bLocal = b.toLocal();
  return aLocal.year == bLocal.year &&
      aLocal.month == bLocal.month &&
      aLocal.day == bLocal.day;
}
