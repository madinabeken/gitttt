import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(TaskApp());

class TaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.grey.shade200,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple,
          elevation: 5,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.purple,
        ),
        cardTheme: CardTheme(
          margin: EdgeInsets.all(8),
          elevation: 5,
          shadowColor: Colors.purple.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: TaskScreen(),
    );
  }
}

class Task {
  String title;
  String description;
  String deadline;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline,
      'isCompleted': isCompleted.toString(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: map['deadline'] ?? '',
      isCompleted: map['isCompleted'] == 'true',
    );
  }
}

class TaskScreen extends StatefulWidget {
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Task> _tasks = [];
  bool _showCompleted = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeTasks();
  }

  Future<void> _initializeTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedTasks = prefs.getStringList('tasks');

    if (storedTasks != null && storedTasks.isNotEmpty) {
      setState(() {
        _tasks = storedTasks.map((taskString) {
          final Map<String, dynamic> map = taskString
              .split(';')
              .asMap()
              .map((_, value) {
            final parts = value.split(':');
            return MapEntry(parts[0], parts[1]);
          })
              .cast<String, dynamic>();
          return Task.fromMap(map);
        }).toList();
      });
    } else {
      setState(() {
        _tasks = [
          Task(
            title: "Flutter UI құрастыру",
            description: "Flutter-да экрандар арасындағы ауысуларды жасау.",
            deadline: "2024-11-20",
          ),
          Task(
            title: "Деректер базасы орнату",
            description: "SQL және SharedPreferences көмегімен сақтау жүйесін іске қосу.",
            deadline: "2024-11-30",
          ),
          Task(
            title: "REST API қосу",
            description: "Flutter-да HTTP сұраулармен жұмыс істеу.",
            deadline: "2024-12-15",
          ),
          Task(
            title: "UI тестілеу",
            description: "Барлық экрандарды толығымен тексеру.",
            deadline: "2025-01-30",
          ),
        ];
      });
      _saveTasks();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskStrings = _tasks
        .map((task) => task.toMap().entries.map((e) => '${e.key}:${e.value}').join(';'))
        .toList();
    await prefs.setStringList('tasks', taskStrings);
  }

  Future<void> _addOrEditTask({int? index}) async {
    final isEdit = index != null;
    if (isEdit) {
      _titleController.text = _tasks[index].title;
      _descriptionController.text = _tasks[index].description;
      _selectedDate = DateTime.parse(_tasks[index].deadline);
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _selectedDate = null;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          isEdit ? 'Тапсырманы өңдеу' : 'Тапсырма қосу',
          style: TextStyle(color: Colors.purple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Атау',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Сипаттама',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Күн таңдалмаған'
                        : 'Күні: ${_selectedDate!.toIso8601String().split('T').first}',
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Text('Күн таңдау'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Болдырмау'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty &&
                  _descriptionController.text.isNotEmpty &&
                  _selectedDate != null) {
                setState(() {
                  if (isEdit) {
                    _tasks[index!] = Task(
                      title: _titleController.text,
                      description: _descriptionController.text,
                      deadline: _selectedDate!.toIso8601String().split('T').first,
                      isCompleted: _tasks[index!].isCompleted,
                    );
                  } else {
                    _tasks.add(Task(
                      title: _titleController.text,
                      description: _descriptionController.text,
                      deadline: _selectedDate!.toIso8601String().split('T').first,
                    ));
                  }
                });
                _saveTasks();
                Navigator.of(context).pop();
              }
            },
            child: Text(isEdit ? 'Сақтау' : 'Қосу'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTaskCompletion(int index) async {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((task) => task.isCompleted == _showCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Тапсырмалар тізімі'),
            SizedBox(width: 10),
            Switch(
              value: _showCompleted,
              onChanged: (value) {
                setState(() {
                  _showCompleted = value;
                });
              },
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final taskIndex = _tasks.indexOf(task);

                return Card(
                  color: task.isCompleted ? Colors.green.shade50 : Colors.white,
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('${task.description}\n${task.deadline}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _addOrEditTask(index: taskIndex),
                        ),
                        IconButton(
                          icon: Icon(
                            task.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                          ),
                          onPressed: () => _toggleTaskCompletion(taskIndex),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _tasks.removeAt(taskIndex);
                            });
                            _saveTasks();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTask(),
        child: Icon(Icons.add),
      ),
    );
  }
}
