import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/app_settings_provider.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/utils/time_format.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class ScheduleLayoutSettingsScreen extends StatefulWidget {
  const ScheduleLayoutSettingsScreen({super.key});

  @override
  State<ScheduleLayoutSettingsScreen> createState() =>
      _ScheduleLayoutSettingsScreenState();
}

class _ScheduleLayoutSettingsScreenState
    extends State<ScheduleLayoutSettingsScreen> {
  RangeValues? _rangeDraft;
  Set<int>? _weekdaysDraft;
  double? _labelScaleDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<AppSettingsProvider>(context);

    final providerRange = RangeValues(
      provider.scheduleDayStartMinutes.toDouble(),
      provider.scheduleDayEndMinutes.toDouble(),
    );
    final range = _rangeDraft ?? providerRange;

    final selectedWeekdays =
        _weekdaysDraft ?? provider.scheduleVisibleWeekdays.toSet();

    final providerScale = provider.scheduleLabelTextScale.clamp(0.8, 1.4);
    final labelScale = _labelScaleDraft ?? providerScale;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleLayoutSettings),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await provider.resetScheduleLayoutSettings();
              if (!mounted) return;
              setState(() {
                _rangeDraft = null;
                _weekdaysDraft = null;
                _labelScaleDraft = null;
              });
            },
            child: Text(l10n.resetButton),
          ),
        ],
      ),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scheduleTimeRange,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatMinutesAsHHmm(range.start.round())} - ${formatMinutesAsHHmm(range.end.round())}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    RangeSlider(
                      values: range,
                      min: 0,
                      max: 1440,
                      divisions: 96,
                      labels: RangeLabels(
                        formatMinutesAsHHmm(range.start.round()),
                        formatMinutesAsHHmm(range.end.round()),
                      ),
                      activeColor: AppTheme.primaryColor,
                      onChanged: (values) {
                        setState(() => _rangeDraft = values);
                      },
                      onChangeEnd: (values) async {
                        await provider.setScheduleTimeRange(
                          startMinutes: values.start.round(),
                          endMinutes: values.end.round(),
                        );
                        if (!mounted) return;
                        setState(() => _rangeDraft = null);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scheduleVisibleWeekdays,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final weekday in const <int>[
                          DateTime.monday,
                          DateTime.tuesday,
                          DateTime.wednesday,
                          DateTime.thursday,
                          DateTime.friday,
                          DateTime.saturday,
                          DateTime.sunday,
                        ])
                          FilterChip(
                            label: Text(_weekdayLabel(l10n, weekday)),
                            selected: selectedWeekdays.contains(weekday),
                            onSelected: (selected) async {
                              final next = Set<int>.from(selectedWeekdays);
                              if (selected) {
                                next.add(weekday);
                              } else {
                                next.remove(weekday);
                              }

                              if (next.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.scheduleAtLeastOneDay),
                                  ),
                                );
                                return;
                              }

                              setState(() => _weekdaysDraft = next);
                              await provider.setScheduleVisibleWeekdays(
                                next.toList(),
                              );
                              if (!mounted) return;
                              setState(() => _weekdaysDraft = null);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scheduleLabelTextScale,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(labelScale * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: labelScale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      label: '${labelScale.toStringAsFixed(1)}x',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (value) {
                        setState(() => _labelScaleDraft = value);
                      },
                      onChangeEnd: (value) async {
                        final normalized = (value * 10).round() / 10.0;
                        await provider.setScheduleLabelTextScale(normalized);
                        if (!mounted) return;
                        setState(() => _labelScaleDraft = null);
                      },
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

  String _weekdayLabel(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.monday;
      case DateTime.tuesday:
        return l10n.tuesday;
      case DateTime.wednesday:
        return l10n.wednesday;
      case DateTime.thursday:
        return l10n.thursday;
      case DateTime.friday:
        return l10n.friday;
      case DateTime.saturday:
        return l10n.saturday;
      case DateTime.sunday:
        return l10n.sunday;
    }
    return l10n.monday;
  }
}
