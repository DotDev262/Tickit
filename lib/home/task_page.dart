import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickit/main.dart';
import 'package:tickit/models/sort_option.dart';
import 'package:tickit/models/task.dart';
import 'package:tickit/widgets/add_task_dialog.dart';

class TaskPage extends ConsumerStatefulWidget {
  const TaskPage({super.key});

  @override
  ConsumerState<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends ConsumerState<TaskPage> {
  SortOption _currentSortOption = SortOption.deadline;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleSort() {
    setState(() {
      _currentSortOption = _currentSortOption == SortOption.deadline
          ? SortOption.title
          : SortOption.deadline;
    });
  }

  Future<void> _showAddTaskDialog() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );

    if (task != null) {
      try {
        await ref.read(todoServiceProvider).addTodo(task);
        ref.invalidate(todoListProvider);
      } catch (e) {
        _showSnackBar('Failed to add task: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoList = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              _currentSortOption == SortOption.deadline
                  ? Icons.schedule
                  : Icons.sort_by_alpha,
            ),
            onPressed: _toggleSort,
            tooltip:
                'Sort by ${_currentSortOption == SortOption.deadline ? "Title" : "Deadline"}',
          ),
        ],
      ),
      body: todoList.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks yet! Add one using the + button.'),
            );
          }
          final sortedTasks = List<Task>.from(tasks);
          sortedTasks.sort((a, b) {
            if (_currentSortOption == SortOption.deadline) {
              return a.deadline.compareTo(b.deadline);
            } else {
              return a.title.compareTo(b.title);
            }
          });

          return ListView.builder(
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              final task = sortedTasks[index];
              return TaskTile(
                task: task,
                onTaskChanged: (newTask) async {
                  try {
                    await ref.read(todoServiceProvider).updateTodo(newTask);
                    ref.invalidate(todoListProvider);
                  } catch (e) {
                    _showSnackBar('Failed to update task: $e');
                  }
                },
                onTaskDeleted: () async {
                  if (task.id != null) {
                    try {
                      await ref.read(todoServiceProvider).deleteTodo(task.id!);
                      ref.invalidate(todoListProvider);
                    } catch (e) {
                      _showSnackBar('Failed to delete task: $e');
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load tasks: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onTaskChanged,
    required this.onTaskDeleted,
  });

  final Task task;
  final ValueChanged<Task> onTaskChanged;
  final VoidCallback onTaskDeleted;

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.completed && task.deadline.isBefore(DateTime.now());
    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (bool? value) {
          onTaskChanged(task.copyWith(completed: value ?? false));
        },
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          color: isOverdue && !task.completed ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        'Deadline: ${task.deadline.toLocal().toString().split(' ')[0]}',
        style: TextStyle(
          color: isOverdue && !task.completed ? Colors.red : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onTaskDeleted,
      ),
    );
  }
}
