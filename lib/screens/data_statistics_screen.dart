import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/services/timezone_service.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';
import 'package:easy_todo/utils/date_utils.dart';

class DataStatisticsScreen extends StatefulWidget {
  final String? navigationSource;

  const DataStatisticsScreen({super.key, this.navigationSource});

  @override
  State<DataStatisticsScreen> createState() => _DataStatisticsScreenState();
}

class _DataStatisticsScreenState extends State<DataStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TimezoneService _timezoneService;
  RepeatTodoModel? _selectedRepeatTodo;
  DateTimeRange? _selectedDateRange;

  // 获取本地时间的辅助方法
  DateTime _getLocalNow() {
    return _timezoneService.getCurrentTime();
  }

  @override
  void initState() {
    super.initState();
    _timezoneService = TimezoneService();
    _tabController = TabController(length: 4, vsync: this);

    // Set default to "All Data" for weekly and monthly views
    if (widget.navigationSource == 'thisWeek' ||
        widget.navigationSource == 'thisMonth') {
      _selectedRepeatTodo = null; // null represents "All Data"
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final repeatTodosWithStats = todoProvider.repeatTodos
            .where((rt) => rt.dataStatisticsEnabled)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: widget.navigationSource == 'overview'
                ? Text('${l10n.dataStatisticsTab}-${l10n.timePeriodOverview}')
                : Text(l10n.dataStatisticsTab),
            bottom: widget.navigationSource == null
                ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: [
                      Tab(text: l10n.timePeriodToday),
                      Tab(text: l10n.timePeriodThisWeek),
                      Tab(text: l10n.timePeriodThisMonth),
                      Tab(text: l10n.timePeriodOverview),
                    ],
                  )
                : null,
          ),
          body: WebDesktopContent(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Repeat task selector and time period selector (only for direct access to statistics page)
                if (widget.navigationSource == null)
                  _buildSelectors(repeatTodosWithStats, l10n),

                // Main content
                Expanded(
                  child: widget.navigationSource == null
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            Builder(
                              builder: (_) =>
                                  _buildTodayView(todoProvider, l10n),
                            ),
                            Builder(
                              builder: (_) =>
                                  _buildWeeklyView(todoProvider, l10n),
                            ),
                            Builder(
                              builder: (_) =>
                                  _buildMonthlyView(todoProvider, l10n),
                            ),
                            Builder(
                              builder: (_) =>
                                  _buildOverviewView(todoProvider, l10n),
                            ),
                          ],
                        )
                      : _buildFilteredView(todoProvider, l10n),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilteredView(TodoProvider todoProvider, AppLocalizations l10n) {
    switch (widget.navigationSource) {
      case 'today':
        return _buildTodayView(todoProvider, l10n);
      case 'thisWeek':
        return _buildWeeklyView(todoProvider, l10n);
      case 'thisMonth':
        return _buildMonthlyView(todoProvider, l10n);
      default:
        return _buildOverviewView(todoProvider, l10n);
    }
  }

  Widget _buildSelectors(
    List<RepeatTodoModel> repeatTodosWithStats,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Repeat task selector
          if (repeatTodosWithStats.isNotEmpty &&
              widget.navigationSource == null)
            DropdownButtonFormField<RepeatTodoModel>(
              value: _selectedRepeatTodo ?? repeatTodosWithStats.first,
              decoration: InputDecoration(
                labelText: l10n.selectRepeatTask,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: repeatTodosWithStats.map((repeatTodo) {
                return DropdownMenuItem(
                  value: repeatTodo,
                  child: Text(repeatTodo.title),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRepeatTodo = value;
                });
              },
            ),

          // Date range selector for overview mode
          if (widget.navigationSource == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(_getDateRangeDisplay(l10n)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataSelector(
    List<RepeatTodoModel> repeatTodosWithStats,
    AppLocalizations l10n, {
    required bool isWeekly,
  }) {
    // Add "All Data" option at the beginning
    final allOptions = [
      {'id': 'all', 'title': l10n.allData},
      ...repeatTodosWithStats.map(
        (todo) => {'id': todo.id, 'title': todo.title},
      ),
    ];

    // Find current selection or default to 'all'
    final currentSelection = _selectedRepeatTodo?.id ?? 'all';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWeekly ? l10n.selectRepeatTask : l10n.selectRepeatTask,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentSelection,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: allOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['id'],
                child: Text(option['title']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                if (value == 'all') {
                  _selectedRepeatTodo = null; // null represents all data
                } else {
                  _selectedRepeatTodo = repeatTodosWithStats.firstWhere(
                    (todo) => todo.id == value,
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayView(TodoProvider todoProvider, AppLocalizations l10n) {
    final repeatTodosWithStats = todoProvider.repeatTodos
        .where((rt) => rt.dataStatisticsEnabled)
        .toList();

    if (repeatTodosWithStats.isEmpty) {
      return _buildNoDataView(l10n.noDataForToday);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _DeferredFutureBuilder<_TodayDataResult>(
        cacheKey:
            'today:${todoProvider.statisticsData.length}:${repeatTodosWithStats.length}',
        placeholder: () => _buildTodayLoadingPlaceholder(),
        loader: () => _loadTodayData(todoProvider, repeatTodosWithStats),
        builder: (context, result) {
          if (result.dataByTitle.isEmpty) {
            return SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: _buildNoDataView(l10n.noDataForToday),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...result.dataByTitle.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTodayDataCard(entry.key, entry.value, l10n),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyView(TodoProvider todoProvider, AppLocalizations l10n) {
    final repeatTodosWithStats = todoProvider.repeatTodos
        .where((rt) => rt.dataStatisticsEnabled)
        .toList();

    if (repeatTodosWithStats.isEmpty) {
      return _buildNoDataView(l10n.noDataForThisWeek);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data selector for weekly view
          _buildDataSelector(repeatTodosWithStats, l10n, isWeekly: true),
          const SizedBox(height: 16),
          _DeferredFutureBuilder<_PeriodDataResult>(
            cacheKey:
                'week:${_selectedRepeatTodo?.id ?? 'all'}:${todoProvider.statisticsData.length}',
            placeholder: () =>
                _buildChartLoadingPlaceholder(chartHeight: 220, items: 2),
            loader: () => _loadWeekData(todoProvider, l10n),
            builder: (context, result) {
              if (result.data.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: _buildNoDataView(l10n.noDataForThisWeek),
                );
              }

              return Column(
                children: [
                  if (result.isAllData)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        result.chartTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  _buildWeeklyChart(result.data, l10n),
                  const SizedBox(height: 16),
                  if (result.isAllData &&
                      result.groupedByRepeatTodoId.length > 1)
                    _buildChartLegend(
                      result.groupedByRepeatTodoId,
                      todoProvider,
                      l10n,
                    ),
                  if (result.isAllData)
                    _buildAllWeeklySummary(todoProvider, result.data, l10n)
                  else
                    Column(
                      children: [
                        _buildWeeklySummary(
                          result.data,
                          l10n,
                          _selectedRepeatTodo?.statisticsModes,
                        ),
                        if (_selectedRepeatTodo?.statisticsModes?.contains(
                              StatisticsMode.trend,
                            ) ??
                            true)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildOverallTrendAnalysis(result.data, l10n),
                            ],
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(TodoProvider todoProvider, AppLocalizations l10n) {
    final repeatTodosWithStats = todoProvider.repeatTodos
        .where((rt) => rt.dataStatisticsEnabled)
        .toList();

    if (repeatTodosWithStats.isEmpty) {
      return _buildNoDataView(l10n.noDataForThisMonth);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data selector for monthly view
          _buildDataSelector(repeatTodosWithStats, l10n, isWeekly: false),
          const SizedBox(height: 16),
          _DeferredFutureBuilder<_PeriodDataResult>(
            cacheKey:
                'month:${_selectedRepeatTodo?.id ?? 'all'}:${todoProvider.statisticsData.length}',
            placeholder: () =>
                _buildChartLoadingPlaceholder(chartHeight: 240, items: 2),
            loader: () => _loadMonthData(todoProvider, l10n),
            builder: (context, result) {
              if (result.data.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: _buildNoDataView(l10n.noDataForThisMonth),
                );
              }

              return Column(
                children: [
                  if (result.isAllData)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        result.chartTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  _buildMonthlyChart(result.data, l10n),
                  const SizedBox(height: 16),
                  if (result.isAllData &&
                      result.groupedByRepeatTodoId.length > 1)
                    _buildChartLegend(
                      result.groupedByRepeatTodoId,
                      todoProvider,
                      l10n,
                    ),
                  if (result.isAllData)
                    _buildAllMonthlySummary(todoProvider, result.data, l10n)
                  else
                    Column(
                      children: [
                        _buildMonthlySummary(
                          result.data,
                          l10n,
                          _selectedRepeatTodo?.statisticsModes,
                        ),
                        if (_selectedRepeatTodo?.statisticsModes?.contains(
                              StatisticsMode.trend,
                            ) ??
                            true)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildOverallTrendAnalysis(result.data, l10n),
                            ],
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewView(TodoProvider todoProvider, AppLocalizations l10n) {
    final repeatTodosWithStats = todoProvider.repeatTodos
        .where((rt) => rt.dataStatisticsEnabled)
        .toList();

    if (repeatTodosWithStats.isEmpty) {
      return _buildNoDataView(l10n.noStatisticsData);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data selector for overview view
          _buildDataSelector(repeatTodosWithStats, l10n, isWeekly: false),
          const SizedBox(height: 16),
          _DeferredFutureBuilder<_OverviewDataResult>(
            cacheKey:
                'overview:${_selectedRepeatTodo?.id ?? 'all'}:${_selectedDateRange?.start.millisecondsSinceEpoch ?? 'auto'}:${_selectedDateRange?.end.millisecondsSinceEpoch ?? 'auto'}:${todoProvider.statisticsData.length}',
            placeholder: () =>
                _buildChartLoadingPlaceholder(chartHeight: 240, items: 3),
            loader: () => _loadOverviewData(todoProvider),
            builder: (context, result) {
              if (_selectedDateRange == null && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _selectedDateRange != null) return;
                  setState(() {
                    _selectedDateRange = result.selectedRange;
                  });
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range display
                  _buildDateRangeDisplay(l10n),
                  const SizedBox(height: 16),
                  if (result.data.isEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 300,
                      child: _buildNoDataView(l10n.noStatisticsData),
                    )
                  else ...[
                    _buildOverviewChart(result.data, l10n),
                    const SizedBox(height: 16),
                    if (_selectedRepeatTodo == null)
                      _buildChartLegendForOverview(
                        result.data,
                        todoProvider,
                        l10n,
                      ),
                    _buildOverviewStats(result.data, l10n),
                    if (_selectedRepeatTodo?.statisticsModes?.contains(
                          StatisticsMode.trend,
                        ) ??
                        true)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildTrendAnalysis(result.data, l10n),
                        ],
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLoadingPlaceholder() {
    return Column(
      children: [
        _buildSkeletonCard(height: 140),
        const SizedBox(height: 16),
        _buildSkeletonCard(height: 140),
      ],
    );
  }

  Widget _buildChartLoadingPlaceholder({
    required double chartHeight,
    required int items,
  }) {
    return Column(
      children: [
        _buildSkeletonCard(height: chartHeight),
        const SizedBox(height: 16),
        for (int i = 0; i < items; i++) ...[
          _buildSkeletonCard(height: 72),
          if (i != items - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    final base = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<_TodayDataResult> _loadTodayData(
    TodoProvider provider,
    List<RepeatTodoModel> repeatTodosWithStats,
  ) async {
    final now = _getLocalNow();
    final today = localDay(now);

    final todayData = provider.statisticsData
        .where((d) => isSameLocalDay(d.todoCreatedAt, today))
        .toList();

    final byRepeatTodoId = <String, List<StatisticsDataModel>>{};
    for (final data in todayData) {
      byRepeatTodoId.putIfAbsent(data.repeatTodoId, () => []).add(data);
    }

    final byTitle = <String, List<StatisticsDataModel>>{};
    for (final repeatTodo in repeatTodosWithStats) {
      final data = byRepeatTodoId[repeatTodo.id];
      if (data == null || data.isEmpty) continue;
      data.sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));
      byTitle[repeatTodo.title] = data;
    }

    return _TodayDataResult(byTitle);
  }

  Future<_PeriodDataResult> _loadWeekData(
    TodoProvider provider,
    AppLocalizations l10n,
  ) async {
    final isAllData = _selectedRepeatTodo == null;
    final data = isAllData
        ? _getAllWeekData(provider)
        : _getWeekData(provider, _selectedRepeatTodo!.id);

    final grouped = <String, List<StatisticsDataModel>>{};
    for (final item in data) {
      grouped.putIfAbsent(item.repeatTodoId, () => []).add(item);
    }

    return _PeriodDataResult(
      data: data,
      chartTitle: isAllData ? l10n.allData : _selectedRepeatTodo!.title,
      isAllData: isAllData,
      groupedByRepeatTodoId: grouped,
    );
  }

  Future<_PeriodDataResult> _loadMonthData(
    TodoProvider provider,
    AppLocalizations l10n,
  ) async {
    final isAllData = _selectedRepeatTodo == null;
    final data = isAllData
        ? _getAllMonthData(provider)
        : _getMonthData(provider, _selectedRepeatTodo!.id);

    final grouped = <String, List<StatisticsDataModel>>{};
    for (final item in data) {
      grouped.putIfAbsent(item.repeatTodoId, () => []).add(item);
    }

    return _PeriodDataResult(
      data: data,
      chartTitle: isAllData ? l10n.allData : _selectedRepeatTodo!.title,
      isAllData: isAllData,
      groupedByRepeatTodoId: grouped,
    );
  }

  Future<_OverviewDataResult> _loadOverviewData(TodoProvider provider) async {
    final selectedRange =
        _selectedDateRange ?? _calculateFullDateRange(provider);
    final data = _selectedRepeatTodo == null
        ? _getAllFilteredDataWithRange(provider, selectedRange)
        : _getFilteredDataWithRange(
            provider,
            _selectedRepeatTodo!.id,
            selectedRange,
          );

    return _OverviewDataResult(selectedRange: selectedRange, data: data);
  }

  DateTimeRange _calculateFullDateRange(TodoProvider provider) {
    if (provider.statisticsData.isEmpty) {
      final now = _getLocalNow();
      final day = localDay(now);
      return DateTimeRange(start: day, end: day);
    }

    final earliestDate = provider.statisticsData
        .map((data) => data.todoCreatedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latestDate = provider.statisticsData
        .map((data) => data.todoCreatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return DateTimeRange(
      start: localDay(earliestDate),
      end: localDay(latestDate),
    );
  }

  Widget _buildTodayDataCard(
    String title,
    List<StatisticsDataModel> todayData,
    AppLocalizations l10n,
  ) {
    final total = todayData.fold<double>(0, (sum, data) => sum + data.value);
    final average = todayData.isNotEmpty ? total / todayData.length : 0;
    final unit = todayData.isNotEmpty ? todayData.first.unit : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.data_usage,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.totalValue,
                    '${total.toStringAsFixed(2)}${unit.isNotEmpty ? ' $unit' : ''}',
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.average,
                    '${average.toStringAsFixed(2)}${unit.isNotEmpty ? ' $unit' : ''}',
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.dataPoints,
                    todayData.length.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(
    List<StatisticsDataModel> weekData,
    AppLocalizations l10n,
  ) {
    // Group data by repeat todo for separate lines
    final groupedData = <String, List<StatisticsDataModel>>{};
    for (final data in weekData) {
      groupedData.putIfAbsent(data.repeatTodoId, () => []);
      groupedData[data.repeatTodoId]!.add(data);
    }

    // Create separate line bars for each repeat todo
    final lineBarsData = <LineChartBarData>[];
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.blue,
    ];

    int colorIndex = 0;
    for (final entry in groupedData.entries) {
      // Sort data by todo creation time for proper weekly display
      final sortedData = entry.value
        ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

      // Create spots for each day of the week (Monday to Sunday)
      final weeklySpots = <FlSpot>[];

      // Create a map to store data by day of week
      final dayDataMap = <int, List<StatisticsDataModel>>{};
      for (int i = 0; i < 7; i++) {
        dayDataMap[i] = [];
      }

      // Group data by day of week (0 = Monday, 6 = Sunday)
      for (final data in sortedData) {
        final dayOfWeek =
            data.todoCreatedAt.weekday - 1; // Convert to 0-6 (Monday-Sunday)
        if (dayOfWeek >= 0 && dayOfWeek < 7) {
          dayDataMap[dayOfWeek]!.add(data);
        }
      }

      // Create spots for each day of the week
      for (int day = 0; day < 7; day++) {
        final dayData = dayDataMap[day]!;
        if (dayData.isNotEmpty) {
          // Use the average value if multiple entries exist for the same day
          final averageValue =
              dayData.fold<double>(0, (sum, data) => sum + data.value) /
              dayData.length;
          weeklySpots.add(FlSpot(day.toDouble(), averageValue));
        } else {
          weeklySpots.add(FlSpot(day.toDouble(), 0));
        }
      }

      lineBarsData.add(
        LineChartBarData(
          spots: weeklySpots,
          isCurved: true,
          color: colors[colorIndex % colors.length],
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      );
      colorIndex++;
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = [
                    l10n.mon,
                    l10n.tue,
                    l10n.wed,
                    l10n.thu,
                    l10n.fri,
                    l10n.sat,
                    l10n.sun,
                  ];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(
                      days[value.toInt()],
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() > 0) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBarsData,
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(
    List<StatisticsDataModel> monthData,
    AppLocalizations l10n,
  ) {
    // Group data by repeat todo for separate lines
    final groupedData = <String, List<StatisticsDataModel>>{};
    for (final data in monthData) {
      groupedData.putIfAbsent(data.repeatTodoId, () => []);
      groupedData[data.repeatTodoId]!.add(data);
    }

    // Create separate line bars for each repeat todo
    final lineBarsData = <LineChartBarData>[];
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.blue,
    ];

    // Get current month and year
    final now = _getLocalNow();
    final currentMonth = now.month;
    final currentYear = now.year;
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    int colorIndex = 0;
    for (final entry in groupedData.entries) {
      // Sort data by creation time for proper monthly display
      final sortedData = entry.value
        ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

      // Create spots for each day of the month (1st to end of month)
      final monthlySpots = <FlSpot>[];

      // Initialize all days of the month
      for (int day = 1; day <= daysInMonth; day++) {
        final targetDate = DateTime(currentYear, currentMonth, day);
        final dayData = sortedData
            .where(
              (data) =>
                  isSameLocalDay(data.todoCreatedAt, targetDate),
            )
            .toList();

        if (dayData.isNotEmpty) {
          // Use the average value if multiple entries exist for the same day
          final averageValue =
              dayData.fold<double>(0, (sum, data) => sum + data.value) /
              dayData.length;
          monthlySpots.add(FlSpot(day.toDouble(), averageValue));
        } else {
          monthlySpots.add(FlSpot(day.toDouble(), 0));
        }
      }

      lineBarsData.add(
        LineChartBarData(
          spots: monthlySpots,
          isCurved: true,
          color: colors[colorIndex % colors.length],
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      );
      colorIndex++;
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (day >= 1 && day <= daysInMonth) {
                    // Show labels strategically to avoid crowding
                    if (day == 1 ||
                        day == daysInMonth ||
                        day % 5 == 0 ||
                        daysInMonth <= 15) {
                      return Text(
                        day.toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() > 0) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBarsData,
        ),
      ),
    );
  }

  Widget _buildOverviewChart(
    List<StatisticsDataModel> allData,
    AppLocalizations l10n,
  ) {
    // Group data by repeat todo for separate lines
    final groupedData = <String, List<StatisticsDataModel>>{};
    for (final data in allData) {
      groupedData.putIfAbsent(data.repeatTodoId, () => []);
      groupedData[data.repeatTodoId]!.add(data);
    }

    // Create separate line bars for each repeat todo
    final lineBarsData = <LineChartBarData>[];
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.blue,
    ];

    // Get date range for overview - use the actual data range
    DateTime startDate, endDate;
    if (_selectedDateRange != null) {
      startDate = localDay(_selectedDateRange!.start);
      endDate = localDay(_selectedDateRange!.end);
    } else {
      // If no date range selected, use the actual data range
      if (allData.isNotEmpty) {
        final sortedData = List<StatisticsDataModel>.from(allData)
          ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));
        startDate = localDay(sortedData.first.todoCreatedAt);
        endDate = localDay(sortedData.last.todoCreatedAt);
      } else {
        // Fallback to earliest data available
        endDate = localDay(_getLocalNow());
        startDate = endDate;
      }
    }
    final totalDays = endDate.difference(startDate).inDays + 1;

    int colorIndex = 0;
    for (final entry in groupedData.entries) {
      final sortedData = entry.value
        ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

      // Create spots for each day in the date range
      final overviewSpots = <FlSpot>[];

      for (int dayOffset = 0; dayOffset < totalDays; dayOffset++) {
        final targetDate = startDate.add(Duration(days: dayOffset));
        final dayData = sortedData
            .where(
              (data) =>
                  isSameLocalDay(data.todoCreatedAt, targetDate),
            )
            .toList();

        if (dayData.isNotEmpty) {
          // Use the average value if multiple entries exist for the same day
          final averageValue =
              dayData.fold<double>(0, (sum, data) => sum + data.value) /
              dayData.length;
          overviewSpots.add(FlSpot(dayOffset.toDouble(), averageValue));
        } else {
          overviewSpots.add(FlSpot(dayOffset.toDouble(), 0));
        }
      }

      lineBarsData.add(
        LineChartBarData(
          spots: overviewSpots,
          isCurved: true,
          color: colors[colorIndex % colors.length],
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      );
      colorIndex++;
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final dayOffset = value.toInt();
                  if (dayOffset >= 0 && dayOffset < totalDays) {
                    final currentDate = startDate.add(
                      Duration(days: dayOffset),
                    );
                    // Show date labels strategically to avoid crowding
                    if (dayOffset == 0 ||
                        dayOffset == totalDays - 1 ||
                        dayOffset % 5 == 0 ||
                        (totalDays <= 20 && dayOffset % 3 == 0) ||
                        (totalDays <= 10)) {
                      return Transform.rotate(
                        angle: -45 * 3.14159 / 180,
                        child: Text(
                          '${currentDate.month}/${currentDate.day}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
                reservedSize: 50,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() > 0) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBarsData,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildNoDataView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Data retrieval methods

  List<StatisticsDataModel> _getWeekData(
    TodoProvider provider,
    String repeatTodoId,
  ) {
    final now = _getLocalNow();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    ); // 本周周一
    final weekEnd = now; // 到今天为止

    return provider.statisticsData
        .where(
          (data) =>
              data.repeatTodoId == repeatTodoId &&
              data.todoCreatedAt.isAfter(
                weekStart.subtract(const Duration(days: 1)),
              ) &&
              data.todoCreatedAt.isBefore(weekEnd.add(const Duration(days: 1))),
        )
        .toList()
      ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));
  }

  List<StatisticsDataModel> _getAllWeekData(TodoProvider provider) {
    final now = _getLocalNow();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    ); // 本周周一
    final weekEnd = now; // 到今天为止

    return provider.statisticsData
        .where(
          (data) =>
              data.todoCreatedAt.isAfter(
                weekStart.subtract(const Duration(days: 1)),
              ) &&
              data.todoCreatedAt.isBefore(weekEnd.add(const Duration(days: 1))),
        )
        .toList()
      ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));
  }

  List<StatisticsDataModel> _getMonthData(
    TodoProvider provider,
    String repeatTodoId,
  ) {
    final now = _getLocalNow();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = now; // 到今天为止

    return provider.statisticsData
        .where(
          (data) =>
              data.repeatTodoId == repeatTodoId &&
              data.todoCreatedAt.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              data.todoCreatedAt.isBefore(
                monthEnd.add(const Duration(days: 1)),
              ),
        )
        .toList()
      ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));
  }

  List<StatisticsDataModel> _getAllMonthData(TodoProvider provider) {
    final now = _getLocalNow();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = now; // 到今天为止

    return provider.statisticsData
        .where(
          (data) =>
              data.todoCreatedAt.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              data.todoCreatedAt.isBefore(
                monthEnd.add(const Duration(days: 1)),
              ),
        )
        .toList()
      ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));
  }

  Widget _buildWeeklySummary(
    List<StatisticsDataModel> weekData,
    AppLocalizations l10n,
    List<StatisticsMode>? selectedModes,
  ) {
    if (weekData.isEmpty) return const SizedBox.shrink();

    // Use default modes if none selected
    final modes =
        selectedModes ??
        [
          StatisticsMode.sum,
          StatisticsMode.average,
          StatisticsMode.growth,
          StatisticsMode.trend,
        ];

    final total = weekData.fold<double>(0, (sum, item) => sum + item.value);
    final average = total / weekData.length;

    // Calculate min/max for extremum mode
    final values = weekData.map((d) => d.value).toList();
    final min = values.isNotEmpty
        ? values.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final max = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Build stat items based on selected modes
    final mainStatItems = <Widget>[]; // 平均值、极值、总计

    // Calculate growth and trend if needed
    double? growthValue;
    String? trendAnalysis;

    if (modes.contains(StatisticsMode.growth) ||
        modes.contains(StatisticsMode.trend)) {
      final sortedData = List<StatisticsDataModel>.from(weekData)
        ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

      if (sortedData.length >= 2) {
        // Calculate total growth (difference between last and first value)
        growthValue = sortedData.last.value - sortedData.first.value;

        // Calculate trend using linear regression analysis
        if (modes.contains(StatisticsMode.trend)) {
          trendAnalysis = _calculateTrendAnalysis(sortedData);
        }
      }
    }

    final trendItem =
        modes.contains(StatisticsMode.trend) && trendAnalysis != null
        ? _buildStatItem(l10n.trend, trendAnalysis, Colors.purple)
        : null;
    final growthItem =
        modes.contains(StatisticsMode.growth) && growthValue != null
        ? _buildStatItem(
            l10n.growth,
            growthValue.toStringAsFixed(2),
            Colors.teal,
          )
        : null;

    // Build main statistics items (平均、极值、总计)
    if (modes.contains(StatisticsMode.sum)) {
      mainStatItems.add(
        _buildStatItem(
          l10n.total,
          total.toStringAsFixed(2),
          AppTheme.primaryColor,
        ),
      );
    }

    if (modes.contains(StatisticsMode.average)) {
      mainStatItems.add(
        _buildStatItem(
          l10n.average,
          average.toStringAsFixed(2),
          AppTheme.secondaryColor,
        ),
      );
    }

    if (modes.contains(StatisticsMode.extremum)) {
      mainStatItems.add(
        _buildStatItem(
          '${l10n.min}/${l10n.max}',
          '${min.toStringAsFixed(2)}/${max.toStringAsFixed(2)}',
          Colors.orange,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main statistics row (平均、极值、总计) - 平分宽度
            if (mainStatItems.isNotEmpty)
              Row(
                children: mainStatItems
                    .map((item) => Expanded(child: item))
                    .toList(),
              ),

            // Growth and Trend row (增长和趋势在同一行)
            if (growthItem != null || trendItem != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (growthItem != null) Expanded(child: growthItem),
                  if (growthItem != null && trendItem != null)
                    const SizedBox(width: 8),
                  if (trendItem != null) Expanded(child: trendItem),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(
    List<StatisticsDataModel> monthData,
    AppLocalizations l10n,
    List<StatisticsMode>? selectedModes,
  ) {
    if (monthData.isEmpty) return const SizedBox.shrink();

    // Use default modes if none selected
    final modes =
        selectedModes ??
        [
          StatisticsMode.sum,
          StatisticsMode.average,
          StatisticsMode.growth,
          StatisticsMode.trend,
        ];

    final total = monthData.fold<double>(0, (sum, item) => sum + item.value);
    final average = total / monthData.length;

    // Calculate min/max for extremum mode
    final values = monthData.map((d) => d.value).toList();
    final min = values.isNotEmpty
        ? values.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final max = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Build stat items based on selected modes
    final mainStatItems = <Widget>[]; // 平均值、极值、总计

    // Calculate growth and trend if needed
    double? growthValue;
    String? trendAnalysis;

    if (modes.contains(StatisticsMode.growth) ||
        modes.contains(StatisticsMode.trend)) {
      final sortedData = List<StatisticsDataModel>.from(monthData)
        ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

      if (sortedData.length >= 2) {
        // Calculate total growth (difference between last and first value)
        growthValue = sortedData.last.value - sortedData.first.value;

        // Calculate trend using linear regression analysis
        if (modes.contains(StatisticsMode.trend)) {
          trendAnalysis = _calculateTrendAnalysis(sortedData);
        }
      }
    }

    final trendItem =
        modes.contains(StatisticsMode.trend) && trendAnalysis != null
        ? _buildStatItem(l10n.trend, trendAnalysis, Colors.purple)
        : null;
    final growthItem =
        modes.contains(StatisticsMode.growth) && growthValue != null
        ? _buildStatItem(
            l10n.growth,
            growthValue.toStringAsFixed(2),
            Colors.teal,
          )
        : null;

    // Build main statistics items (平均、极值、总计)
    if (modes.contains(StatisticsMode.sum)) {
      mainStatItems.add(
        _buildStatItem(
          l10n.total,
          total.toStringAsFixed(2),
          AppTheme.primaryColor,
        ),
      );
    }

    if (modes.contains(StatisticsMode.average)) {
      mainStatItems.add(
        _buildStatItem(
          l10n.average,
          average.toStringAsFixed(2),
          AppTheme.secondaryColor,
        ),
      );
    }

    if (modes.contains(StatisticsMode.extremum)) {
      mainStatItems.add(
        _buildStatItem(
          '${l10n.min}/${l10n.max}',
          '${min.toStringAsFixed(2)}/${max.toStringAsFixed(2)}',
          Colors.orange,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main statistics row (平均、极值、总计) - 平分宽度
            if (mainStatItems.isNotEmpty)
              Row(
                children: mainStatItems
                    .map((item) => Expanded(child: item))
                    .toList(),
              ),

            // Growth and Trend row (增长和趋势在同一行)
            if (growthItem != null || trendItem != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (growthItem != null) Expanded(child: growthItem),
                  if (growthItem != null && trendItem != null)
                    const SizedBox(width: 8),
                  if (trendItem != null) Expanded(child: trendItem),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllWeeklySummary(
    TodoProvider provider,
    List<StatisticsDataModel> allWeekData,
    AppLocalizations l10n,
  ) {
    if (allWeekData.isEmpty) return const SizedBox.shrink();

    // Group data by repeat todo for individual summaries
    final groupedData = <String, List<StatisticsDataModel>>{};
    for (final data in allWeekData) {
      groupedData.putIfAbsent(data.repeatTodoId, () => []);
      groupedData[data.repeatTodoId]!.add(data);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.breakdownByTask,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...groupedData.entries.map((entry) {
              final repeatTodo = provider.repeatTodos.firstWhere(
                (rt) => rt.id == entry.key,
                orElse: () => RepeatTodoModel.create(
                  title: l10n.unknown,
                  repeatType: RepeatType.daily,
                ),
              );
              final taskData = entry.value;
              final taskTotal = taskData.fold<double>(
                0,
                (sum, item) => sum + item.value,
              );
              final taskAverage = taskData.isNotEmpty
                  ? taskTotal / taskData.length
                  : 0;
              final taskUnit = repeatTodo.dataUnit ?? '';

              // Get the selected modes for this task
              final selectedModes = repeatTodo.statisticsModes;

              // Calculate min/max for extremum mode
              final values = taskData.map((d) => d.value).toList();
              final min = values.isNotEmpty
                  ? values.reduce((a, b) => a < b ? a : b)
                  : 0.0;
              final max = values.isNotEmpty
                  ? values.reduce((a, b) => a > b ? a : b)
                  : 0.0;

              // Build stat items based on selected modes
              final mainStatItems = <Widget>[]; // 平均值、极值、总计

              // Calculate growth and trend if needed
              double? growthValue;
              String? trendAnalysis;

              if (selectedModes != null &&
                  (selectedModes.contains(StatisticsMode.growth) ||
                      selectedModes.contains(StatisticsMode.trend))) {
                final sortedData = List<StatisticsDataModel>.from(taskData)
                  ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

                if (sortedData.length >= 2) {
                  // Calculate total growth (difference between last and first value)
                  growthValue = sortedData.last.value - sortedData.first.value;

                  // Calculate trend using linear regression analysis
                  if (selectedModes.contains(StatisticsMode.trend)) {
                    trendAnalysis = _calculateTrendAnalysis(sortedData);
                  }
                }
              }

              final trendItem =
                  (selectedModes != null &&
                          selectedModes.contains(StatisticsMode.trend)) &&
                      trendAnalysis != null
                  ? _buildMiniStatItem(l10n.trend, trendAnalysis, Colors.purple)
                  : null;
              final growthItem =
                  (selectedModes != null &&
                          selectedModes.contains(StatisticsMode.growth)) &&
                      growthValue != null
                  ? _buildMiniStatItem(
                      l10n.growth,
                      growthValue.toStringAsFixed(2),
                      Colors.teal,
                    )
                  : null;

              // Build main statistics items (平均、极值、总计)
              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.sum)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    l10n.total,
                    '${taskTotal.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    AppTheme.primaryColor,
                  ),
                );
              }

              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.average)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    l10n.average,
                    '${taskAverage.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    AppTheme.secondaryColor,
                  ),
                );
              }

              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.extremum)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    '${l10n.min}/${l10n.max}',
                    '${min.toStringAsFixed(2)}/${max.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    Colors.orange,
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repeatTodo.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    // Main statistics row (平均、极值、总计) - 平分宽度
                    if (mainStatItems.isNotEmpty)
                      Row(
                        children: mainStatItems
                            .map((item) => Expanded(child: item))
                            .toList(),
                      ),

                    // Growth and Trend row (增长和趋势在同一行)
                    if (growthItem != null || trendItem != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (growthItem != null) Expanded(child: growthItem),
                          if (growthItem != null && trendItem != null)
                            const SizedBox(width: 8),
                          if (trendItem != null) Expanded(child: trendItem),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAllMonthlySummary(
    TodoProvider provider,
    List<StatisticsDataModel> allMonthData,
    AppLocalizations l10n,
  ) {
    if (allMonthData.isEmpty) return const SizedBox.shrink();

    // Group data by repeat todo for individual summaries
    final groupedData = <String, List<StatisticsDataModel>>{};
    for (final data in allMonthData) {
      groupedData.putIfAbsent(data.repeatTodoId, () => []);
      groupedData[data.repeatTodoId]!.add(data);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.breakdownByTask,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...groupedData.entries.map((entry) {
              final repeatTodo = provider.repeatTodos.firstWhere(
                (rt) => rt.id == entry.key,
                orElse: () => RepeatTodoModel.create(
                  title: l10n.unknown,
                  repeatType: RepeatType.daily,
                ),
              );
              final taskData = entry.value;
              final taskTotal = taskData.fold<double>(
                0,
                (sum, item) => sum + item.value,
              );
              final taskAverage = taskData.isNotEmpty
                  ? taskTotal / taskData.length
                  : 0;
              final taskUnit = repeatTodo.dataUnit ?? '';

              // Get the selected modes for this task
              final selectedModes = repeatTodo.statisticsModes;

              // Calculate min/max for extremum mode
              final values = taskData.map((d) => d.value).toList();
              final min = values.isNotEmpty
                  ? values.reduce((a, b) => a < b ? a : b)
                  : 0.0;
              final max = values.isNotEmpty
                  ? values.reduce((a, b) => a > b ? a : b)
                  : 0.0;

              // Build stat items based on selected modes
              final mainStatItems = <Widget>[]; // 平均值、极值、总计

              // Calculate growth and trend if needed
              double? growthValue;
              String? trendAnalysis;

              if (selectedModes != null &&
                  (selectedModes.contains(StatisticsMode.growth) ||
                      selectedModes.contains(StatisticsMode.trend))) {
                final sortedData = List<StatisticsDataModel>.from(taskData)
                  ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

                if (sortedData.length >= 2) {
                  // Calculate total growth (difference between last and first value)
                  growthValue = sortedData.last.value - sortedData.first.value;

                  // Calculate trend using linear regression analysis
                  if (selectedModes.contains(StatisticsMode.trend)) {
                    trendAnalysis = _calculateTrendAnalysis(sortedData);
                  }
                }
              }

              final trendItem =
                  (selectedModes != null &&
                          selectedModes.contains(StatisticsMode.trend)) &&
                      trendAnalysis != null
                  ? _buildMiniStatItem(l10n.trend, trendAnalysis, Colors.purple)
                  : null;
              final growthItem =
                  (selectedModes != null &&
                          selectedModes.contains(StatisticsMode.growth)) &&
                      growthValue != null
                  ? _buildMiniStatItem(
                      l10n.growth,
                      growthValue.toStringAsFixed(2),
                      Colors.teal,
                    )
                  : null;

              // Build main statistics items (平均、极值、总计)
              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.sum)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    l10n.total,
                    '${taskTotal.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    AppTheme.primaryColor,
                  ),
                );
              }

              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.average)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    l10n.average,
                    '${taskAverage.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    AppTheme.secondaryColor,
                  ),
                );
              }

              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.extremum)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    '${l10n.min}/${l10n.max}',
                    '${min.toStringAsFixed(2)}/${max.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    Colors.orange,
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repeatTodo.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    // Main statistics row (平均、极值、总计) - 平分宽度
                    if (mainStatItems.isNotEmpty)
                      Row(
                        children: mainStatItems
                            .map((item) => Expanded(child: item))
                            .toList(),
                      ),

                    // Growth and Trend row (增长和趋势在同一行)
                    if (growthItem != null || trendItem != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (growthItem != null) Expanded(child: growthItem),
                          if (growthItem != null && trendItem != null)
                            const SizedBox(width: 8),
                          if (trendItem != null) Expanded(child: trendItem),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStats(
    List<StatisticsDataModel> allData,
    AppLocalizations l10n,
  ) {
    if (allData.isEmpty) return const SizedBox.shrink();

    // Group data by repeat todo for individual summaries
    final groupedData = <String, List<StatisticsDataModel>>{};
    for (final data in allData) {
      groupedData.putIfAbsent(data.repeatTodoId, () => []);
      groupedData[data.repeatTodoId]!.add(data);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.breakdownByTask,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...groupedData.entries.map((entry) {
              final repeatTodo =
                  Provider.of<TodoProvider>(
                    context,
                    listen: false,
                  ).repeatTodos.firstWhere(
                    (rt) => rt.id == entry.key,
                    orElse: () => RepeatTodoModel.create(
                      title: l10n.unknown,
                      repeatType: RepeatType.daily,
                    ),
                  );
              final taskData = entry.value;
              final taskTotal = taskData.fold<double>(
                0,
                (sum, item) => sum + item.value,
              );
              final taskAverage = taskData.isNotEmpty
                  ? taskTotal / taskData.length
                  : 0;
              final taskUnit = repeatTodo.dataUnit ?? '';

              // Get the selected modes for this task
              final selectedModes = repeatTodo.statisticsModes;

              // Calculate min/max for extremum mode
              final values = taskData.map((d) => d.value).toList();
              final min = values.isNotEmpty
                  ? values.reduce((a, b) => a < b ? a : b)
                  : 0.0;
              final max = values.isNotEmpty
                  ? values.reduce((a, b) => a > b ? a : b)
                  : 0.0;

              // Build stat items based on selected modes
              final mainStatItems = <Widget>[]; // 平均值、极值、总计

              // Calculate growth and trend if needed
              double? growthValue;
              String? trendAnalysis;

              if (selectedModes != null &&
                  (selectedModes.contains(StatisticsMode.growth) ||
                      selectedModes.contains(StatisticsMode.trend))) {
                final sortedData = List<StatisticsDataModel>.from(taskData)
                  ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

                if (sortedData.length >= 2) {
                  // Calculate total growth (difference between last and first value)
                  growthValue = sortedData.last.value - sortedData.first.value;

                  // Calculate trend using linear regression analysis
                  if (selectedModes.contains(StatisticsMode.trend)) {
                    trendAnalysis = _calculateTrendAnalysis(sortedData);
                  }
                }
              }

              final trendItem =
                  (selectedModes != null &&
                          selectedModes.contains(StatisticsMode.trend)) &&
                      trendAnalysis != null
                  ? _buildMiniStatItem(l10n.trend, trendAnalysis, Colors.purple)
                  : null;
              final growthItem =
                  (selectedModes != null &&
                          selectedModes.contains(StatisticsMode.growth)) &&
                      growthValue != null
                  ? _buildMiniStatItem(
                      l10n.growth,
                      growthValue.toStringAsFixed(2),
                      Colors.teal,
                    )
                  : null;

              // Build main statistics items (平均、极值、总计)
              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.sum)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    l10n.total,
                    '${taskTotal.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    AppTheme.primaryColor,
                  ),
                );
              }

              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.average)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    l10n.average,
                    '${taskAverage.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    AppTheme.secondaryColor,
                  ),
                );
              }

              if (selectedModes != null &&
                  selectedModes.contains(StatisticsMode.extremum)) {
                mainStatItems.add(
                  _buildMiniStatItem(
                    '${l10n.min}/${l10n.max}',
                    '${min.toStringAsFixed(2)}/${max.toStringAsFixed(2)}${taskUnit.isNotEmpty ? ' $taskUnit' : ''}',
                    Colors.orange,
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repeatTodo.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    // Main statistics row (平均、极值、总计) - 平分宽度
                    if (mainStatItems.isNotEmpty)
                      Row(
                        children: mainStatItems
                            .map((item) => Expanded(child: item))
                            .toList(),
                      ),

                    // Growth and Trend row (增长和趋势在同一行)
                    if (growthItem != null || trendItem != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (growthItem != null) Expanded(child: growthItem),
                          if (growthItem != null && trendItem != null)
                            const SizedBox(width: 8),
                          if (trendItem != null) Expanded(child: trendItem),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis(
    List<StatisticsDataModel> allData,
    AppLocalizations l10n,
  ) {
    if (allData.length < 2) return const SizedBox.shrink();

    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        // Group data by repeat todo for individual trend analysis
        final groupedData = <String, List<StatisticsDataModel>>{};
        for (final data in allData) {
          groupedData.putIfAbsent(data.repeatTodoId, () => []);
          groupedData[data.repeatTodoId]!.add(data);
        }

        // If this is "all data" view (multiple data types), show individual trends
        if (groupedData.length > 1) {
          return _buildIndividualTrendAnalysis(groupedData, todoProvider, l10n);
        } else {
          // Single data type, show overall trend
          return _buildOverallTrendAnalysis(allData, l10n);
        }
      },
    );
  }

  /// Calculate trend analysis using linear regression
  String _calculateTrendAnalysis(List<StatisticsDataModel> sortedData) {
    final l10n = AppLocalizations.of(context)!;
    if (sortedData.length < 2) return l10n.insufficientData;

    // Simple linear regression: y = mx + b
    // Where x is time index, y is value
    // Note: sortedData is in chronological order (oldest first, newest last)
    final n = sortedData.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble(); // Time index (0 = oldest, n-1 = newest)
      final y = sortedData[i].value;

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    // Calculate slope (m)
    final numerator = n * sumXY - sumX * sumY;
    final denominator = n * sumX2 - sumX * sumX;

    if (denominator == 0) return l10n.stable;

    final slope = numerator / denominator;

    // Calculate correlation coefficient (r) for trend strength
    final meanX = sumX / n;
    final meanY = sumY / n;

    double ssX = 0;
    double ssY = 0;
    double ssXY = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = sortedData[i].value;
      final deltaX = x - meanX;
      final deltaY = y - meanY;

      ssX += deltaX * deltaX;
      ssY += deltaY * deltaY;
      ssXY += deltaX * deltaY;
    }

    final r = ssXY / math.sqrt(ssX * ssY);

    // Determine trend based on slope and correlation strength
    final strength = r.abs();

    if (strength < 0.3) {
      return l10n.stable;
    } else if (slope > 0) {
      if (strength > 0.7) {
        return l10n.strongUpward;
      } else {
        return l10n.upward;
      }
    } else {
      if (strength > 0.7) {
        return l10n.strongDownward;
      } else {
        return l10n.downward;
      }
    }
  }

  Widget _buildOverallTrendAnalysis(
    List<StatisticsDataModel> allData,
    AppLocalizations l10n,
  ) {
    if (allData.length < 2) return const SizedBox.shrink();

    // Sort data by todo creation date to ensure correct chronological order for trend analysis
    final sortedData = List<StatisticsDataModel>.from(allData)
      ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

    // Calculate total growth (difference between last and first value)
    final totalGrowth = sortedData.last.value - sortedData.first.value;

    // Calculate trend analysis using linear regression
    final trendAnalysis = _calculateTrendAnalysis(sortedData);

    // Determine color based on trend analysis
    Color trendColor;
    if (trendAnalysis.contains('上升')) {
      trendColor = Colors.green;
    } else if (trendAnalysis.contains('下降')) {
      trendColor = Colors.red;
    } else {
      trendColor = Colors.orange;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.trendAnalysis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.totalGrowth,
                    totalGrowth.toStringAsFixed(2),
                    trendColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(l10n.trend, trendAnalysis, trendColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualTrendAnalysis(
    Map<String, List<StatisticsDataModel>> groupedData,
    TodoProvider todoProvider,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.trendAnalysis} - ${l10n.allData}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...groupedData.entries.map((entry) {
              final repeatTodo = todoProvider.repeatTodos.firstWhere(
                (rt) => rt.id == entry.key,
                orElse: () => RepeatTodoModel.create(
                  title: l10n.unknown,
                  repeatType: RepeatType.daily,
                ),
              );

              return _buildSingleTrendCard(repeatTodo.title, entry.value, l10n);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleTrendCard(
    String title,
    List<StatisticsDataModel> data,
    AppLocalizations l10n,
  ) {
    if (data.length < 2) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.needMoreDataToAnalyze,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Sort data by todo creation date to ensure correct chronological order for trend analysis
    final sortedData = List<StatisticsDataModel>.from(data)
      ..sort((a, b) => a.todoCreatedAt.compareTo(b.todoCreatedAt));

    // Calculate total growth (difference between last and first value)
    final totalGrowth = sortedData.last.value - sortedData.first.value;

    // Calculate trend analysis using linear regression
    final trendAnalysis = _calculateTrendAnalysis(sortedData);

    // Determine color and icon based on trend analysis
    Color trendColor;
    IconData trendIcon;

    if (trendAnalysis.contains('上升')) {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
    } else if (trendAnalysis.contains('下降')) {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    } else {
      trendColor = Colors.orange;
      trendIcon = Icons.trending_flat;
    }

    final unit = data.isNotEmpty ? data.first.unit : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatItem(
                  l10n.totalGrowth,
                  '${totalGrowth.toStringAsFixed(2)}${unit.isNotEmpty ? ' $unit' : ''}',
                  trendColor,
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trendAnalysis,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildChartLegend(
    Map<String, List<StatisticsDataModel>> groupedData,
    TodoProvider todoProvider,
    AppLocalizations l10n,
  ) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.blue,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('数据源', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: groupedData.entries.map((entry) {
              final repeatTodo = todoProvider.repeatTodos.firstWhere(
                (rt) => rt.id == entry.key,
                orElse: () => RepeatTodoModel.create(
                  title: l10n.unknown,
                  repeatType: RepeatType.daily,
                ),
              );
              final colorIndex = groupedData.keys.toList().indexOf(entry.key);
              final color = colors[colorIndex % colors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    repeatTodo.title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendForOverview(
    List<StatisticsDataModel> allData,
    TodoProvider todoProvider,
    AppLocalizations l10n,
  ) {
    // Group data by repeat todo
    final groupedData = <String, List<StatisticsDataModel>>{};
    for (final data in allData) {
      groupedData.putIfAbsent(data.repeatTodoId, () => []);
      groupedData[data.repeatTodoId]!.add(data);
    }

    // Only show legend if there are multiple data sources
    if (groupedData.length <= 1) {
      return const SizedBox.shrink();
    }

    return _buildChartLegend(groupedData, todoProvider, l10n);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _getLocalNow(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _getDateRangeDisplay(AppLocalizations l10n) {
    if (_selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} ~ ${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    }
    return l10n.customDateRange;
  }

  List<StatisticsDataModel> _getFilteredDataWithRange(
    TodoProvider provider,
    String repeatTodoId,
    DateTimeRange range,
  ) {
    return provider.statisticsData
        .where(
          (data) =>
              data.repeatTodoId == repeatTodoId &&
              data.todoCreatedAt.isAfter(
                range.start.subtract(const Duration(days: 1)),
              ) &&
              data.todoCreatedAt.isBefore(
                range.end.add(const Duration(days: 1)),
              ),
        )
        .toList();
  }

  List<StatisticsDataModel> _getAllFilteredDataWithRange(
    TodoProvider provider,
    DateTimeRange range,
  ) {
    return provider.statisticsData
        .where(
          (data) =>
              data.todoCreatedAt.isAfter(
                range.start.subtract(const Duration(days: 1)),
              ) &&
              data.todoCreatedAt.isBefore(
                range.end.add(const Duration(days: 1)),
              ),
        )
        .toList();
  }

  Widget _buildDateRangeDisplay(AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _selectDateRange,
      icon: Icon(
        Icons.date_range,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      label: Text(
        _getDateRangeDisplay(l10n),
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _DeferredFutureBuilder<T> extends StatefulWidget {
  final String cacheKey;
  final Future<T> Function() loader;
  final Widget Function() placeholder;
  final Widget Function(BuildContext context, T result) builder;

  const _DeferredFutureBuilder({
    required this.cacheKey,
    required this.loader,
    required this.placeholder,
    required this.builder,
  });

  @override
  State<_DeferredFutureBuilder<T>> createState() =>
      _DeferredFutureBuilderState<T>();
}

class _DeferredFutureBuilderState<T> extends State<_DeferredFutureBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = _createFuture();
  }

  @override
  void didUpdateWidget(covariant _DeferredFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _future = _createFuture();
    }
  }

  Future<T> _createFuture() async {
    await SchedulerBinding.instance.endOfFrame;
    return widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || data == null) {
          return widget.placeholder();
        }
        return widget.builder(context, data);
      },
    );
  }
}

class _TodayDataResult {
  final Map<String, List<StatisticsDataModel>> dataByTitle;

  const _TodayDataResult(this.dataByTitle);
}

class _PeriodDataResult {
  final List<StatisticsDataModel> data;
  final String chartTitle;
  final bool isAllData;
  final Map<String, List<StatisticsDataModel>> groupedByRepeatTodoId;

  const _PeriodDataResult({
    required this.data,
    required this.chartTitle,
    required this.isAllData,
    required this.groupedByRepeatTodoId,
  });
}

class _OverviewDataResult {
  final DateTimeRange selectedRange;
  final List<StatisticsDataModel> data;

  const _OverviewDataResult({required this.selectedRange, required this.data});
}
