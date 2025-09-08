import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tickit/models/task.dart';

class TodoService {
  final _client = Supabase.instance.client;

  Future<List<Task>> getTodos() async {
    final data = await _client.from('todos').select() as List;
    return data.map((e) => Task.fromJson(e)).toList();
  }

  Future<void> addTodo(Task task) async {
    await _client.from('todos').insert(task.toJson()..remove('id'));
  }

  Future<void> updateTodo(Task task) async {
    await _client.from('todos').update(task.toJson()).eq('id', task.id!);
  }

  Future<void> deleteTodo(String id) async {
    await _client.from('todos').delete().eq('id', id);
  }
}
