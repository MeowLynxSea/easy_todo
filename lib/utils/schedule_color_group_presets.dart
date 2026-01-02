import 'package:easy_todo/models/schedule_color_group.dart';

class ScheduleColorGroupPresets {
  static const ScheduleColorGroup warmCool = ScheduleColorGroup(
    id: 'preset:warm_cool',
    name: 'Warm & Cool',
    incompleteColorsArgb: <int>[
      0xFFFFE0B2, // orange100
      0xFFFFCCBC, // deepOrange100
      0xFFFFECB3, // amber100
      0xFFFFC1E3, // pink100
      0xFFFFCDD2, // red100
    ],
    completedColorsArgb: <int>[
      0xFF1565C0, // blue800
      0xFF006064, // cyan900
      0xFF004D40, // teal900
      0xFF283593, // indigo800
      0xFF1B5E20, // green900
    ],
  );

  static const ScheduleColorGroup forestLavender = ScheduleColorGroup(
    id: 'preset:forest_lavender',
    name: 'Forest & Lavender',
    incompleteColorsArgb: <int>[
      0xFFD1FAE5, // emerald100
      0xFFBBF7D0, // green200
      0xFFBAE6FD, // sky200
      0xFFE0F2FE, // sky100
      0xFFE9D5FF, // purple200
    ],
    completedColorsArgb: <int>[
      0xFF1B4332, // deep forest
      0xFF2D6A4F, // deep green
      0xFF2E1065, // deep purple
      0xFF312E81, // indigo900
      0xFF0F172A, // slate900
    ],
  );

  static const ScheduleColorGroup sunsetOcean = ScheduleColorGroup(
    id: 'preset:sunset_ocean',
    name: 'Sunset & Ocean',
    incompleteColorsArgb: <int>[
      0xFFFFE4E6, // rose100
      0xFFFFE0E7, // pink100
      0xFFFFEDD5, // orange100
      0xFFFEF3C7, // amber100
      0xFFE0F2FE, // sky100
    ],
    completedColorsArgb: <int>[
      0xFF0B3C5D, // deep ocean
      0xFF0F766E, // teal700
      0xFF1E3A8A, // blue900
      0xFF164E63, // cyan900
      0xFF1F2937, // gray800
    ],
  );

  static const ScheduleColorGroup grayscale = ScheduleColorGroup(
    id: 'preset:grayscale',
    name: 'Grayscale',
    incompleteColorsArgb: <int>[
      0xFFF3F4F6,
      0xFFE5E7EB,
      0xFFD1D5DB,
      0xFF9CA3AF,
      0xFF6B7280,
    ],
    completedColorsArgb: <int>[
      0xFF374151, // gray700
      0xFF1F2937, // gray800
      0xFF111827, // gray900
      0xFF0B0F1A, // near-black
      0xFF000000, // black
    ],
  );

  static const List<ScheduleColorGroup> all = <ScheduleColorGroup>[
    warmCool,
    forestLavender,
    sunsetOcean,
    grayscale,
  ];

  static ScheduleColorGroup? byId(String id) {
    for (final group in all) {
      if (group.id == id) return group;
    }
    return null;
  }
}
