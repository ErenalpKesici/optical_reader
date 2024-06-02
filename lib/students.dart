import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optical_reader/helper.dart';
import 'package:optical_reader/main.dart';

class StudentsPage extends StatefulWidget {
  final int? testId;

  StudentsPage({Key? key, this.testId}) : super(key: key);

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();

  List<Map<String, dynamic>> studentList = [];

  @override
  void initState() {
    super.initState();
    if (widget.testId != null) {
      dbHelper
          .getRows(table: 'students', where: 'id = ${widget.testId}')
          .then((value) {
        setState(() {
          refreshstudentList();
        });
      });
    }
  }

  Future<void> refreshstudentList() async {
    final updatedList = await dbHelper.getRows(table: 'students');
    setState(() {
      studentList = updatedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build your widget here
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğrenciler'),
      ),
      body: ListView.builder(
        itemCount: studentList.length,
        itemBuilder: (context, index) {
          int id = studentList[index]['id'];
          return Card(
            child: ListTile(
                title: Text(studentList[index]['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StudentAnswersPage(
                                    studentId: studentList[index]['id'],
                                    testId: widget.testId ?? 0)));
                      },
                      icon: Icon(Icons.question_answer_outlined),
                      label: Text('Cevapları'),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Material(
                        elevation: 1,
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.blue.withOpacity(0.5),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            StudentDetailsPage(id: id)))
                                .then((value) => refreshstudentList());
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Material(
                        elevation: 1,
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.red.withOpacity(0.5),
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Silme İşlemini Onayla'),
                                  content: Text(
                                      '${studentList[index]['name']} adlı ögrenciyi silmek istediğinizden emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        await dbHelper.delete('students', id);
                                        Navigator.of(context).pop();
                                        refreshstudentList();
                                      },
                                      child: Text('Sil'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('İptal'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => StudentDetailsPage()))
              .then((value) {
            if (value == true) {
              refreshstudentList();
            }
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class StudentDetailsPage extends StatefulWidget {
  final int? id;

  StudentDetailsPage({Key? key, this.id}) : super(key: key);
  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final TextEditingController nameController = TextEditingController();

  void initState() {
    super.initState();
    if (widget.id != null) {
      dbHelper
          .getRows(table: 'students', where: 'id = ${widget.id}')
          .then((value) {
        setState(() {
          nameController.text = value[0]['name'];
        });
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (widget.id != null) {
                    await dbHelper.update('students', {
                      'id': widget.id,
                      'name': nameController.text,
                    });
                  } else {
                    await dbHelper.insert('students', {
                      'name': nameController.text,
                    });
                  }
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentAnswersPage extends StatefulWidget {
  final int studentId;
  final int testId;

  StudentAnswersPage({Key? key, required this.studentId, required this.testId})
      : super(key: key);

  @override
  _StudentAnswersPageState createState() => _StudentAnswersPageState();
}

class _StudentAnswersPageState extends State<StudentAnswersPage> {
  List<String> questions = [];
  List<String> answers = [];
  List<dynamic> correctAnswers = [];

  @override
  void initState() {
    super.initState();
    fetchAnswers();
  }

  Future<void> fetchAnswers() async {
    final studentAnswers = await dbHelper.getRows(
        table: 'student_answers',
        where:
            'student_id = ${widget.studentId} AND test_id = ${widget.testId}');
    final tests =
        await dbHelper.getRows(table: 'tests', where: 'id = ${widget.testId}');
    if (tests.isNotEmpty) {
      correctAnswers = jsonDecode(tests[0]['correct_answers']);
    }
    if (studentAnswers.isNotEmpty) {
      final resultsString = studentAnswers[0]['results'];
      final results = jsonDecode(resultsString);
      for (var result in results) {
        questions.add(result['question']);
        answers.add(result['answer']);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cevapları'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await showDialog<PickedFile>(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: const Text('Fotoğraf çek veya galeriden seç'),
                        children: <Widget>[
                          SimpleDialogOption(
                            onPressed: () async {
                              final pickedFile = await picker.pickImage(
                                  source: ImageSource.camera);
                              await insertAnswersFromImage(
                                  pickedFile, widget.studentId, widget.testId);
                            },
                            child: const Text('Fotoğraf çek'),
                          ),
                          SimpleDialogOption(
                            onPressed: () async {
                              final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery);
                              await insertAnswersFromImage(
                                  pickedFile, widget.studentId, widget.testId);
                            },
                            child: const Text('Galeriden seç'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Fotoğraf Okut')),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(
                      label: Text(
                        'Soru #',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Cevap',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    DataColumn(
                      label: Text('Doğru Cevap',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ],
                  rows: List<DataRow>.generate(
                    questions.length,
                    (index) => generateDataRow(
                        index, questions, answers, correctAnswers),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

DataRow generateDataRow(int index, List<String> questions, List<String> answers,
    List<dynamic> correctAnswers) {
  // You can run any code here before creating each DataCell

  final correctAnswer = correctAnswers[index] ?? '';

  return DataRow(
    cells: <DataCell>[
      DataCell(Text(questions[index])),
      DataCell(
        Row(
          children: [
            Text(answers[index]),
            if (answers[index] == correctAnswer)
              Icon(Icons.check, color: Colors.green),
          ],
        ),
      ),
      DataCell(Text(correctAnswer)),
    ],
  );
}