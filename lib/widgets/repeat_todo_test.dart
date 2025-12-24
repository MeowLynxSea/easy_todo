import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/widgets/repeat_todo_dialog.dart';

class RepeatTodoTestScreen extends StatefulWidget {
  const RepeatTodoTestScreen({super.key});

  @override
  State<RepeatTodoTestScreen> createState() => _RepeatTodoTestScreenState();
}

class _RepeatTodoTestScreenState extends State<RepeatTodoTestScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.repeatTodoTest)),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${l10n.repeatTodos}${todoProvider.repeatTodos.length}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => RepeatTodoDialog(
                        onAdd: (repeatTodo) async {
                          await todoProvider.addRepeatTodo(repeatTodo);
                        },
                      ),
                    );
                  },
                  child: Text(l10n.addRepeatTodo),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await todoProvider.checkAndGenerateRepeatTodos();
                  },
                  child: Text(l10n.checkRepeatTodos),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
