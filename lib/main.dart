import 'package:flutter/material.dart';
import './database_helper.dart';

void main() {
  runApp(PetReminderApp());
}

class Pet {
  final String name;
  final int age;
  final int? id; // Optional: if you're using an ID from the database

  Pet({required this.name, required this.age, this.id});

  // Convert a Pet into a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'id': id // If using ID
    };
  }

  // Create a Pet from a Map
  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(name: map['name'], age: map['age'], id: map['id'] // If using ID
        );
  }
}

Map<int, Pet> petMap = {};

class Task {
  final String name;
  final String description;
  final int isDaily;
  DateTime? date;
  TimeOfDay? time;
  Pet petId;
  final int? id; // Optional: if you're using an ID from the database

  Task(
      {required this.name,
      required this.description,
      required this.isDaily,
      this.date,
      this.time,
      required this.petId,
      this.id});

  // Convert a task into a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isDaily': isDaily,
      'date': date?.toIso8601String(),
      'time': time != null ? '${time!.hour}:${time!.minute}' : null,
      'petId': petId.id,
      'id': id // If using ID
    };
  }

  // Create a task from a Map
  factory Task.fromMap(Map<String, dynamic> map) {
    // Convert string to DateTime
    DateTime? restoredDate;
    if (map['date'] != null) {
      restoredDate = DateTime.parse(map['date']);
    }

    // Convert string to TimeOfDay
    TimeOfDay? restoredTime;
    if (map['time'] != null) {
      List<String> timeParts = (map['time'] as String).split(':');
      restoredTime = TimeOfDay(
          hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }

    // Fetch the corresponding Pet from petMap based on its ID
    Pet associatedPet = petMap[map['petId']] ?? Pet(name: "", age: 0);

    return Task(
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        isDaily: map['isDaily'],
        date: restoredDate,
        time: restoredTime,
        petId: associatedPet,
        id: map['id']);
  }
}

class PetReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'treats&tracks',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dbHelper = DatabaseHelper.instance;

  List<Pet> petsFromDatabase = [];
  Pet? selectedPet;
  List<Task> tasksFromDatabase = [];
  Task? selectedTask;

  final TextEditingController _descriptionController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPetsFromDatabase();
    _fetchTasksFromDatabase();
  }

  void _fetchPetsFromDatabase() async {
    final allPets = await dbHelper.queryAll(DatabaseHelper.tablePets);
    setState(() {
      petsFromDatabase = allPets.map((e) => Pet.fromMap(e)).toList();
    });
  }

  void _preloadPets() async {
    final allPets = await dbHelper.queryAll(DatabaseHelper.tablePets);
    petMap = Map.fromIterable(allPets.map((e) => Pet.fromMap(e)),
        key: (pet) => pet.id, value: (pet) => pet);
  }

  Future<Map<int, Pet>> _fetchPetsMap() async {
    final allPets = await dbHelper.queryAll(DatabaseHelper.tablePets);
    var petMap = <int, Pet>{};
    for (var petData in allPets) {
      var pet = Pet.fromMap(
          petData); // Assuming you have a `fromMap` method in your Pet class
      petMap[pet.id!] = pet;
    }
    return petMap;
  }

  void _fetchTasksFromDatabase() async {
    final allTasks = await dbHelper.queryAll(DatabaseHelper.tableTasks);

    List<Task> tasks = [];

    for (var taskMap in allTasks) {
      var task = Task.fromMap(taskMap);

      final petId = taskMap[DatabaseHelper.columnPetFK];
      final List<Map<String, dynamic>> pets =
          await dbHelper.querySpecific(DatabaseHelper.tablePets, petId);

      if (pets.isNotEmpty) {
        task.petId = Pet.fromMap(pets
            .first); // Assuming you have a `fromMap` method in your Pet class
        tasks.add(task);
      }
    }

    setState(() {
      tasksFromDatabase = tasks;
    });
  }

  void _addPetToDatabase(String petName, int petAge) async {
    Pet newPet = Pet(name: petName, age: petAge);
    await dbHelper.insert(newPet.toMap(), DatabaseHelper.tablePets);
  }

  void _addTaskToDatabase(String name, String description, int isDaily,
      DateTime? date, TimeOfDay? time, Pet petId) async {
    Task newTask = Task(
        name: name,
        description: description,
        isDaily: isDaily,
        date: date,
        time: time,
        petId: petId);
    await dbHelper.insert(newTask.toMap(), DatabaseHelper.tableTasks);
  }

  void _showAddPetDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add a pet"),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: "Age"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () async {
                    // Notice the addition of 'async' here
                    if (_nameController.text.isNotEmpty &&
                        _ageController.text.isNotEmpty) {
                      // Prepare data for insertion into the database
                      var row = {
                        DatabaseHelper.columnPetName: _nameController.text,
                        DatabaseHelper.columnPetAge:
                            int.parse(_ageController.text),
                      };

                      // Insert the pet into the database
                      final id =
                          await dbHelper.insert(row, DatabaseHelper.tablePets);

                      // After saving to the database, update your local list
                      setState(() {
                        petsFromDatabase.add(Pet(
                            name: _nameController.text,
                            age: int.parse(_ageController.text),
                            id: id // assuming your Pet model has an 'id' field, if not, you can skip this.
                            ));
                      });

                      //_addPetToDatabase(
                      //    _nameController.text, int.parse(_ageController.text));

                      // Close the dialog
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text("Add pet")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel")),
            ],
          );
        });
  }

  void _showAddDailyTaskDialog() {
    String description = '';
    int isDaily = 1;
    TimeOfDay? taskTime;
    DateTime? taskDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a task'),
          content: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use as little space as needed
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Task'),
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  //TextField(
                  //  controller: _nameController,
                  //  decoration: InputDecoration(labelText: 'Description'),
                  //),
                  CheckboxListTile(
                    title: Text('Daily task'),
                    value: isDaily == 1,
                    onChanged: (bool? value) {
                      setState(() {
                        isDaily = value! ? 1 : 0;
                      });
                    },
                  ),
                  if (!(isDaily == 1)) ...[
                    // DatePicker and TimePicker can be added here
                    ElevatedButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null && pickedDate != taskDate)
                          setState(() {
                            taskDate = pickedDate;
                          });
                      },
                      child: Text("Date"),
                    ),
                    if (taskDate != null)
                      Text(
                          "Date: ${taskDate!.toLocal().toString().split(' ')[0]}")
                  ],
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null && pickedTime != taskTime)
                        setState(() {
                          taskTime = pickedTime;
                        });
                    },
                    child: Text("Time"),
                  ),
                  if (taskTime != null)
                    Text("Time: ${taskTime!.format(context)}"),
                  DropdownButton<Pet>(
                    hint: Text("Pet"),
                    value: selectedPet,
                    onChanged: (Pet? petId) {
                      setState(() {
                        selectedPet = petId;
                      });
                    },
                    items: petsFromDatabase.map((Pet petId) {
                      return DropdownMenuItem<Pet>(
                        value: petId,
                        child: Text("${petId.name}, ${petId.age} years"),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  var row = {
                    DatabaseHelper.columnTaskName: _nameController.text,
                    DatabaseHelper.columnTaskDescription:
                        _descriptionController.text,
                    DatabaseHelper.columnIsDaily: isDaily,
                    DatabaseHelper.columnDate: taskDate?.toIso8601String(),
                    DatabaseHelper.columnTime:
                        '${taskTime!.hour}:${taskTime!.minute}',
                    DatabaseHelper.columnPetFK: selectedPet!.id
                  };

                  // Insert the task into the database
                  final id =
                      await dbHelper.insert(row, DatabaseHelper.tableTasks);

                  // After saving to the database, update your local list
                  setState(() {
                    tasksFromDatabase.add(Task(
                        name: _nameController.text,
                        description: description,
                        isDaily: isDaily,
                        time: taskTime,
                        date: taskDate,
                        petId: selectedPet!,
                        id: id // assuming your Pet model has an 'id' field, if not, you can skip this.
                        ));
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Add task'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFAFCC),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize
              .min, // This ensures the row uses only as much space as it needs.
          children: [
            Image.asset('lib/logo.png',
                height: 30.0,
                width: 30.0,
                fit: BoxFit.cover), // Added width and fit properties
            SizedBox(
                width: 10), // A little spacing between the logo and the title
            Text('treats&tracks', style: TextStyle(color: Color(0xFFFF8BB4))),
          ],
        ),
      ),
      body: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Dropdowns and other UI elements will go here.
              DropdownButton<Pet>(
                hint: Text("Your pets:"),
                value: selectedPet,
                items: petsFromDatabase.map((Pet pet) {
                  return DropdownMenuItem<Pet>(
                    value: pet,
                    child: Text("${pet.name} | ${pet.age}"),
                  );
                }).toList(),
                onChanged: (Pet? newValue) {
                  setState(() {
                    selectedPet = newValue!;
                  });
                },
              ),
              ElevatedButton(
                onPressed: _showAddPetDialog,
                child: Icon(Icons.add),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Color(0xffCDB4DB)),
                ),
              ),
              DropdownButton<Task>(
                hint: Text("Upcoming reminders:"),
                value: selectedTask,
                items: tasksFromDatabase.map((Task task) {
                  return DropdownMenuItem<Task>(
                    value: task,
                    child: Text(
                        "${task.name} | ${task.petId.name} | ${task.date} ${task.time?.format(context)}"),
                  );
                }).toList(),
                onChanged: (Task? task) {
                  setState(() {
                    selectedTask = task;
                  });
                },
              ),
              ElevatedButton(
                onPressed:
                    _showAddDailyTaskDialog, // You'd define this method to show a dialog for adding tasks
                child: Icon(Icons.add),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Color(0xffFFDFEB)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
