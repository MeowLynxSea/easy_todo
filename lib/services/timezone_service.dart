import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  static final TimezoneService _instance = TimezoneService._internal();
  factory TimezoneService() => _instance;
  TimezoneService._internal();

  // Comprehensive timezone abbreviation to IANA mapping
  static const Map<String, String> _timezoneAbbreviationMap = {
    // North America
    'EST': 'America/New_York',
    'EDT': 'America/New_York',
    'CST': 'America/Chicago',
    'CDT': 'America/Chicago',
    'MST': 'America/Denver',
    'MDT': 'America/Denver',
    'PST': 'America/Los_Angeles',
    'PDT': 'America/Los_Angeles',
    'AKST': 'America/Anchorage',
    'AKDT': 'America/Anchorage',
    'HST': 'Pacific/Honolulu',
    'HDT': 'Pacific/Honolulu',

    // Europe
    'GMT': 'Europe/London',
    'BST': 'Europe/London',
    'CET': 'Europe/Paris',
    'CEST': 'Europe/Paris',
    'EET': 'Europe/Helsinki',
    'EEST': 'Europe/Helsinki',
    'MSK': 'Europe/Moscow',
    'MSD': 'Europe/Moscow',
    'WET': 'Europe/Lisbon',
    'WEST': 'Europe/Lisbon',

    // Asia
    'JST': 'Asia/Tokyo',
    'KST': 'Asia/Seoul',
    'CNST': 'Asia/Shanghai', // Chinese Standard Time
    'HKT': 'Asia/Hong_Kong',
    'SGT': 'Asia/Singapore',
    'IST': 'Asia/Kolkata',
    'PKT': 'Asia/Karachi',
    'IRST': 'Asia/Tehran',
    'IDT': 'Asia/Jerusalem',
    'GST': 'Asia/Dubai',
    'WIB': 'Asia/Jakarta',
    'WITA': 'Asia/Makassar',
    'WIT': 'Asia/Jayapura',
    'PHT': 'Asia/Manila',
    'ICT': 'Asia/Bangkok',
    'VST': 'Asia/Ho_Chi_Minh',
    'MMT': 'Asia/Yangon',
    'BTT': 'Asia/Thimphu',
    'BNT': 'Asia/Brunei',
    'CHOT': 'Asia/Choibalsan',
    'TWT': 'Asia/Taipei',
    'WAKT': 'Pacific/Wake',

    // Australia/Pacific
    'AEST': 'Australia/Sydney',
    'AEDT': 'Australia/Sydney',
    'ACST': 'Australia/Adelaide',
    'ACDT': 'Australia/Adelaide',
    'AWST': 'Australia/Perth',
    'AWDT': 'Australia/Perth',
    'NZST': 'Pacific/Auckland',
    'NZDT': 'Pacific/Auckland',
    'FJT': 'Pacific/Fiji',
    'NCT': 'Pacific/Noumea',
    'VUT': 'Pacific/Efate',
    'GILT': 'Pacific/Tarawa',
    'TVT': 'Pacific/Funafuti',
    'TOT': 'Pacific/Tongatapu',
    'SST': 'Pacific/Guadalcanal',
    'CKT': 'Pacific/Rarotonga',
    'NUT': 'Pacific/Niue',

    // Africa
    'CAT': 'Africa/Harare',
    'SAST': 'Africa/Johannesburg',
    'EAT': 'Africa/Nairobi',
    'WAT': 'Africa/Lagos',
    'WAST': 'Africa/Windhoek',
    'EGT': 'Africa/Cairo',

    // South America
    'ART': 'America/Argentina/Buenos_Aires',
    'BOT': 'America/La_Paz',
    'BRT': 'America/Sao_Paulo',
    'BRST': 'America/Sao_Paulo',
    'CLT': 'America/Santiago',
    'CLST': 'America/Santiago',
    'COT': 'America/Bogota',
    'ECT': 'America/Guayaquil',
    'FKST': 'Atlantic/Stanley',
    'FKT': 'Atlantic/Stanley',
    'GFT': 'America/Cayenne',
    'GYT': 'America/Guyana',
    'PYT': 'America/Asuncion',
    'PYST': 'America/Asuncion',
    'SRT': 'America/Paramaribo',
    'UYT': 'America/Montevideo',
    'UYST': 'America/Montevideo',
    'VET': 'America/Caracas',

    // Middle East
    'AST': 'Asia/Riyadh',

    // Indian Ocean
    'MVT': 'Indian/Maldives',
    'SCT': 'Indian/Mahe',
    'MUT': 'Indian/Mauritius',
    'RET': 'Indian/Reunion',
    'TFT': 'Indian/Kerguelen',

    // Other
    'UTC': 'UTC',
    'Z': 'UTC',

    // Military time zones
    'A': 'UTC+1',
    'B': 'UTC+2',
    'C': 'UTC+3',
    'D': 'UTC+4',
    'E': 'UTC+5',
    'F': 'UTC+6',
    'G': 'UTC+7',
    'H': 'UTC+8',
    'I': 'UTC+9',
    'K': 'UTC+10',
    'L': 'UTC+11',
    'M': 'UTC+12',
    'N': 'UTC-1',
    'O': 'UTC-2',
    'P': 'UTC-3',
    'Q': 'UTC-4',
    'R': 'UTC-5',
    'S': 'UTC-6',
    'T': 'UTC-7',
    'U': 'UTC-8',
    'V': 'UTC-9',
    'W': 'UTC-10',
    'X': 'UTC-11',
    'Y': 'UTC-12',
  };

  // GMT offset to IANA timezone mapping (fallback)
  static final Map<double, List<String>> _gmtOffsetMap = {
    -12: ['Pacific/Baker', 'Pacific/Howland'],
    -11: ['Pacific/Pago_Pago', 'Pacific/Niue'],
    -10: ['Pacific/Honolulu', 'Pacific/Rarotonga', 'Pacific/Tahiti'],
    -9: ['America/Anchorage', 'Pacific/Gambier'],
    -8: ['America/Los_Angeles', 'America/Vancouver', 'America/Tijuana'],
    -7: ['America/Denver', 'America/Phoenix', 'America/Chihuahua'],
    -6: ['America/Chicago', 'America/Mexico_City', 'America/Guatemala'],
    -5: ['America/New_York', 'America/Toronto', 'America/Bogota'],
    -4: ['America/Halifax', 'America/Caracas', 'America/La_Paz'],
    -3: ['America/Sao_Paulo', 'America/Buenos_Aires', 'America/Recife'],
    -2: ['America/Noronha', 'Atlantic/South_Georgia'],
    -1: ['Atlantic/Azores', 'Atlantic/Cape_Verde'],
    0: ['Europe/London', 'Europe/Dublin', 'Africa/Casablanca'],
    1: ['Europe/Paris', 'Europe/Berlin', 'Africa/Lagos'],
    2: ['Europe/Helsinki', 'Africa/Cairo', 'Europe/Athens'],
    3: ['Europe/Moscow', 'Africa/Nairobi', 'Asia/Baghdad'],
    4: ['Asia/Dubai', 'Asia/Tbilisi', 'Asia/Yerevan'],
    5: ['Asia/Karachi', 'Asia/Tashkent', 'Indian/Maldives'],
    5.5: ['Asia/Kolkata', 'Asia/Colombo'],
    6: ['Asia/Dhaka', 'Asia/Almaty', 'Indian/Chagos'],
    7: ['Asia/Bangkok', 'Asia/Jakarta', 'Indian/Christmas'],
    8: ['Asia/Shanghai', 'Asia/Hong_Kong', 'Asia/Singapore'],
    9: ['Asia/Tokyo', 'Asia/Seoul', 'Pacific/Palau'],
    10: ['Australia/Sydney', 'Pacific/Guam', 'Asia/Vladivostok'],
    11: ['Pacific/Noumea', 'Pacific/Guadalcanal', 'Asia/Magadan'],
    12: ['Pacific/Auckland', 'Pacific/Fiji', 'Asia/Kamchatka'],
    13: ['Pacific/Tongatapu', 'Pacific/Fakaofo'],
    14: ['Pacific/Kiritimati'],
  };

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      _isInitialized = true;
      // debugPrint('Timezone database initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize timezone database: $e');
      rethrow;
    }
  }

  /// Enhanced timezone detection with comprehensive mapping
  String detectTimezone() {
    try {
      if (!_isInitialized) {
        throw Exception('TimezoneService not initialized');
      }

      final now = DateTime.now();
      final timeZoneName = now.timeZoneName.toUpperCase();
      final timeZoneOffset = now.timeZoneOffset;
      final offsetInHours =
          timeZoneOffset.inHours + (timeZoneOffset.inMinutes % 60) / 60.0;

      // debugPrint('=== Enhanced Timezone Detection ===');
      // debugPrint('Device timezone name: $timeZoneName');
      // debugPrint('Device timezone offset: $timeZoneOffset (${offsetInHours.toStringAsFixed(2)} hours)');

      // Try direct timezone name match first
      String? detectedTimezone = _tryDirectTimezoneName(timeZoneName);
      if (detectedTimezone != null) {
        // debugPrint('Detected via direct name match: $detectedTimezone');
        return detectedTimezone;
      }

      // Try abbreviation mapping
      detectedTimezone = _tryAbbreviationMapping(timeZoneName);
      if (detectedTimezone != null) {
        // debugPrint('Detected via abbreviation mapping: $detectedTimezone');
        return detectedTimezone;
      }

      // Try GMT offset parsing
      detectedTimezone = _tryGmtOffsetParsing(timeZoneName, offsetInHours);
      if (detectedTimezone != null) {
        // debugPrint('Detected via GMT offset parsing: $detectedTimezone');
        return detectedTimezone;
      }

      // Fallback to GMT offset mapping
      detectedTimezone = _fallbackToOffsetMapping(offsetInHours);
      if (detectedTimezone != null) {
        // debugPrint('Detected via offset fallback: $detectedTimezone');
        return detectedTimezone;
      }

      // debugPrint('No timezone detected, using UTC');
      return 'UTC';
    } catch (e) {
      debugPrint('Error detecting timezone: $e');
      return 'UTC';
    }
  }

  String? _tryDirectTimezoneName(String timeZoneName) {
    try {
      // Try to use the timezone name directly if it's a valid IANA timezone
      if (timeZoneName.contains('/') &&
          timeZoneName != 'GMT' &&
          timeZoneName != 'UTC') {
        try {
          tz.getLocation(timeZoneName);
          return timeZoneName;
        } catch (e) {
          debugPrint('Direct timezone name $timeZoneName is not valid: $e');
        }
      }

      // Check for timezone name with region removed
      if (timeZoneName.startsWith('GMT')) {
        final cleanName = timeZoneName.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
        if (cleanName != timeZoneName) {
          try {
            tz.getLocation(cleanName);
            return cleanName;
          } catch (e) {
            debugPrint('Cleaned timezone name $cleanName is not valid: $e');
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error in direct timezone name detection: $e');
      return null;
    }
  }

  String? _tryAbbreviationMapping(String timeZoneName) {
    try {
      // Check exact abbreviation match
      if (_timezoneAbbreviationMap.containsKey(timeZoneName)) {
        return _timezoneAbbreviationMap[timeZoneName];
      }

      // Check for partial matches (e.g., "GMT+8" should match with "GMT")
      for (final entry in _timezoneAbbreviationMap.entries) {
        if (timeZoneName.contains(entry.key) ||
            entry.key.contains(timeZoneName)) {
          return entry.value;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error in abbreviation mapping: $e');
      return null;
    }
  }

  String? _tryGmtOffsetParsing(String timeZoneName, double offsetInHours) {
    try {
      // Parse GMT offset patterns
      final gmtPattern = RegExp(r'GMT([+-])(\d+)(?::?(\d+))?');
      final utcPattern = RegExp(r'UTC([+-])(\d+)(?::?(\d+))?');

      RegExpMatch? match =
          gmtPattern.firstMatch(timeZoneName) ??
          utcPattern.firstMatch(timeZoneName);

      if (match != null) {
        final sign = match.group(1) == '+' ? 1 : -1;
        final hours = int.parse(match.group(2)!);
        final minutes = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        final totalOffset = sign * (hours + minutes / 60.0);

        return _findBestTimezoneForOffset(totalOffset);
      }

      return null;
    } catch (e) {
      debugPrint('Error in GMT offset parsing: $e');
      return null;
    }
  }

  String? _fallbackToOffsetMapping(double offsetInHours) {
    try {
      // Find closest offset match
      return _findBestTimezoneForOffset(offsetInHours);
    } catch (e) {
      debugPrint('Error in offset fallback: $e');
      return null;
    }
  }

  String? _findBestTimezoneForOffset(double offsetInHours) {
    try {
      // Check for exact match first
      if (_gmtOffsetMap.containsKey(offsetInHours)) {
        final timezones = _gmtOffsetMap[offsetInHours]!;
        // Return the most common timezone for this offset
        return _getPreferredTimezone(timezones);
      }

      // Check for approximate match (within 30 minutes)
      for (final entry in _gmtOffsetMap.entries) {
        if ((entry.key - offsetInHours).abs() <= 0.5) {
          final timezones = entry.value;
          return _getPreferredTimezone(timezones);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding timezone for offset: $e');
      return null;
    }
  }

  String _getPreferredTimezone(List<String> timezones) {
    // Return the most commonly used timezone for this offset
    // Priority order: major cities > regions
    final preferredOrder = [
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'Europe/London',
      'Europe/Paris',
      'Europe/Berlin',
      'Europe/Moscow',
      'Asia/Shanghai',
      'Asia/Tokyo',
      'Asia/Seoul',
      'Asia/Singapore',
      'Asia/Kolkata',
      'Australia/Sydney',
      'Pacific/Auckland',
    ];

    for (final preferred in preferredOrder) {
      if (timezones.contains(preferred)) {
        return preferred;
      }
    }

    // Return first timezone if no preferred match
    return timezones.first;
  }

  /// Get current time in the detected timezone
  DateTime getCurrentTime() {
    try {
      if (!_isInitialized) {
        return DateTime.now();
      }

      return tz.TZDateTime.now(tz.local);
    } catch (e) {
      debugPrint('Error getting current time: $e');
      return DateTime.now();
    }
  }

  /// Convert local time to UTC
  DateTime toUtc(DateTime localTime) {
    try {
      if (!_isInitialized) {
        return localTime.toUtc();
      }

      if (localTime is tz.TZDateTime) {
        return localTime.toUtc();
      }

      return tz.TZDateTime.from(localTime, tz.local).toUtc();
    } catch (e) {
      debugPrint('Error converting to UTC: $e');
      return localTime.toUtc();
    }
  }

  /// Convert UTC to local time
  DateTime fromUtc(DateTime utcTime) {
    try {
      if (!_isInitialized) {
        return utcTime.toLocal();
      }

      if (utcTime is tz.TZDateTime) {
        return tz.TZDateTime.from(utcTime, tz.local);
      }

      return tz.TZDateTime.from(utcTime, tz.local);
    } catch (e) {
      debugPrint('Error converting from UTC: $e');
      return utcTime.toLocal();
    }
  }

  /// Get timezone information
  Map<String, dynamic> getTimezoneInfo() {
    try {
      final now = DateTime.now();
      final localNow = getCurrentTime();

      return {
        'device_timezone': now.timeZoneName,
        'device_offset': now.timeZoneOffset.inHours,
        'detected_timezone': tz.local.name,
        'local_time': localNow,
        'utc_time': DateTime.now().toUtc(),
        'offset_hours': localNow.timeZoneOffset.inHours,
        'offset_minutes': localNow.timeZoneOffset.inMinutes % 60,
      };
    } catch (e) {
      debugPrint('Error getting timezone info: $e');
      return {'error': e.toString()};
    }
  }

  /// Force a specific timezone (for testing)
  Future<void> setCustomTimezone(String timezoneId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final location = tz.getLocation(timezoneId);
      tz.setLocalLocation(location);
      // debugPrint('Manually set timezone to: $timezoneId');
    } catch (e) {
      debugPrint('Failed to set custom timezone $timezoneId: $e');
    }
  }

  /// Get list of supported timezones
  List<String> getSupportedTimezones() {
    return [
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'Europe/London',
      'Europe/Paris',
      'Europe/Berlin',
      'Europe/Moscow',
      'Asia/Shanghai',
      'Asia/Tokyo',
      'Asia/Seoul',
      'Asia/Singapore',
      'Asia/Kolkata',
      'Australia/Sydney',
      'Pacific/Auckland',
      'America/Toronto',
      'America/Vancouver',
      'America/Mexico_City',
      'America/Sao_Paulo',
      'America/Buenos_Aires',
      'Africa/Cairo',
      'Africa/Johannesburg',
      'Pacific/Honolulu',
      'Asia/Dubai',
    ];
  }
}
