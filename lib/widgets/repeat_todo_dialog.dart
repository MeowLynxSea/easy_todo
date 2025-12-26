import 'package:flutter/material.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';

class RepeatTodoDialog extends StatefulWidget {
  final Function(RepeatTodoModel repeatTodo) onAdd;
  final RepeatTodoModel? repeatTodo;

  const RepeatTodoDialog({super.key, required this.onAdd, this.repeatTodo});

  @override
  State<RepeatTodoDialog> createState() => _RepeatTodoDialogState();
}

class _RepeatTodoDialogState extends State<RepeatTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _repeatEnabled = true;
  RepeatType _repeatType = RepeatType.daily;
  List<int> _selectedWeekDays = [];
  int? _selectedDayOfMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasEndDate = false;
  bool _dataStatisticsEnabled = false;
  List<StatisticsMode> _selectedStatisticsModes = [];
  final _dataUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.repeatTodo != null) {
      _titleController.text = widget.repeatTodo!.title;
      _descriptionController.text = widget.repeatTodo!.description ?? '';
      _repeatEnabled = widget.repeatTodo!.isActive;
      _repeatType = widget.repeatTodo!.repeatType;
      _selectedWeekDays = widget.repeatTodo!.weekDays ?? [];
      _selectedDayOfMonth = widget.repeatTodo!.dayOfMonth;
      _startDate = widget.repeatTodo!.startDate;
      _endDate = widget.repeatTodo!.endDate;
      _hasEndDate = widget.repeatTodo!.endDate != null;
      _dataStatisticsEnabled = widget.repeatTodo!.dataStatisticsEnabled;
      _selectedStatisticsModes = widget.repeatTodo!.statisticsModes ?? [];
      _dataUnitController.text = widget.repeatTodo!.dataUnit ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dataUnitController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repeatTodo =
          RepeatTodoModel.create(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            repeatType: _repeatType,
            weekDays: _repeatType == RepeatType.weekly
                ? _selectedWeekDays
                : null,
            dayOfMonth: _repeatType == RepeatType.monthly
                ? _selectedDayOfMonth
                : null,
            startDate: _startDate,
            endDate: _hasEndDate ? _endDate : null,
            dataStatisticsEnabled: _dataStatisticsEnabled,
            statisticsModes: _dataStatisticsEnabled
                ? _selectedStatisticsModes
                : null,
            dataUnit: _dataStatisticsEnabled
                ? _dataUnitController.text.trim().isEmpty
                      ? null
                      : _dataUnitController.text.trim()
                : null,
          ).copyWith(
            id: widget.repeatTodo?.id,
            isActive: _repeatEnabled,
            createdAt: widget.repeatTodo?.createdAt,
            lastGeneratedDate: widget.repeatTodo?.lastGeneratedDate,
            order: widget.repeatTodo?.order ?? 0,
          );

      await widget.onAdd(repeatTodo);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.repeatTaskCreateError(e.toString())),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.repeatTodo != null
                        ? l10n.editRepeat
                        : l10n.repeatTask,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.todoTitle,
                      hintText: l10n.addTodoHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.repeatTaskTitleRequired;
                      }
                      return null;
                    },
                    readOnly: widget.repeatTodo != null,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.todoDescription,
                      hintText: l10n.todoDescription.toLowerCase(),
                    ),
                    maxLines: 3,
                    readOnly: widget.repeatTodo != null,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(l10n.repeatEnabled),
                    subtitle: Text(l10n.repeatDescription),
                    value: _repeatEnabled,
                    onChanged: (value) {
                      setState(() {
                        _repeatEnabled = value;
                      });
                    },
                    secondary: Icon(
                      Icons.repeat,
                      color: _repeatEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  if (_repeatEnabled) ...[
                    const SizedBox(height: 16),
                    _buildRepeatTypeSelector(),
                    const SizedBox(height: 16),
                    _buildRepeatTypeSpecificOptions(),
                    const SizedBox(height: 16),
                    _buildDateOptions(),
                    const SizedBox(height: 16),
                    _buildDataStatisticsOptions(),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.repeatTodo != null
                                      ? l10n.save
                                      : l10n.addTodo,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatTypeSelector() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.repeatType, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: RepeatType.values.map((type) {
            final isSelected = _repeatType == type;
            return ChoiceChip(
              label: Text(_getRepeatTypeDisplayName(type, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _repeatType = type;
                    _selectedWeekDays = [];
                    _selectedDayOfMonth = null;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRepeatTypeSpecificOptions() {
    switch (_repeatType) {
      case RepeatType.weekly:
        return _buildWeekdaySelector();
      case RepeatType.monthly:
        return _buildDayOfMonthSelector();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWeekdaySelector() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectDays, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildWeekdayChip(l10n.monday, 1),
            _buildWeekdayChip(l10n.tuesday, 2),
            _buildWeekdayChip(l10n.wednesday, 3),
            _buildWeekdayChip(l10n.thursday, 4),
            _buildWeekdayChip(l10n.friday, 5),
            _buildWeekdayChip(l10n.saturday, 6),
            _buildWeekdayChip(l10n.sunday, 7),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayChip(String label, int day) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedWeekDays.contains(day),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedWeekDays.add(day);
          } else {
            _selectedWeekDays.remove(day);
          }
        });
      },
    );
  }

  Widget _buildDayOfMonthSelector() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectDate, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(31, (index) {
            final day = index + 1;
            return ChoiceChip(
              label: Text(day.toString()),
              selected: _selectedDayOfMonth == day,
              onSelected: (selected) {
                setState(() {
                  _selectedDayOfMonth = selected ? day : null;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDateOptions() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Date
        ListTile(
          title: Text(l10n.startDate),
          subtitle: Text(
            _startDate?.toLocal().toString().split(' ')[0] ?? l10n.selectDate,
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectStartDate,
        ),
        const SizedBox(height: 8),
        // End Date
        SwitchListTile(
          title: Text(l10n.endDate),
          subtitle: _hasEndDate
              ? Text(
                  _endDate?.toLocal().toString().split(' ')[0] ??
                      l10n.noEndDate,
                )
              : Text(l10n.noEndDate),
          value: _hasEndDate,
          onChanged: (value) {
            setState(() {
              _hasEndDate = value;
              if (!value) {
                _endDate = null;
              }
            });
          },
        ),
        if (_hasEndDate) ...[
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.endDate),
            subtitle: Text(
              _endDate?.toLocal().toString().split(' ')[0] ?? l10n.selectDate,
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectEndDate,
          ),
        ],
      ],
    );
  }

  Future<void> _selectStartDate() async {
    // 使用与每日任务相同的系统时间
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    // 使用与每日任务相同的系统时间
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  String _getRepeatTypeDisplayName(RepeatType type, AppLocalizations l10n) {
    switch (type) {
      case RepeatType.daily:
        return l10n.daily;
      case RepeatType.weekly:
        return l10n.weekly;
      case RepeatType.monthly:
        return l10n.monthly;
      case RepeatType.weekdays:
        return l10n.weekdays;
    }
  }

  Widget _buildDataStatisticsOptions() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.dataStatistics),
          subtitle: Text(l10n.dataStatisticsDescription),
          value: _dataStatisticsEnabled,
          onChanged: (value) {
            setState(() {
              _dataStatisticsEnabled = value;
              if (!value) {
                _selectedStatisticsModes = [];
                _dataUnitController.clear();
              }
            });
          },
          secondary: Icon(
            Icons.analytics,
            color: _dataStatisticsEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        if (_dataStatisticsEnabled) ...[
          const SizedBox(height: 16),
          _buildStatisticsModesSelector(),
          const SizedBox(height: 16),
          _buildDataUnitField(),
        ],
      ],
    );
  }

  Widget _buildStatisticsModesSelector() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statisticsModes,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StatisticsMode.values.map((mode) {
            final isSelected = _selectedStatisticsModes.contains(mode);
            return FilterChip(
              label: Text(_getStatisticsModeDisplayName(mode, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStatisticsModes.add(mode);
                  } else {
                    _selectedStatisticsModes.remove(mode);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataUnitField() {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: _dataUnitController,
      decoration: InputDecoration(
        labelText: l10n.dataUnit,
        hintText: l10n.dataUnitHint,
      ),
      validator: (value) {
        if (_dataStatisticsEnabled && (value == null || value.trim().isEmpty)) {
          return l10n.dataUnitRequired;
        }
        return null;
      },
    );
  }

  String _getStatisticsModeDisplayName(
    StatisticsMode mode,
    AppLocalizations l10n,
  ) {
    switch (mode) {
      case StatisticsMode.average:
        return l10n.average;
      case StatisticsMode.growth:
        return l10n.growth;
      case StatisticsMode.extremum:
        return l10n.extremum;
      case StatisticsMode.trend:
        return l10n.trend;
      case StatisticsMode.sum:
        return l10n.total; // Using "Total" for sum mode
    }
  }
}
