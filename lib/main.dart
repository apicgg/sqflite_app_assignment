import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sqflite Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  late Database _database;
  List<Map<String, dynamic>> _persons = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  void _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'person_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE persons(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
        );
      },
      version: 1,
    );

    _refreshPersons();
  }

  void _refreshPersons() async {
    final persons = await _database.query('persons');
    setState(() {
      _persons = persons;
    });
  }

  void _insertPerson(String name, int age) async {
    await _database.insert(
      'persons',
      {'name': name, 'age': age},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _refreshPersons();
  }

  void _updatePerson(int id, String name, int age) async {
    await _database.update(
      'persons',
      {'name': name, 'age': age},
      where: 'id = ?',
      whereArgs: [id],
    );
    _refreshPersons();
  }

  void _deletePerson(int id) async {
    await _database.delete(
      'persons',
      where: 'id = ?',
      whereArgs: [id],
    );
    _refreshPersons();
  }

  @override
  void dispose() {
    _database.close();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Sqflite Demo'),
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an age';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _insertPerson(
                            _nameController.text,
                            int.parse(_ageController.text),
                          );
                          _nameController.clear();
                          _ageController.clear();
                        }
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _persons.length,
              itemBuilder: (context, index) {
                final person = _persons[index];
                return ListTile(
                  title: Text(person['name']),
                  subtitle: Text('${person['age']} years old'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deletePerson(person['id']);
                    },
                  ),
                  onTap: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) {
                        final nameController =
                            TextEditingController(text: person['name']);
                        final ageController = TextEditingController(
                            text: person['age'].toString());
                        return AlertDialog(
                          title: Text('Edit Person'),
                          content: Form(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a name';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an age';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (Form.of(context)!.validate()) {
                                  _updatePerson(
                                    person['id'],
                                    nameController.text,
                                    int.parse(ageController.text),
                                  );
                                  Navigator.pop(context, true);
                                }
                              },
                              child: Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                    if (result == true) {
                      _refreshPersons();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
