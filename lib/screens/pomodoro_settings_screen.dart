import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/pomodoro_provider.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class PomodoroSettingsScreen extends StatefulWidget {
  const PomodoroSettingsScreen({super.key});

  @override
  State<PomodoroSettingsScreen> createState() => _PomodoroSettingsScreenState();
}

class _PomodoroSettingsScreenState extends State<PomodoroSettingsScreen> {
  late TextEditingController _workDurationController;
  late TextEditingController _breakDurationController;
  late TextEditingController _longBreakDurationController;
  late TextEditingController _sessionsUntilLongBreakController;
  late PomodoroProvider _pomodoroProvider;

  @override
  void initState() {
    super.initState();
    _pomodoroProvider = Provider.of<PomodoroProvider>(context, listen: false);

    _workDurationController = TextEditingController(
      text: (_pomodoroProvider.workDuration ~/ 60).toString(),
    );
    _breakDurationController = TextEditingController(
      text: (_pomodoroProvider.breakDuration ~/ 60).toString(),
    );
    _longBreakDurationController = TextEditingController(
      text: (_pomodoroProvider.longBreakDuration ~/ 60).toString(),
    );
    _sessionsUntilLongBreakController = TextEditingController(
      text: _pomodoroProvider.sessionsUntilLongBreak.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _saveSettings();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.pomodoroSettings), centerTitle: true),
        body: WebDesktopContent(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.pomodoroSettings,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildDurationSetting(
                          l10n.workDuration,
                          _workDurationController,
                          l10n.minutes,
                          Icons.work_outline,
                          (value) {
                            final minutes = int.tryParse(value) ?? 25;
                            if (minutes > 0) {
                              _pomodoroProvider.updateSettings(
                                workDuration: minutes * 60,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDurationSetting(
                          l10n.breakDuration,
                          _breakDurationController,
                          l10n.minutes,
                          Icons.coffee_outlined,
                          (value) {
                            final minutes = int.tryParse(value) ?? 5;
                            if (minutes > 0) {
                              _pomodoroProvider.updateSettings(
                                breakDuration: minutes * 60,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDurationSetting(
                          l10n.longBreakDuration,
                          _longBreakDurationController,
                          l10n.minutes,
                          Icons.weekend_outlined,
                          (value) {
                            final minutes = int.tryParse(value) ?? 15;
                            if (minutes > 0) {
                              _pomodoroProvider.updateSettings(
                                longBreakDuration: minutes * 60,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDurationSetting(
                          l10n.sessionsUntilLongBreak,
                          _sessionsUntilLongBreakController,
                          l10n.sessions,
                          Icons.repeat_outlined,
                          (value) {
                            final sessions = int.tryParse(value) ?? 4;
                            if (sessions > 0) {
                              _pomodoroProvider.updateSettings(
                                sessionsUntilLongBreak: sessions,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _workDurationController.dispose();
    _breakDurationController.dispose();
    _longBreakDurationController.dispose();
    _sessionsUntilLongBreakController.dispose();
    super.dispose();
  }

  Widget _buildDurationSetting(
    String label,
    TextEditingController controller,
    String unit,
    IconData icon,
    Function(String) onChanged,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  void _saveSettings() {
    final workMinutes = int.tryParse(_workDurationController.text) ?? 25;
    final breakMinutes = int.tryParse(_breakDurationController.text) ?? 5;
    final longBreakMinutes =
        int.tryParse(_longBreakDurationController.text) ?? 15;
    final sessions = int.tryParse(_sessionsUntilLongBreakController.text) ?? 4;

    _pomodoroProvider.updateSettings(
      workDuration: workMinutes * 60,
      breakDuration: breakMinutes * 60,
      longBreakDuration: longBreakMinutes * 60,
      sessionsUntilLongBreak: sessions,
    );
  }
}
