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
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TestResultsPage(testId: widget.testId)));
            },
          ),
        ],
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
                                        await dbHelper
                                            .delete('students', 'id=?', [id]);
                                        await dbHelper.delete('student_answers',
                                            'student_id=?', [id]);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => StudentDetailsPage()))
              .then((value) {
            if (value == true) {
              refreshstudentList();
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Öğrenci Ekle'),
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
        title: Text(
            nameController.text == '' ? 'Yeni Öğrenci' : nameController.text),
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
                  labelText: 'Öğrenci İsmi',
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
                child: Text('Kaydet'),
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

  int correctAnswerCount = 0;
  int wrongAnswerCount = 0;
  int emptyAnswerCount = 0;
  int score = 0;

  String studentName = '';

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
      for (var studentAnswer in studentAnswers) {
        final resultsString = studentAnswer['results'];
        final results = jsonDecode(resultsString);
        if (results.isEmpty) {
          continue;
        } else {
          for (var result in results) {
            questions.add(result['question']);
            answers.add(result['answer']);
          }
          break;
        }
      }
    }
    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == correctAnswers[i]) {
        correctAnswerCount++;
      } else if (answers[i].isEmpty) {
        emptyAnswerCount++;
      } else {
        wrongAnswerCount++;
      }
    }
    score = correctAnswerCount *
        100 ~/
        (questions.length < 1 ? 1 : questions.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> answersButtons = [
      ElevatedButton.icon(
        icon: Icon(Icons.camera_alt),
        label: Text('Cevapları Oku'),
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
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.camera);
                      await insertAnswersFromImage(
                          pickedFile, widget.studentId, widget.testId);
                      Navigator.pop(context);
                      setState(() {
                        fetchAnswers();
                      });
                    },
                    child: const Text('Fotoğraf çek'),
                  ),
                  SimpleDialogOption(
                    onPressed: () async {
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.gallery);
                      await insertAnswersFromImage(
                          pickedFile, widget.studentId, widget.testId);
                      Navigator.pop(context);
                      setState(() {
                        fetchAnswers();
                      });
                    },
                    child: const Text('Galeriden seç'),
                  ),
                ],
              );
            },
          );
        },
      ),
    ];
    if (questions.length != 0) {
      answersButtons.add(ElevatedButton.icon(
        icon: Icon(Icons.delete),
        label: Text('Cevapları Sil'),
        onPressed: () async {
          await dbHelper.delete('student_answers', 'student_id=? AND test_id=?',
              [widget.studentId, widget.testId]);
          setState(() {
            questions = [];
            answers = [];
            correctAnswers = [];
            correctAnswerCount = 0;
            wrongAnswerCount = 0;
            emptyAnswerCount = 0;
            score = 0;
          });
        },
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Ögrenci Cevapları'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Örnek Optik Form Formatı'),
                    content: Image.asset('assets/example_test.png'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Kapat'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: answersButtons,
            ),
            if (questions.isNotEmpty) const Divider(),
            if (questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Doğru Cevap: $correctAnswerCount'),
                        Text('Yanlış Cevap: $wrongAnswerCount'),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Puanı: $score',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (questions.isNotEmpty)
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
  final correctAnswer = correctAnswers[index] ?? '-';
  return DataRow(
    color: MaterialStateColor.resolveWith((states) {
      if (answers[index] == correctAnswer) {
        return Colors.green.withOpacity(0.3);
      } else if (correctAnswer != '') {
        return Colors.red.withOpacity(0.3);
      } else {
        return Colors.grey.withOpacity(0.3);
      }
    }),
    cells: <DataCell>[
      DataCell(
        Container(
          child: Text(questions[index]),
        ),
      ),
      DataCell(
        Container(
          child: Text(answers[index]),
        ),
      ),
      DataCell(
        Container(
          child: Text(correctAnswer),
        ),
      ),
    ],
  );
}

class TestResultsPage extends StatefulWidget {
  final int? testId;

  TestResultsPage({Key? key, this.testId}) : super(key: key);

  @override
  _TestResultsPageState createState() => _TestResultsPageState();
}

class _TestResultsPageState extends State<TestResultsPage> {
  List<Map<String, dynamic>> testResults = [];

  @override
  void initState() {
    super.initState();
    fetchTestResults();
  }

  void fetchTestResults() async {
    final testResults = await dbHelper.getJoinRows(
        tables: ['students', 'student_answers', 'tests'],
        on: 'students.id = student_answers.student_id AND tests.id = student_answers.test_id',
        where: 'student_answers.test_id = ${widget.testId}',
        columns: [
          'students.name',
          'student_answers.results',
          'tests.correct_answers',
        ]);
    setState(() {
      this.testResults = testResults;
    });
  }

  int calculateTotalScore(String resultsJson, String correctAnswersJson) {
    final results = jsonDecode(resultsJson);
    final correctAnswers = jsonDecode(correctAnswersJson);
    int score = 0;
    for (int i = 0; i < results.length; i++) {
      if (results[i]['answer'] == correctAnswers[i]) {
        score++;
      }
    }
    double percentage = (score / results.length) * 100;
    return percentage.toInt();
  }

  @override
  Widget build(BuildContext context) {
    if (testResults.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Test Sonuçları'),
        ),
        body: Center(
          child: Text('Sonuç bulunamadı.'),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Test Sonuçları'),
        ),
        body: ListView.builder(
          itemCount: testResults.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(testResults[index]['name']),
                subtitle: Text(
                  'Puanı: ${calculateTotalScore(testResults[index]['results'], testResults[index]['correct_answers'])}',
                ),
              ),
            );
          },
        ),
      );
    }
  }
}
