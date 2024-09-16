import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'todo.dart';

final todoListProvider = NotifierProvider<TodoList, List<Todo>>(TodoList.new);

enum TodoListFilter {
  all,
  active,
  completed,
}

final todoListFilter = StateProvider((_) => TodoListFilter.all);

final filteredTodos = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoListFilter);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoListFilter.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilter.all:
      return todos;
  }
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends HookConsumerWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodos);
    final newTodoController = useTextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const Text(
              "Todo qo'shish",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: newTodoController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Yangi todo',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ref.read(todoListProvider.notifier).add(newTodoController.text);
                newTodoController.clear();
              },
              child: const Text("Qo'shish"),
            ),
            const SizedBox(height: 20),
            const Text(
              "Todo'lar",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            for (var todo in todos) ...[
              const Divider(height: 0),
              Dismissible(
                key: ValueKey(todo.id),
                onDismissed: (_) {
                  ref.read(todoListProvider.notifier).remove(todo);
                },
                child: ProviderScope(
                  overrides: [
                    _currentTodo.overrideWithValue(todo),
                  ],
                  child: const TodoItem(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final _currentTodo = Provider<Todo>((ref) => throw UnimplementedError());

class TodoItem extends HookConsumerWidget {
  const TodoItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(_currentTodo);
    final textEditingController = useTextEditingController();
    textEditingController.text = todo.description;

    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        onChanged: (value) {
          ref.read(todoListProvider.notifier).toggle(todo.id);
        },
      ),
      title: TextField(
        controller: textEditingController,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      trailing: IconButton.outlined(
        onPressed: () {
          ref
              .read(todoListProvider.notifier)
              .edit(id: todo.id, description: textEditingController.text);
        },
        icon: const Icon(Icons.save),
      ),
    );
  }
}
