import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/providers/pomodoro_provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/screens/data_statistics_screen.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';

// 数据统计按钮的内容组件
class _DataStatsButtonContent extends StatelessWidget {
  final TodoProvider todoProvider;
  final AppLocalizations l10n;
  final TabController tabController;

  const _DataStatsButtonContent({
    required Key key,
    required this.todoProvider,
    required this.l10n,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          String? navigationSource;
          switch (tabController.index) {
            case 0:
              navigationSource = 'today';
              break;
            case 1:
              navigationSource = 'thisWeek';
              break;
            case 2:
              navigationSource = 'thisMonth';
              break;
            case 3:
              navigationSource = 'overview';
              break;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DataStatisticsScreen(
                navigationSource: navigationSource,
              ),
            ),
          );
        },
        icon: const Icon(Icons.analytics),
        label: Text(l10n.dataStatisticsTab),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0; // 跟踪当前实际显示的标签页

  // Get message color based on completion rate
  Color _getMessageColor(double completionRate) {
    if (completionRate >= 80) return Colors.green;
    if (completionRate >= 60) return Colors.blue;
    if (completionRate >= 40) return Colors.orange;
    if (completionRate >= 20) return Colors.deepOrange;
    return Colors.purple;
  }

  // 检查重复任务是否应该在今天生成
  bool _shouldGenerateForToday(RepeatTodoModel repeatTodo, DateTime currentDate) {
    // 使用本地时间进行判断
    final today = DateTime(currentDate.year, currentDate.month, currentDate.day);

    // 检查是否已过开始日期
    if (repeatTodo.startDate != null) {
      final startDate = DateTime(repeatTodo.startDate!.year, repeatTodo.startDate!.month, repeatTodo.startDate!.day);
      if (today.isBefore(startDate)) {
        return false;
      }
    }

    // 检查是否已过结束日期
    if (repeatTodo.endDate != null) {
      final endDate = DateTime(repeatTodo.endDate!.year, repeatTodo.endDate!.month, repeatTodo.endDate!.day);
      if (today.isAfter(endDate)) {
        return false;
      }
    }

    // 根据重复类型检查是否应该在今天生成
    switch (repeatTodo.repeatType) {
      case RepeatType.daily:
        return true; // 每天都生成

      case RepeatType.weekly:
        if (repeatTodo.weekDays == null || repeatTodo.weekDays!.isEmpty) return false;
        // 使用本地时间的星期几进行判断
        return repeatTodo.weekDays!.contains(currentDate.weekday);

      case RepeatType.monthly:
        if (repeatTodo.dayOfMonth == null) return false;

        // 检查今天是否是指定的日期
        if (today.day == repeatTodo.dayOfMonth) {
          return true;
        }

        // 如果指定的日期超过了本月的最大天数，则在本月的最后一天生成
        final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;
        if (repeatTodo.dayOfMonth! > lastDayOfMonth && today.day == lastDayOfMonth) {
          return true;
        }

        return false;

      case RepeatType.weekdays:
        return currentDate.weekday <= 5; // 周一到周五
    }
  }

