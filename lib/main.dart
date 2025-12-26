import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/notification_service.dart';
import 'package:easy_todo/services/update_service.dart';
import 'package:easy_todo/services/permission_service.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/providers/language_provider.dart';
import 'package:easy_todo/providers/theme_provider.dart';
import 'package:easy_todo/providers/filter_provider.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/providers/pomodoro_provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/screens/todo_list_screen.dart';
import 'package:easy_todo/screens/history_screen.dart';
import 'package:easy_todo/screens/statistics_screen.dart';
import 'package:easy_todo/screens/preference_screen.dart';
import 'package:easy_todo/screens/forced_update_page.dart';
import 'package:easy_todo/widgets/auth_wrapper.dart';
import 'package:easy_todo/services/timezone_service.dart';
import 'package:easy_todo/utils/app_scroll_behavior.dart';
import 'package:easy_todo/utils/responsive.dart';
import 'package:easy_todo/widgets/responsive_web_frame.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize enhanced timezone service
  final timezoneService = TimezoneService();
  try {
    await timezoneService.initialize();

    // Detect and set the correct timezone
    final detectedTimezone = timezoneService.detectTimezone();
    await timezoneService.setCustomTimezone(detectedTimezone);

    // Print detailed timezone information
    // final timezoneInfo = timezoneService.getTimezoneInfo();
  } catch (e) {
    rethrow;
  }

  // Initialize Hive with enhanced error handling for schema changes
  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('Hive initialization failed: $e');
    // If the error is related to AI settings schema, try to recover
    if (e.toString().contains('type cast') ||
        e.toString().contains('bool') ||
        e.toString().contains('AISettingsModel')) {
      try {
        // Delete the corrupted AI settings box and try again
        await Hive.deleteBoxFromDisk(HiveService.aiSettingsBoxName);
        await HiveService.init();
      } catch (e2) {
        debugPrint('Failed to recover from AI settings error: $e2');
        // As a last resort, try to continue without AI settings
        // We'll need to modify HiveService to handle missing AI settings gracefully
        rethrow;
      }
    } else {
      rethrow;
    }
  }
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Reschedule all notifications after app restart (only if needed)
  await notificationService.rescheduleAllReminders();

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TodoProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FilterProvider()),
        ChangeNotifierProvider(create: (context) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (context) => PomodoroProvider()),
        ChangeNotifierProvider(create: (context) => AIProvider()),
      ],
      child: Consumer3<LanguageProvider, ThemeProvider, AIProvider>(
        builder: (context, languageProvider, themeProvider, aiProvider, child) {
          final l10n = AppLocalizations.of(context);
          return MaterialApp(
            key: ValueKey(themeProvider.themeVersion),
            title: l10n?.appTitle ?? 'Easy Todo',
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            builder: (context, child) {
              return ResponsiveWebFrame(
                child: child ?? const SizedBox.shrink(),
              );
            },
            navigatorKey: navigatorKey,
            locale: languageProvider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageProvider.supportedLocales,
            home: Builder(
              builder: (materialAppContext) {
                // Set AI provider and context in notification service (now inside MaterialApp)
                final notificationService = NotificationService.instance;
                notificationService.setAIProvider(aiProvider);
                notificationService.setContext(materialAppContext);

                return AuthWrapper(
                  child: MainNavigationScreen(),
                  onAuthComplete: () {
                    // Connect AI provider and language provider to todo provider after auth
                    final todoProvider = Provider.of<TodoProvider>(
                      materialAppContext,
                      listen: false,
                    );
                    todoProvider.setAIProvider(aiProvider);
                    todoProvider.setLanguageProvider(languageProvider);

                    // Connect AI provider and todo provider to pomodoro provider
                    final pomodoroProvider = Provider.of<PomodoroProvider>(
                      materialAppContext,
                      listen: false,
                    );
                    pomodoroProvider.setAIProvider(aiProvider);
                    pomodoroProvider.setTodoProvider(todoProvider);

                    // Also connect language provider to AI provider
                    aiProvider.setLanguageProvider(languageProvider);
                    // Update AI service with context for proper localization
                    aiProvider.updateAIServiceContext(materialAppContext);
                    // Set up callback to clear AI cache when language changes
                    languageProvider.setOnLanguageChanged(() {
                      aiProvider.clearMotivationalMessageCache();
                      // Update AI service context when language changes
                      aiProvider.updateAIServiceContext(materialAppContext);
                      // Also update notification service context
                      final notificationService = NotificationService.instance;
                      notificationService.setContext(materialAppContext);
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _GoToTabIntent extends Intent {
  final int index;

  const _GoToTabIntent(this.index);
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final UpdateService _updateService = UpdateService();

  final List<Widget> _screens = [
    const TodoListScreen(),
    const HistoryScreen(),
    const StatisticsScreen(),
    const PreferenceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      _checkForUpdates();
    }
    _checkRepeatTodos();
    _initializePermissions();
  }

  Future<void> _checkForUpdates() async {
    // Wait a bit to let the app fully initialize
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final appSettingsProvider = Provider.of<AppSettingsProvider>(
      context,
      listen: false,
    );

    // Only check for updates if auto-update is enabled
    if (appSettingsProvider.autoUpdateEnabled) {
      try {
        final updateInfo = await _updateService.checkForUpdates();

        if (mounted && updateInfo.updateAvailable) {
          if (updateInfo.forceUpdate) {
            // Show forced update page
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ForcedUpdatePage(
                  updateInfo: updateInfo,
                  updateService: _updateService,
                ),
              ),
            );
          } else {
            // Show optional update notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.updateAvailable,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                action: SnackBarAction(
                  label: AppLocalizations.of(context)!.updateNow,
                  textColor: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ForcedUpdatePage(
                          updateInfo: updateInfo,
                          updateService: _updateService,
                        ),
                      ),
                    );
                  },
                ),
                duration: const Duration(seconds: 10),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.primaryContainer,
              ),
            );
          }
        }
      } catch (e) {
        // Silently fail update check to avoid interrupting user experience
        debugPrint('Failed to check for updates: $e');
      }
    }
  }

  Future<void> _checkRepeatTodos() async {
    // Wait a bit to let the app fully initialize
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    await todoProvider.checkAndGenerateRepeatTodos();

    // Schedule midnight check
    _scheduleMidnightCheck();
  }

  Future<void> _initializePermissions() async {
    // Wait a bit to let the app fully initialize
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 初始化权限
    await PermissionService.initializePermissions(context);
  }

  void _scheduleMidnightCheck() {
    // 使用本地时间计算午夜，确保在用户本地时间的午夜触发
    try {
      final now = _getLocalDateTime();
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final durationUntilMidnight = midnight.difference(now);

      // 添加额外的调试信息

      Future.delayed(durationUntilMidnight, () {
        if (mounted) {
          final todoProvider = Provider.of<TodoProvider>(
            context,
            listen: false,
          );
          todoProvider.forceRefreshAllRepeatTasks();
          // Schedule next day's check
          _scheduleMidnightCheck();
        }
      });
    } catch (e) {
      debugPrint('Error scheduling midnight check: $e');
      // 如果时区处理失败，使用简单延迟重试
      Future.delayed(const Duration(minutes: 1), () {
        if (mounted) {
          _scheduleMidnightCheck();
        }
      });
    }
  }

  Future<void> _checkRepeatTodosOnResume() async {
    // 等待一小段时间确保应用完全恢复
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    await todoProvider.forceCheckRepeatTodos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // 应用回到前台时检查重复任务，添加延迟避免频繁调用
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _checkRepeatTodosOnResume();
          }
        });
        break;
      case AppLifecycleState.paused:
        // 应用进入后台时可以做一些清理工作
        break;
      case AppLifecycleState.detached:
        // 应用被终止时移除观察者
        WidgetsBinding.instance.removeObserver(this);
        break;
      case AppLifecycleState.inactive:
        // 应用处于非活动状态
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏
        break;
    }
  }

  // 获取本地时间的辅助方法 (直接使用系统时间)
  DateTime _getLocalDateTime() {
    final systemTime = DateTime.now();
    return systemTime;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final desktopWeb = isWebDesktop(context);
    final desktopWebWide = isWebDesktopWide(context);

    final pageView = PageView(
      controller: _pageController,
      physics: desktopWeb ? const NeverScrollableScrollPhysics() : null,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: _screens,
    );

    final scaffold = Scaffold(
      body: desktopWeb
          ? Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onTabTapped,
                    extended: desktopWebWide,
                    labelType: desktopWebWide
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.task_alt,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          if (desktopWebWide) ...[
                            const SizedBox(width: 8),
                            Text(
                              l10n.appTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.task_alt_outlined),
                        selectedIcon: const Icon(Icons.task_alt),
                        label: Text(l10n.todos),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.history_outlined),
                        selectedIcon: const Icon(Icons.history),
                        label: Text(l10n.history),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.bar_chart_outlined),
                        selectedIcon: const Icon(Icons.bar_chart),
                        label: Text(l10n.stats),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: const Icon(Icons.settings),
                        label: Text(l10n.preferences),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                Expanded(child: pageView),
              ],
            )
          : pageView,
      bottomNavigationBar: desktopWeb
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.task_alt,
                        label: l10n.todos,
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.history,
                        label: l10n.history,
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Icons.bar_chart,
                        label: l10n.stats,
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.settings_outlined,
                        label: l10n.preferences,
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );

    if (!desktopWeb) return scaffold;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _GoToTabIntent(0),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _GoToTabIntent(1),
        SingleActivator(LogicalKeyboardKey.digit3, control: true):
            _GoToTabIntent(2),
        SingleActivator(LogicalKeyboardKey.digit4, control: true):
            _GoToTabIntent(3),
        SingleActivator(LogicalKeyboardKey.digit1, meta: true): _GoToTabIntent(
          0,
        ),
        SingleActivator(LogicalKeyboardKey.digit2, meta: true): _GoToTabIntent(
          1,
        ),
        SingleActivator(LogicalKeyboardKey.digit3, meta: true): _GoToTabIntent(
          2,
        ),
        SingleActivator(LogicalKeyboardKey.digit4, meta: true): _GoToTabIntent(
          3,
        ),
      },
      child: Actions(
        actions: {
          _GoToTabIntent: CallbackAction<_GoToTabIntent>(
            onInvoke: (intent) {
              _onTabTapped(intent.index);
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: scaffold),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
