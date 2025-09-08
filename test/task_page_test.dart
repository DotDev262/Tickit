
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickit/home/task_page.dart';
import 'package:tickit/models/task.dart';
import 'package:tickit/services/todo_service.dart';

class MockTodoService implements TodoService {
  @override
  Future<List<Task>> getTodos() async {
    return [
      Task(
        id: '1',
        title: 'Test Task 1',
        deadline: DateTime.now(),
        completed: false,
        userId: '1',
      ),
      Task(
        id: '2',
        title: 'Test Task 2',
        deadline: DateTime.now(),
        completed: true,
        userId: '1',
      ),
    ];
  }

  @override
  Future<void> addTodo(Task task) async {}

  @override
  Future<void> deleteTodo(String id) async {}

  @override
  Future<void> updateTodo(Task task) async {}
}

void main() {
  testWidgets('TaskPage displays a list of tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoServiceProvider.overrideWithValue(MockTodoService()),
        ],
        child: const MaterialApp(
          home: TaskPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Task 1'), findsOneWidget);
    expect(find.text('Test Task 2'), findsOneWidget);
  });
}
