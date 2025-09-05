import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickit/models/task.dart';
import 'package:tickit/exceptions/todo_service_exception.dart'; // Import custom exception

class TodoService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> getTodos() async {
    try {
      final response = await _client
          .from('todos')
          .select()
          .eq('user_id', _client.auth.currentUser!.id)
          .order('deadline', ascending: true);

      return (response as List).map((e) => Task.fromJson(e)).toList();
    } catch (e) {
      throw TodoServiceException('Failed to fetch todos', originalError: e);
    }
  }

  Future<void> addTodo(Task task) async {
    try {
      await _client.from('todos').insert({
        'title': task.title,
        'deadline': task.deadline.toIso8601String(),
        'user_id': _client.auth.currentUser!.id,
        'completed': task.completed,
      });
    } catch (e) {
      throw TodoServiceException('Failed to add todo', originalError: e);
    }
  }

  Future<void> updateTodo(Task task) async {
    try {
      await _client.from('todos').update({
        'title': task.title,
        'deadline': task.deadline.toIso8601String(),
        'completed': task.completed,
      }).eq('id', task.id!);
    } catch (e) {
      throw TodoServiceException('Failed to update todo', originalError: e);
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _client.from('todos').delete().eq('id', id);
    } catch (e) {
      throw TodoServiceException('Failed to delete todo', originalError: e);
    }
  }
}