  // 获取本地时间的辅助方法
  DateTime _getLocalNow() {
    try {
      tz.initializeTimeZones();

      // 使用更完整的时区检测逻辑
      final localTimeZoneName = DateTime.now().timeZoneName;
      String? timeZoneId;

      if (localTimeZoneName.contains('CST') || localTimeZoneName.contains('GMT+8') || localTimeZoneName.contains('UTC+8')) {
        timeZoneId = 'Asia/Shanghai';
      } else if (localTimeZoneName.contains('PST') || localTimeZoneName.contains('GMT-8')) {
        timeZoneId = 'America/Los_Angeles';
      } else if (localTimeZoneName.contains('EST') || localTimeZoneName.contains('GMT-5')) {
        timeZoneId = 'America/New_York';
      } else if (localTimeZoneName.contains('JST') || localTimeZoneName.contains('GMT+9')) {
        timeZoneId = 'Asia/Tokyo';
      } else if (localTimeZoneName.contains('GMT')) {
        final offset = DateTime.now().timeZoneOffset.inHours;
        if (offset == 8) {
          timeZoneId = 'Asia/Shanghai';
        } else if (offset == 9) {
          timeZoneId = 'Asia/Tokyo';
        } else if (offset == -5) {
          timeZoneId = 'America/New_York';
        } else if (offset == -8) {
          timeZoneId = 'America/Los_Angeles';
        }
      }

      if (timeZoneId != null) {
        try {
          final location = tz.getLocation(timeZoneId);
          tz.setLocalLocation(location);
          // debugPrint('StatisticsScreen: Set timezone to $timeZoneId');
        } catch (e) {
          debugPrint('StatisticsScreen: Failed to set timezone: $e');
        }
      }

      return tz.TZDateTime.now(tz.local);
    } catch (e) {
      debugPrint('StatisticsScreen: Timezone initialization failed: $e');
      return DateTime.now();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    if (_tabController.animation != null) {
      _tabController.animation!.removeListener(_onAnimationChanged);
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // 监听所有标签页变化，包括点击切换和滑动切换
    // TabController的animation在滑动时会发生变化，我们可以据此判断当前的目标页面
    if (_tabController.animation != null) {
      _tabController.animation!.addListener(_onAnimationChanged);
    }

    // 立即更新当前标签页索引
    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _onAnimationChanged() {
    // 根据动画进度计算当前的目标页面索引
    if (_tabController.animation != null) {
      final animationValue = _tabController.animation!.value;
      final targetIndex = animationValue.round();

      if (targetIndex != _currentTabIndex) {
        setState(() {
          _currentTabIndex = targetIndex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<TodoProvider, PomodoroProvider>(
      builder: (context, todoProvider, pomodoroProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.stats),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.today),
                Tab(text: l10n.thisWeek),
                Tab(text: l10n.thisMonth),
                Tab(text: l10n.overview),
              ],
            ),
          ),
          body: Column(
            children: [
              // Data Statistics button will be moved to bottom

              // Main content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailyView(todoProvider, pomodoroProvider),
                    _buildWeeklyView(todoProvider, pomodoroProvider),
                    _buildMonthlyView(todoProvider, pomodoroProvider),
                    _buildOverviewView(todoProvider, pomodoroProvider),
                  ],
                ),
              ),

              // Data Statistics button at bottom
              _buildDataStatsButton(todoProvider, l10n),
            ],
          ),
        );
      },
    );
  }

  
  Widget _buildDataStatsButton(TodoProvider todoProvider, AppLocalizations l10n) {
    final repeatTodosWithStats = todoProvider.repeatTodos
        .where((rt) => rt.dataStatisticsEnabled)
        .toList();

    // 判断是否应该显示按钮
    final shouldShowButton = repeatTodosWithStats.isNotEmpty && _currentTabIndex != 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 使用向下滑动动画
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1.0), // 从下方开始
          end: Offset.zero, // 到正常位置
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ));

        // 使用淡入淡出动画
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: shouldShowButton
          ? _DataStatsButtonContent(
              key: const ValueKey('dataStatsButton'),
              todoProvider: todoProvider,
              l10n: l10n,
              tabController: _tabController,
            )
          : const SizedBox.shrink(key: ValueKey('emptySpace')),
    );
  }

