import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/pomodoro_provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/models/todo_model.dart';

class PomodoroScreen extends StatefulWidget {
  final TodoModel todo;

  const PomodoroScreen({super.key, required this.todo});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pomodoroProvider = Provider.of<PomodoroProvider>(context);
    final todoProvider = Provider.of<TodoProvider>(context);

    // Update progress animation
    if (pomodoroProvider.state != PomodoroState.idle) {
      _progressController.animateTo(pomodoroProvider.progress);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.pomodoroTimer,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.todo.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Timer Display
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress Circle
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background Circle
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),

                            // Progress Arc
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(280, 280),
                                  painter: ProgressPainter(
                                    progress: pomodoroProvider.progress,
                                    color: pomodoroProvider.isBreakTime
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.primary,
                                    backgroundColor: theme.colorScheme.outline
                                        .withValues(alpha: 0.1),
                                  ),
                                );
                              },
                            ),

                            // Timer Text
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  pomodoroProvider.formattedTime,
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pomodoroProvider.isBreakTime
                                      ? l10n.breakTime
                                      : l10n.focusTime,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 16,
                        children: [
                          if (pomodoroProvider.isRunning ||
                              pomodoroProvider.isBreakTime)
                            _ControlButton(
                              icon: Icons.pause,
                              label: l10n.pause,
                              onPressed: () => pomodoroProvider.pauseTimer(),
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onSecondaryContainer,
                            )
                          else if (pomodoroProvider.isPaused)
                            _ControlButton(
                              icon: Icons.play_arrow,
                              label: l10n.resume,
                              onPressed: () => pomodoroProvider.resumeTimer(),
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                            )
                          else if (pomodoroProvider.state == PomodoroState.idle)
                            _ControlButton(
                              icon: Icons.play_arrow,
                              label: l10n.start,
                              onPressed: () => pomodoroProvider.startPomodoro(
                                widget.todo.id,
                              ),
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                            ),

                          if (pomodoroProvider.state != PomodoroState.idle)
                            _ControlButton(
                              icon: Icons.stop,
                              label: l10n.stop,
                              onPressed: () async {
                                await pomodoroProvider.stopTimer();
                                Navigator.of(context).pop();
                              },
                              backgroundColor: theme.colorScheme.errorContainer,
                              foregroundColor:
                                  theme.colorScheme.onErrorContainer,
                            ),

                          // Complete button - available during active timer sessions and break time
                          if (pomodoroProvider.state == PomodoroState.running ||
                              pomodoroProvider.state == PomodoroState.paused ||
                              pomodoroProvider.state == PomodoroState.completed ||
                              pomodoroProvider.state == PomodoroState.breakTime)
                            _ControlButton(
                              icon: Icons.check,
                              label: l10n.complete,
                              onPressed: () async {
                                await pomodoroProvider.completePomodoroManually(
                                  widget.todo,
                                );
                                // 完成任务后重置番茄钟周期
                                pomodoroProvider.resetCurrentCycle();
                                // 确保时区已初始化
                                try {
                                  tz.initializeTimeZones();
                                } catch (e) {
                                  // 时区初始化失败时继续使用默认时区
                                }
                                await todoProvider.updateTodo(
                                  widget.todo.copyWith(
                                    isCompleted: true,
                                    completedAt: tz.TZDateTime.now(tz.local),
                                    timeSpent:
                                        (widget.todo.timeSpent ?? 0) +
                                        pomodoroProvider.getTotalTimeSpent(todoId: widget.todo.id),
                                  ),
                                );
                                Navigator.of(context).pop();
                              },
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 32),
            color: foregroundColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  ProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const startAngle = -90 * (3.14159 / 180);
    final sweepAngle = progress * 360 * (3.14159 / 180);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is ProgressPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.color != color ||
            oldDelegate.backgroundColor != backgroundColor);
  }
}
