import 'package:flutter/material.dart';
import 'package:easy_todo/theme/app_theme.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/widgets/repeat_todo_dialog.dart';

class AddTodoDialog extends StatefulWidget {
  final Function(
    String title,
    String? description, {
    DateTime? reminderTime,
    bool reminderEnabled,
  })
  onAdd;
  final Function(RepeatTodoModel repeatTodo)? onAddRepeat;
  final TodoModel? todo;

  const AddTodoDialog({
    super.key,
    required this.onAdd,
    this.onAddRepeat,
    this.todo,
  });

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _reminderEnabled = false;
  DateTime? _reminderTime;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
      _reminderEnabled = widget.todo!.reminderEnabled;
      _reminderTime = widget.todo!.reminderTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onAdd(
        _titleController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        reminderTime: _reminderTime,
        reminderEnabled: _reminderEnabled,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addTodoError(e.toString())),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if(mounted) {
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
                widget.todo != null ? l10n.edit : l10n.addTodo,
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
                    return l10n.titleRequired;
                  }
                  return null;
                },
                readOnly: widget.todo != null,
                textInputAction: widget.todo == null
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: widget.todo == null
                    ? (_) {
                        FocusScope.of(context).nextFocus();
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.todoDescription,
                  hintText: l10n.todoDescription.toLowerCase(),
                ),
                maxLines: 3,
                readOnly: widget.todo != null,
                textInputAction: widget.todo == null
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: widget.todo == null
                    ? (_) {
                        FocusScope.of(context).nextFocus();
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.enableReminder),
                subtitle: _reminderTime != null
                    ? Text(
                        l10n.timeFormat(
                          _reminderTime!.hour.toString().padLeft(2, '0'),
                          _reminderTime!.minute.toString().padLeft(2, '0'),
                        ),
                      )
                    : Text(l10n.noReminderSet),
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _reminderEnabled = value;
                    if (!value) {
                      _reminderTime = null;
                    }
                  });
                },
                secondary: Icon(
                  Icons.alarm_outlined,
                  color: _reminderEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 16),
                ListTile(
                  title: Text(l10n.reminderTime),
                  subtitle: _reminderTime != null
                      ? Text(
                          l10n.timeFormat(
                            _reminderTime!.hour.toString().padLeft(2, '0'),
                            _reminderTime!.minute.toString().padLeft(2, '0'),
                          ),
                        )
                      : Text(l10n.setReminder),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectReminderTime,
                ),
              ],
              if (widget.onAddRepeat != null) ...[
                const SizedBox(height: 16),
                ListTile(
                  title: Text(l10n.repeatTask),
                  subtitle: Text(l10n.repeatDescription),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showRepeatTodoDialog,
                ),
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
                              widget.todo != null ? l10n.save : l10n.addTodo,
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

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      // 使用系统时间，避免时区混乱
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      setState(() {
        _reminderTime = selectedDateTime;
      });

      }
  }

  void _showRepeatTodoDialog() {
    // Pre-fill with current title and description
    showDialog(
      context: context,
      builder: (context) => RepeatTodoDialog(
        onAdd: (repeatTodo) {
          widget.onAddRepeat?.call(repeatTodo);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