Widget _buildDailyView(
    TodoProvider todoProvider,
    PomodoroProvider pomodoroProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final todayStats = _getTodayStats(todoProvider);
    final todayPomodoroStats = _getTodayPomodoroStats(pomodoroProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todayProgress,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAIIncentiveMessage(todayStats, l10n),
          const SizedBox(height: 16),
          _buildSummaryCard(l10n.today, todayStats, l10n),
          const SizedBox(height: 16),
          _buildPomodoroStatsCard(todayPomodoroStats, l10n),
          const SizedBox(height: 16),
          _buildDataEntryProgressCard(todoProvider, l10n),
        ],
      ),
    );
  }

  Widget _buildWeeklyView(
    TodoProvider todoProvider,
    PomodoroProvider pomodoroProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final weekData = _getWeekData(todoProvider);
    final weekPomodoroData = _getWeekPomodoroData(pomodoroProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weeklyProgress,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
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
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                barGroups: weekData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final pomodoroData = weekPomodoroData[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (data['created'] ?? 0).toDouble(),
                        color: AppTheme.primaryColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: (data['completed'] ?? 0).toDouble(),
                        color: AppTheme.secondaryColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: (pomodoroData['sessions'] ?? 0).toDouble(),
                        color: Colors.orange,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(l10n, includePomodoro: true),
          const SizedBox(height: 24),
          _buildWeeklyPomodoroSummary(weekPomodoroData, l10n),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(
    TodoProvider todoProvider,
    PomodoroProvider pomodoroProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final monthData = _getMonthData(todoProvider);
    final monthPomodoroData = _getMonthPomodoroData(pomodoroProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlyTrends,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
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
                          l10n.week1,
                          l10n.week2,
                          l10n.week3,
                          l10n.week4,
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
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
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 3,
                minY: 0,
                maxY: _getMaxYForMonthChart(monthData, monthPomodoroData),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['created'] ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: monthData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['completed'] ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.secondaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: monthPomodoroData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['sessions'] ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(l10n, includePomodoro: true),
          const SizedBox(height: 24),
          _buildMonthlyPomodoroSummary(monthPomodoroData, l10n),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOverviewView(
    TodoProvider todoProvider,
    PomodoroProvider pomodoroProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.productivityOverview,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildStatsGrid(todoProvider, pomodoroProvider, l10n),
          const SizedBox(height: 24),
          _buildCompletionPieChart(todoProvider, l10n),
          const SizedBox(height: 24),
          _buildPomodoroOverviewCard(pomodoroProvider, l10n),
          const SizedBox(height: 24),
          _buildBestPerformance(todoProvider, l10n),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    Map<String, dynamic> stats,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  l10n.created,
                  stats['created'].toString(),
                  AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  l10n.completedTodos,
                  stats['completed'].toString(),
                  AppTheme.secondaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  l10n.completionRate,
                  '${stats['rate'].toStringAsFixed(1)}%',
                  stats['rate'] >= 70
                      ? AppTheme.secondaryColor
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildDataEntryProgressCard(TodoProvider todoProvider, AppLocalizations l10n) {
    // 获取今天有数据统计的重复任务
    final today = _getLocalNow();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 计算今天需要填写数据的任务总数（只计算今天应该生成的重复任务）
    final totalDataEntryTasks = todoProvider.repeatTodos
        .where((rt) => rt.dataStatisticsEnabled && _shouldGenerateForToday(rt, todayDate))
        .length;

    // 计算今天已经填写数据的任务数
    final completedDataEntryTasks = todoProvider.statisticsData
        .where((data) =>
            data.todoCreatedAt.year == today.year &&
            data.todoCreatedAt.month == today.month &&
            data.todoCreatedAt.day == today.day)
        .map((data) => data.repeatTodoId)
        .toSet()
        .length;

    // 计算数据填写进度
    final dataEntryProgress = totalDataEntryTasks > 0
        ? (completedDataEntryTasks / totalDataEntryTasks) * 100
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据填写进度',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: dataEntryProgress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                dataEntryProgress >= 70 ? AppTheme.secondaryColor : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completedDataEntryTasks/$totalDataEntryTasks 个任务已填写数据 (${dataEntryProgress.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(AppLocalizations l10n, {bool includePomodoro = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                width: 16,
                height: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(l10n.created, style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                width: 16,
                height: 16,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(l10n.completedTodos, style: const TextStyle(fontSize: 12)),
          ],
        ),
        if (includePomodoro) ...[
          const SizedBox(width: 24),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(width: 16, height: 16, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              Text(l10n.pomodoroSessions, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsGrid(
    TodoProvider todoProvider,
    PomodoroProvider pomodoroProvider,
    AppLocalizations l10n,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatsCard(
          l10n.totalTodos,
          todoProvider.allTodos.length.toString(),
          Icons.task_alt,
        ),
        _buildStatsCard(
          l10n.activeTodosCount,
          todoProvider.activeTodosCount.toString(),
          Icons.pending_actions,
        ),
        _buildStatsCard(
          l10n.completedTodosCount,
          todoProvider.completedTodosCount.toString(),
          Icons.check_circle,
        ),
        _buildStatsCard(
          l10n.completionRate,
          '${todoProvider.completionRate.toStringAsFixed(1)}%',
          Icons.trending_up,
        ),
        _buildStatsCard(
          l10n.pomodoroSessions,
          pomodoroProvider.completedSessionsCount.toString(),
          Icons.timer,
        ),
        _buildStatsCard(
          l10n.totalFocusTime,
          _formatDuration(pomodoroProvider.getTotalTimeSpent()),
          Icons.hourglass_top,
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionPieChart(
    TodoProvider provider,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              l10n.todoDistribution,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.secondaryColor,
                      value: provider.completedTodosCount.toDouble(),
                      title: l10n.completedTodos,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      value: provider.activeTodosCount.toDouble(),
                      title: l10n.active,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      radius: 60,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestPerformance(TodoProvider provider, AppLocalizations l10n) {
    final bestDay = _getBestPerformanceDay(provider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bestPerformance,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (bestDay != null)
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${bestDay['day']} ${l10n.withCompletedTodos(bestDay['completed'])}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              )
            else
              Text(
                l10n.noCompletedTodosYet,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTodayStats(TodoProvider provider) {
    final todayTodos = provider.getTodayTodos();
    final completedToday = todayTodos.where((todo) => todo.isCompleted).length;
    final rate = todayTodos.isNotEmpty
        ? (completedToday / todayTodos.length) * 100
        : 0.0;

    return {
      'created': todayTodos.length,
      'completed': completedToday,
      'rate': rate,
    };
  }

  List<Map<String, int>> _getWeekData(TodoProvider provider) {
    final now = _getLocalNow();

    // Start from Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final weekData = List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      final dayTodos = provider.allTodos
          .where(
            (todo) =>
                todo.createdAt.year == day.year &&
                todo.createdAt.month == day.month &&
                todo.createdAt.day == day.day,
          )
          .toList();

      final completed = dayTodos.where((todo) => todo.isCompleted).length;

      return {'created': dayTodos.length, 'completed': completed};
    });

    return weekData;
  }

  List<Map<String, int>> _getMonthData(TodoProvider provider) {
    final now = _getLocalNow();

    // Calculate the first day of current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Calculate 4 weeks from the first day of month
    final monthData = List.generate(4, (weekIndex) {
      final weekStart = firstDayOfMonth.add(Duration(days: weekIndex * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekTodos = provider.allTodos
          .where(
            (todo) =>
                todo.createdAt.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                todo.createdAt.isBefore(weekEnd.add(const Duration(days: 1))),
          )
          .toList();

      final completed = weekTodos.where((todo) => todo.isCompleted).length;

      return {'created': weekTodos.length, 'completed': completed};
    });

    return monthData;
  }

  Map<String, dynamic>? _getBestPerformanceDay(TodoProvider provider) {
    final now = _getLocalNow();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final completedTodos = provider.allTodos
        .where((todo) =>
            todo.isCompleted &&
            todo.createdAt.isAfter(thirtyDaysAgo))
        .toList();

    if (completedTodos.isEmpty) return null;

    final dayStats = <String, int>{};
    for (final todo in completedTodos) {
      final dayKey = '${todo.createdAt.day}/${todo.createdAt.month}';
      dayStats[dayKey] = (dayStats[dayKey] ?? 0) + 1;
    }

    final bestDay = dayStats.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {'day': bestDay.key, 'completed': bestDay.value};
  }

  
  
  Map<String, dynamic> _getTodayPomodoroStats(PomodoroProvider provider) {
    final now = _getLocalNow();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaySessions = provider.pomodoroSessions.where((session) =>
        session.startTime.isAtSameMomentAs(today) ||
        (session.startTime.isAfter(today) && session.startTime.isBefore(tomorrow))
    ).toList();

    final focusSessions = todaySessions
        .where((s) => s.isCompleted && !s.isBreak)
        .toList();
    final breakSessions = todaySessions
        .where((s) => s.isCompleted && s.isBreak)
        .toList();

    final completedSessions = focusSessions.length + breakSessions.length;
    final totalTime = focusSessions.fold<int>(
      0,
      (total, session) => total + (session.actualDuration ?? 0),
    );
    final averageTime = focusSessions.isNotEmpty ? totalTime / focusSessions.length : 0.0;

    return {
      'sessions': completedSessions,
      'totalTime': totalTime,
      'averageTime': averageTime,
      'focusSessions': focusSessions.length,
      'breakSessions': breakSessions.length,
    };
  }

  Widget _buildPomodoroStatsCard(
    Map<String, dynamic> stats,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.pomodoroStats,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.sessionsCompleted,
                    stats['sessions'].toString(),
                    AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    l10n.totalTime,
                    _formatDuration(stats['totalTime'].toInt()),
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    l10n.focusSessions,
                    stats['focusSessions'].toString(),
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

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0:00';
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // Weekly Pomodoro Data
  List<Map<String, int>> _getWeekPomodoroData(PomodoroProvider provider) {
    final now = _getLocalNow();

    // Start from Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final weekData = List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySessions = provider.pomodoroSessions
          .where(
            (session) =>
                (session.startTime.isAtSameMomentAs(dayStart) || session.startTime.isAfter(dayStart)) &&
                session.startTime.isBefore(dayEnd) &&
                session.isCompleted &&
                !session.isBreak,
          )
          .toList();

      return {
        'sessions': daySessions.length,
        'totalTime': daySessions.fold<int>(
          0,
          (total, session) => total + (session.actualDuration ?? 0),
        ),
      };
    });

    return weekData;
  }

  // Monthly Pomodoro Data
  List<Map<String, int>> _getMonthPomodoroData(PomodoroProvider provider) {
    final now = _getLocalNow();

    // Calculate the first day of current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Calculate 4 weeks from the first day of month
    final monthData = List.generate(4, (weekIndex) {
      final weekStart = firstDayOfMonth.add(Duration(days: weekIndex * 7));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEnd = weekStartDay.add(const Duration(days: 7));

      final weekSessions = provider.pomodoroSessions
          .where(
            (session) =>
                (session.startTime.isAtSameMomentAs(weekStartDay) || session.startTime.isAfter(weekStartDay)) &&
                session.startTime.isBefore(weekEnd) &&
                session.isCompleted &&
                !session.isBreak,
          )
          .toList();

      return {
        'sessions': weekSessions.length,
        'totalTime': weekSessions.fold<int>(
          0,
          (total, session) => total + (session.actualDuration ?? 0),
        ),
      };
    });

    return monthData;
  }

  // Get max Y value for month chart
  double _getMaxYForMonthChart(
    List<Map<String, int>> monthData,
    List<Map<String, int>> monthPomodoroData,
  ) {
    final maxTodos = monthData.isEmpty
        ? 0
        : monthData
              .map((e) => e['created'] as int)
              .reduce((a, b) => a > b ? a : b);
    final maxPomodoro = monthPomodoroData.isEmpty
        ? 0
        : monthPomodoroData
              .map((e) => e['sessions'] as int)
              .reduce((a, b) => a > b ? a : b);
    final maxValue = (maxTodos > maxPomodoro ? maxTodos : maxPomodoro) + 2;
    return maxValue > 10 ? maxValue.toDouble() : 10.0;
  }

  // Weekly Pomodoro Summary Card
  Widget _buildWeeklyPomodoroSummary(
    List<Map<String, int>> weekPomodoroData,
    AppLocalizations l10n,
  ) {
    final totalSessions = weekPomodoroData.fold<int>(
      0,
      (total, data) => total + data['sessions']!,
    );
    final totalTime = weekPomodoroData.fold<int>(
      0,
      (total, data) => total + data['totalTime']!,
    );
    final averageSessions = totalSessions / 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.weeklyPomodoroStats,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.totalSessions,
                    totalSessions.toString(),
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.totalTime,
                    _formatDuration(totalTime),
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.averageSessions,
                    averageSessions.toStringAsFixed(1),
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

  // Monthly Pomodoro Summary Card
  Widget _buildMonthlyPomodoroSummary(
    List<Map<String, int>> monthPomodoroData,
    AppLocalizations l10n,
  ) {
    final totalSessions = monthPomodoroData.fold<int>(
      0,
      (total, data) => total + data['sessions']!,
    );
    final totalTime = monthPomodoroData.fold<int>(
      0,
      (total, data) => total + data['totalTime']!,
    );
    final averageSessions = totalSessions / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.monthlyPomodoroStats,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.totalSessions,
                    totalSessions.toString(),
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.totalTime,
                    _formatDuration(totalTime),
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.averagePerWeek,
                    averageSessions.toStringAsFixed(1),
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

  // Pomodoro Overview Card
  Widget _buildPomodoroOverviewCard(
    PomodoroProvider provider,
    AppLocalizations l10n,
  ) {
    final now = _getLocalNow();

    // Calculate time periods
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStartDay.add(const Duration(days: 7));

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    // Get completed sessions and time for each period
    final todayTime = provider.getTotalTimeSpent(startDate: todayStart, endDate: todayEnd);
    final weekTime = provider.getTotalTimeSpent(startDate: weekStartDay, endDate: weekEnd);
    final monthTime = provider.getTotalTimeSpent(startDate: monthStart, endDate: monthEnd);

    final todaySessions = provider.getTodaySessions();
    final weekSessions = provider.getWeekSessions();
    final monthSessions = provider.getMonthSessions();

    final todayCompleted = todaySessions
        .where((s) => s.isCompleted && !s.isBreak)
        .length;
    final weekCompleted = weekSessions
        .where((s) => s.isCompleted && !s.isBreak)
        .length;
    final monthCompleted = monthSessions
        .where((s) => s.isCompleted && !s.isBreak)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.pomodoroOverview,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.today,
                    '$todayCompleted (${_formatDuration(todayTime)})',
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.thisWeek,
                    '$weekCompleted (${_formatDuration(weekTime)})',
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.thisMonth,
                    '$monthCompleted (${_formatDuration(monthTime)})',
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

  // Build AI-generated incentive message
  Widget _buildAIIncentiveMessage(Map<String, dynamic> todayStats, AppLocalizations l10n) {
    final completed = todayStats['completed'] as int;
    final total = todayStats['created'] as int;
    final completionRate = todayStats['rate'] as double;

    return Consumer<AIProvider>(
      builder: (context, aiProvider, child) {
        // Check if AI features are disabled OR motivational messages are disabled
        if (!aiProvider.settings.enableAIFeatures || !aiProvider.settings.enableMotivationalMessages) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<String?>(
          future: aiProvider.generateIncentiveMessage(completed, total),
          builder: (context, snapshot) {
            // Debug info removed

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            // Check for error or null data
            if (snapshot.hasError || snapshot.data == null) {
              // Check if there's a specific error message from the provider
              final errorMessage = aiProvider.lastError ?? l10n.aiServiceNotAvailableCheckSettings;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final message = snapshot.data!;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: _getMessageColor(completionRate),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getMessageColor(completionRate),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

  }
}

enum StatisticsTimePeriod {
  today,
  thisWeek,
  thisMonth,
  overview,
}