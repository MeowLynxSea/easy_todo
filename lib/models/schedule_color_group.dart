import 'dart:convert';
import 'dart:ui';

class ScheduleColorGroup {
  final String id;
  final String name;
  final List<int> incompleteColorsArgb;
  final List<int> completedColorsArgb;

  const ScheduleColorGroup({
    required this.id,
    required this.name,
    required this.incompleteColorsArgb,
    required this.completedColorsArgb,
  });

  List<Color> get incompleteColors =>
      incompleteColorsArgb.map((e) => Color(e)).toList(growable: false);

  List<Color> get completedColors =>
      completedColorsArgb.map((e) => Color(e)).toList(growable: false);

  ScheduleColorGroup copyWith({
    String? id,
    String? name,
    List<int>? incompleteColorsArgb,
    List<int>? completedColorsArgb,
  }) {
    return ScheduleColorGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      incompleteColorsArgb: incompleteColorsArgb ?? this.incompleteColorsArgb,
      completedColorsArgb: completedColorsArgb ?? this.completedColorsArgb,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'incompleteColorsArgb': incompleteColorsArgb,
      'completedColorsArgb': completedColorsArgb,
    };
  }

  factory ScheduleColorGroup.fromJson(Map<String, dynamic> json) {
    return ScheduleColorGroup(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      incompleteColorsArgb:
          (json['incompleteColorsArgb'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(growable: false) ??
          const <int>[],
      completedColorsArgb:
          (json['completedColorsArgb'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(growable: false) ??
          const <int>[],
    );
  }

  static List<ScheduleColorGroup> decodeListFromString(String raw) {
    if (raw.trim().isEmpty) return const <ScheduleColorGroup>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ScheduleColorGroup>[];
      return decoded
          .whereType<Object?>()
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
          .whereType<Map<String, dynamic>>()
          .map(ScheduleColorGroup.fromJson)
          .where((e) => e.id.trim().isNotEmpty && e.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <ScheduleColorGroup>[];
    }
  }

  static String encodeListToString(List<ScheduleColorGroup> groups) {
    final payload = groups.map((e) => e.toJson()).toList(growable: false);
    return jsonEncode(payload);
  }
}
