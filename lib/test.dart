import 'package:flutter/material.dart';
import './database_helper.dart';

void main() => runApp(PetReminderApp());

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

class Task {
  final String title;
  final String description;
  bool isDaily;
  DateTime? date;
  TimeOfDay? time;
  Pet pet;

  Task(
      {required this.title,
      required this.description,
      required this.isDaily,
      this.date,
      this.time,
      required this.pet});

  // Convert a task into a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isDaily': isDaily,
      'date': date,
      'time': time,
      'pet': pet
    };
  }

  // Create a task from a Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
        title: map['title'],
        description: map['description'],
        isDaily: map['isDaily'],
        date: map['date'],
        time: map['time'],
        pet: map['pet']);
  }
}

class PetReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Reminder',
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

  void _fetchTasksFromDatabase() async {
    final allTasks = await dbHelper.queryAll(DatabaseHelper.tableTasks);
    setState(() {
      tasksFromDatabase = allTasks.map((e) => Task.fromMap(e)).toList();
    });
  }

  void _addPetToDatabase(String petName, int petAge) async {
    Pet newPet = Pet(name: petName, age: petAge);
    await dbHelper.insert(newPet.toMap(), DatabaseHelper.tablePets);
  }

  void _addTaskToDatabase(String title, String description, bool isDaily,
      DateTime? date, TimeOfDay? time, Pet pet) async {
    Task newTask = Task(
        title: title,
        description: description,
        isDaily: isDaily,
        date: date,
        time: time,
        pet: pet);
    await dbHelper.insert(newTask.toMap(), DatabaseHelper.tableTasks);
  }

  void _showAddPetDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Pet"),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Pet Name"),
                    ),
                    TextField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: "Pet Age"),
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
                  child: Text("Add")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel")),
            ],
          );
        });
  }

  void _showAddDailyTaskDialog() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    bool isDaily = true;
    TimeOfDay? taskTime;
    DateTime? taskDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Use as little space as needed
                  children: <Widget>[
                    TextFormField(
                      onChanged: (value) => title = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Title can\'t be empty' : null,
                      decoration: InputDecoration(labelText: 'Task Title'),
                    ),
                    TextFormField(
                      onChanged: (value) => description = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Description can\'t be empty' : null,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    CheckboxListTile(
                      title: Text('Is Daily?'),
                      value: isDaily,
                      onChanged: (bool? value) {
                        setState(() {
                          isDaily = value!;
                        });
                      },
                    ),
                    if (!isDaily) ...[
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
                        child: Text("Select Date"),
                      ),
                      if (taskDate != null)
                        Text(
                            "Selected Date: ${taskDate!.toLocal().toString().split(' ')[0]}")
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
                      child: Text("Select Time"),
                    ),
                    if (taskTime != null)
                      Text("Selected Time: ${taskTime!.format(context)}"),
                    DropdownButton<Pet>(
                      hint: Text("Select a pet"),
                      value: selectedPet,
                      onChanged: (Pet? pet) {
                        setState(() {
                          selectedPet = pet;
                        });
                      },
                      items: petsFromDatabase.map((Pet pet) {
                        return DropdownMenuItem<Pet>(
                          value: pet,
                          child: Text("${pet.name}, ${pet.age} years"),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() && selectedPet != null) {
                  _formKey.currentState!.save();
                  setState(() {
                    Task newTask = Task(
                      title: title,
                      description: description,
                      isDaily: isDaily,
                      time: taskTime,
                      date: taskDate,
                      pet: selectedPet!,
                    );
                    tasksFromDatabase.add(newTask);
                  });
                  var taskRow = {
                    DatabaseHelper.columnTaskName: title,
                    DatabaseHelper.columnTaskDescription: description,
                    DatabaseHelper.columnIsDaily: isDaily
                        ? 1
                        : 0, // Add this line to set the isDaily column
                    // ... add more columns as necessary ...
                  };
                  await dbHelper.insert(taskRow, DatabaseHelper.tableTasks);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Task'),
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
            Text('Pet Reminder', style: TextStyle(color: Color(0xFFFF8BB4))),
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
                value: selectedPet,
                items: petsFromDatabase.map((Pet pet) {
                  return DropdownMenuItem<Pet>(
                    value: pet,
                    child: Text(pet.name),
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
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
              ),
              DropdownButton<Task>(
                hint: Text("Select a task"),
                value: selectedTask,
                onChanged: (Task? task) {
                  setState(() {
                    selectedTask = task;
                  });
                },
                items: tasksFromDatabase.map((Task task) {
                  return DropdownMenuItem<Task>(
                    value: task,
                    child: Text(
                        "${task.title} for ${task.pet.name} | ${task.time?.format(context)}"),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed:
                    _showAddDailyTaskDialog, // You'd define this method to show a dialog for adding tasks
                child: Icon(Icons.add),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
