import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter/foundation.dart' show immutable;

@immutable
class Todo {
  const Todo({
    required this.description,
    required this.id,
    this.completed = false,
  });

  final int id;  // `id` tipini int qilamiz SQLite uchun
  final String description;
  final bool completed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'completed': completed ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'Todo(id: $id, description: $description, completed: $completed)';
  }
}

class TodoList extends Notifier<List<Todo>> {
  Database? _database;

  Future<Database> _openDb() async {
    if (_database != null) return _database!;
    
    return await openDatabase(
      join(await getDatabasesPath(), 'todo_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, completed INTEGER)',
        );
      },
      version: 1,
    );
  }

  @override
  List<Todo> build() => [];

  Future<void> fetchTodos() async {
    final db = await _openDb();
    final List<Map<String, dynamic>> maps = await db.query('todos');
    state = List.generate(maps.length, (i) {
      return Todo(
        id: maps[i]['id'],
        description: maps[i]['description'],
        completed: maps[i]['completed'] == 1,
      );
    });
  }

  Future<void> add(String description) async {
    final db = await _openDb();

    final id = await db.insert(
      'todos',
      {
        'description': description,
        'completed': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final newTodo = Todo(
      id: id,
      description: description,
      completed: false,
    );

    state = [...state, newTodo];
  }

  Future<void> toggle(int id) async {
    final db = await _openDb();

    final todo = state.firstWhere((todo) => todo.id == id);
    final updatedTodo = Todo(
      id: todo.id,
      description: todo.description,
      completed: !todo.completed,
    );

    await db.update(
      'todos',
      updatedTodo.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    state = [
      for (final todo in state)
        if (todo.id == id) updatedTodo else todo,
    ];
  }

  Future<void> edit({required int id, required String description}) async {
    final db = await _openDb();

    final todo = state.firstWhere((todo) => todo.id == id);
    final updatedTodo = Todo(
      id: todo.id,
      description: description,
      completed: todo.completed,
    );

    await db.update(
      'todos',
      updatedTodo.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    state = [
      for (final todo in state)
        if (todo.id == id) updatedTodo else todo,
    ];
  }

  Future<void> remove(Todo target) async {
    final db = await _openDb();
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [target.id],
    );
    state = state.where((todo) => todo.id != target.id).toList();
  }
}
