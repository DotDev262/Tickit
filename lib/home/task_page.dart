import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickit/models/task.dart';
import 'package:tickit/services/auth_service.dart';
import 'package:tickit/services/notification_service.dart';
import 'package:tickit/services/todo_service.dart';
import 'package:tickit/widgets/add_task_dialog.dart';
import 'package:intl/intl.dart';
import 'package:tickit/settings/settings_page.dart'; // Assuming this contains swipeToDeleteEnabledProvider etc.

final todoServiceProvider = Provider<TodoService>((ref) => TodoService());

final taskListProvider = FutureProvider<List<Task>>((ref) async {
  final sortOption = ref.watch(sortOptionProvider);
  final tasks = await ref.watch(todoServiceProvider).getTodos();

  switch (sortOption) {
    case SortOption.title:
      tasks.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortOption.completed:
      tasks.sort(
        (a, b) => a.completed == b.completed ? 0 : (a.completed ? 1 : -1),
      );
      break;
    case SortOption.none:
      break;
  }

  return tasks;
});

enum SortOption { none, title, completed }

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.none);

class TaskPage extends ConsumerWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskList = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('tickit'),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => _showProfileDialog(context, ref),
        ),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption newValue) {
              ref.read(sortOptionProvider.notifier).state = newValue;
              // ignore: unused_result
              ref.refresh(taskListProvider);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.none,
                child: Text('None'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.title,
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.completed,
                child: Text('Sort by Completed'),
              ),
            ],
          ),
        ],
      ),
      body: taskList.when(
        data: (tasks) {
          final enableSwipeToDelete = ref.watch(swipeToDeleteEnabledProvider);
          final enableSwipeToMarkDone = ref.watch(
            swipeToMarkDoneEnabledProvider,
          );

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Dismissible(
                key: ValueKey(
                  task.id ?? task.hashCode,
                ), // fallback if id is null
                direction: (enableSwipeToDelete && enableSwipeToMarkDone)
                    ? DismissDirection.horizontal
                    : enableSwipeToDelete
                    ? DismissDirection.startToEnd
                    : enableSwipeToMarkDone
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.green,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Confirm delete
                    return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm Deletion"),
                              content: const Text(
                                "Are you sure you want to delete this task?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            );
                          },
                        ) ??
                        false;
                  } else if (direction == DismissDirection.endToStart) {
                    // Confirm mark done
                    return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Mark as Done"),
                              content: const Text(
                                "Are you sure you want to mark this task as done?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Done"),
                                ),
                              ],
                            );
                          },
                        ) ??
                        false;
                  }
                  return false;
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await ref.read(todoServiceProvider).deleteTodo(task.id!);
                  } else if (direction == DismissDirection.endToStart) {
                    await ref
                        .read(todoServiceProvider)
                        .updateTodo(task.copyWith(completed: true));
                  }
                  // ignore: unused_result
                  ref.refresh(taskListProvider);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.completed,
                      onChanged: (bool? newValue) async {
                        if (newValue == null) return;
                        await ref
                            .read(todoServiceProvider)
                            .updateTodo(task.copyWith(completed: newValue));
                        // ignore: unused_result
                        ref.refresh(taskListProvider);
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color:
                            (!task.completed &&
                                task.deadline.isBefore(DateTime.now()))
                            ? Colors.red
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy - hh:mm a').format(task.deadline),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await ref
                            .read(todoServiceProvider)
                            .deleteTodo(task.id!);
                        // ignore: unused_result
                        ref.refresh(taskListProvider);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );

    if (result != null) {
      await ref.read(todoServiceProvider).addTodo(result);
      await NotificationService.scheduleNotification(
        id: result.hashCode,
        title: 'Task Reminder',
        body: 'Your task "${result.title}" is due in 1 hour.',
        scheduledTime: result.deadline.subtract(const Duration(hours: 1)),
      );
      // ignore: unused_result
      ref.refresh(taskListProvider);
    }
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: authState.when(
          data: (user) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (user?.userMetadata?['picture'] != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(user!.userMetadata!['picture']!),
                  radius: 40,
                ),
              const SizedBox(height: 16),
              Text(user?.userMetadata?['name'] ?? user?.email ?? "Not logged in"),
              const SizedBox(height: 8),
              Text(user?.email ?? ""),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text(error.toString()),
        ),
      ),
    );
  }
}
