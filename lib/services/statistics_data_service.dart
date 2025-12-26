import 'package:fl_chart/fl_chart.dart';
import 'package:easy_todo/models/statistics_data_model.dart';

class StatisticsDataService {
  static Map<String, dynamic> calculateAverageStatistics(
    List<StatisticsDataModel> data,
  ) {
    if (data.isEmpty) {
      return {'value': 0.0, 'trend': 0.0};
    }

    final values = data.map((d) => d.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;

    // Calculate trend (simple linear regression slope)
    double trend = 0.0;
    if (data.length > 1) {
      final sortedData = List<StatisticsDataModel>.from(data)
        ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

      final n = sortedData.length.toDouble();
      final sumX = n * (n - 1) / 2; // Sum of 0 to n-1
      final sumY = sortedData.map((d) => d.value).reduce((a, b) => a + b);
      final sumXY = sortedData
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key.toDouble();
            final value = entry.value.value;
            return index * value;
          })
          .reduce((a, b) => a + b);
      final sumX2 = n * (n - 1) * (2 * n - 1) / 6; // Sum of squares

      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      trend = slope;
    }

    return {'value': average, 'trend': trend};
  }

  static Map<String, dynamic> calculateGrowthStatistics(
    List<StatisticsDataModel> data,
  ) {
    if (data.isEmpty) {
      return {'growthRate': 0.0, 'totalGrowth': 0.0};
    }

    final sortedData = List<StatisticsDataModel>.from(data)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (sortedData.length == 1) {
      return {'growthRate': 0.0, 'totalGrowth': 0.0};
    }

    final firstValue = sortedData.first.value;
    final lastValue = sortedData.last.value;
    final totalGrowth = lastValue - firstValue;
    final growthRate = firstValue != 0 ? (totalGrowth / firstValue) * 100 : 0.0;

    return {'growthRate': growthRate, 'totalGrowth': totalGrowth};
  }

  static Map<String, dynamic> calculateExtremumStatistics(
    List<StatisticsDataModel> data,
  ) {
    if (data.isEmpty) {
      return {'min': 0.0, 'max': 0.0, 'range': 0.0};
    }

    final values = data.map((d) => d.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    return {'min': min, 'max': max, 'range': range};
  }

  static Map<String, dynamic> calculateSumStatistics(
    List<StatisticsDataModel> data,
  ) {
    if (data.isEmpty) {
      return {'total': 0.0, 'average': 0.0, 'count': 0};
    }

    final values = data.map((d) => d.value).toList();
    final total = values.reduce((a, b) => a + b);
    final average = total / values.length;

    return {'total': total, 'average': average, 'count': values.length};
  }

  static Map<String, dynamic> calculateTrendStatistics(
    List<StatisticsDataModel> data,
  ) {
    if (data.isEmpty) {
      return {'direction': 'stable', 'strength': 0.0};
    }

    final sortedData = List<StatisticsDataModel>.from(data)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (sortedData.length < 2) {
      return {'direction': 'stable', 'strength': 0.0};
    }

    // Calculate moving average for trend detection
    final windowSize = (sortedData.length / 3).floor().clamp(
      2,
      sortedData.length,
    );
    final movingAverages = <double>[];

    for (int i = 0; i <= sortedData.length - windowSize; i++) {
      final window = sortedData.sublist(i, i + windowSize);
      final avg =
          window.map((d) => d.value).reduce((a, b) => a + b) / window.length;
      movingAverages.add(avg);
    }

    // Determine trend direction and strength
    String direction = 'stable';
    double strength = 0.0;

    if (movingAverages.length > 1) {
      final firstHalf = movingAverages.sublist(
        0,
        (movingAverages.length / 2).floor(),
      );
      final secondHalf = movingAverages.sublist(
        (movingAverages.length / 2).ceil(),
      );

      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      final difference = secondAvg - firstAvg;
      final avgValue =
          sortedData.map((d) => d.value).reduce((a, b) => a + b) /
          sortedData.length;

      strength = avgValue != 0 ? (difference / avgValue).abs() : 0.0;

      if (difference > avgValue * 0.05) {
        direction = 'increasing';
      } else if (difference < -avgValue * 0.05) {
        direction = 'decreasing';
      }
    }

    return {'direction': direction, 'strength': strength};
  }

  static List<Map<String, dynamic>> getWeeklyData(
    List<StatisticsDataModel> data,
    DateTime endDate,
  ) {
    final weeklyData = <Map<String, dynamic>>[];
    final currentDate = endDate;

    for (int i = 6; i >= 0; i--) {
      final weekStart = currentDate.subtract(
        Duration(days: currentDate.weekday + i * 7),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekData = data.where((d) {
        return d.todoCreatedAt.isAfter(
              weekStart.subtract(const Duration(days: 1)),
            ) &&
            d.todoCreatedAt.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();

      if (weekData.isNotEmpty) {
        final values = weekData.map((d) => d.value).toList();
        weeklyData.add({
          'date': weekStart,
          'values': values,
          'average': values.reduce((a, b) => a + b) / values.length,
          'count': values.length,
        });
      } else {
        weeklyData.add({
          'date': weekStart,
          'values': <double>[],
          'average': 0.0,
          'count': 0,
        });
      }
    }

    return weeklyData.reversed.toList();
  }

  static List<Map<String, dynamic>> getMonthlyData(
    List<StatisticsDataModel> data,
    DateTime endDate,
  ) {
    final monthlyData = <Map<String, dynamic>>[];
    final currentDate = endDate;

    for (int i = 3; i >= 0; i--) {
      final month = DateTime(currentDate.year, currentDate.month - i, 1);
      final nextMonth = DateTime(
        currentDate.year,
        currentDate.month - i + 1,
        1,
      );

      final monthData = data.where((d) {
        return d.todoCreatedAt.isAfter(
              month.subtract(const Duration(days: 1)),
            ) &&
            d.todoCreatedAt.isBefore(nextMonth);
      }).toList();

      if (monthData.isNotEmpty) {
        final values = monthData.map((d) => d.value).toList();
        monthlyData.add({
          'date': month,
          'values': values,
          'average': values.reduce((a, b) => a + b) / values.length,
          'count': values.length,
        });
      } else {
        monthlyData.add({
          'date': month,
          'values': <double>[],
          'average': 0.0,
          'count': 0,
        });
      }
    }

    return monthlyData;
  }

  static Map<String, dynamic> calculateOverviewStatistics(
    List<StatisticsDataModel> data, {
    DateTime? startDate,
  }) {
    // Filter data by date range if startDate is provided
    final filteredData = startDate != null
        ? data.where((d) => d.todoCreatedAt.isAfter(startDate)).toList()
        : data;

    if (filteredData.isEmpty) {
      return {
        'totalEntries': 0,
        'totalValue': 0.0,
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'bestDay': null,
        'worstDay': null,
      };
    }

    final values = filteredData.map((d) => d.value).toList();
    final totalValue = values.reduce((a, b) => a + b);
    final average = totalValue / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    // Find best and worst days
    final dailyTotals = <DateTime, double>{};
    for (final item in filteredData) {
      final day = DateTime(
        item.todoCreatedAt.year,
        item.todoCreatedAt.month,
        item.todoCreatedAt.day,
      );
      dailyTotals[day] = (dailyTotals[day] ?? 0) + item.value;
    }

    DateTime? bestDay;
    DateTime? worstDay;
    double bestValue = double.negativeInfinity;
    double worstValue = double.infinity;

    dailyTotals.forEach((day, value) {
      if (value > bestValue) {
        bestValue = value;
        bestDay = day;
      }
      if (value < worstValue) {
        worstValue = value;
        worstDay = day;
      }
    });

    return {
      'totalEntries': filteredData.length,
      'totalValue': totalValue,
      'average': average,
      'min': min,
      'max': max,
      'bestDay': bestDay,
      'worstDay': worstDay,
    };
  }

  static List<FlSpot> createFlSpots(List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['average']?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  static List<FlSpot> createValueFlSpots(List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final values = entry.value['values'] as List<double>;
      final total = values.isNotEmpty ? values.reduce((a, b) => a + b) : 0.0;
      return FlSpot(entry.key.toDouble(), total);
    }).toList();
  }
}
