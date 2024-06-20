import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'students.dart';

List<CameraDescription> cameras = [];
var dbHelper = DatabaseHelper();
final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

List<String> answer_options = ['A', 'B', 'C', 'D', 'E'];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optik Okuyucu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Optik Okuyucu - Testler'),
    );
  }
}

Future<Database> openMyDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'my_database.db');
  final database = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Create tables here
    },
  );
  return database;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> testList = [];

  @override
  void initState() {
    super.initState();
    dbHelper.getRows(table: 'tests').then((value) {
      setState(() {
        testList = value;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshTestList();
  }

  Future<void> refreshTestList() async {
    final updatedList = await dbHelper.getRows(table: 'tests');
    setState(() {
      testList = updatedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: testList.length,
        itemBuilder: (context, index) {
          int id = testList[index]['id'];
          return Card(
            child: ListTile(
                title: Text(testList[index]['name']),
                subtitle: Text('${testList[index]['question_count']} Soru'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.white), // Set the background color here
                      ),
                      onPressed: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        StudentsPage(testId: id)))
                            .then((value) => refreshTestList());
                      },
                      icon: Icon(Icons.school),
                      label: Text('Öğrenciler'),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 2), // Add padding here
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
                                            TestDetailsPage(id: id)))
                                .then((value) => refreshTestList());
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 2), // Add padding here
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
                                      '${testList[index]['name']} adlı testi silmek istediğinizden emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        await dbHelper
                                            .delete('tests', 'id=?', [id]);
                                        await dbHelper.delete('student_answers',
                                            'test_id=?', [id]);
                                        Navigator.of(context).pop();
                                        refreshTestList();
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
                  MaterialPageRoute(builder: (context) => TestDetailsPage()))
              .then((value) {
            if (value == true) {
              refreshTestList();
            }
          });
        },
        tooltip: 'Increment',
        icon: const Icon(Icons.add),
        label: Text('Yeni Test Ekle'),
      ),
    );
  }
}

class TestDetailsPage extends StatefulWidget {
  final int? id;

  TestDetailsPage({Key? key, this.id}) : super(key: key);

  @override
  _TestDetailsPageState createState() => _TestDetailsPageState();
}

class _TestDetailsPageState extends State<TestDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController questionCountController = TextEditingController();

  var answerValues = [];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      dbHelper
          .getRows(table: 'tests', where: 'id = ${widget.id}')
          .then((value) {
        setState(() {
          nameController.text = value[0]['name'];
          questionCountController.text = value[0]['question_count'].toString();
          answerValues = jsonDecode(value[0]['correct_answers']);
        });
      });
    } else {
      answerValues = List<String?>.filled(100, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(nameController.text == '' ? 'Yeni Test' : nameController.text),
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
                  labelText: 'Test Adı',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: questionCountController,
                decoration: InputDecoration(
                  labelText: 'Soru Sayısı',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.id != null
                          ? ElevatedButton(
                              onPressed: () {
                                int questionCount = int.tryParse(
                                        questionCountController.text) ??
                                    0;
                                if (questionCount == 0) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Uyarı'),
                                        content: const Text(
                                            'Soru bulunamadı. Önce soru sayısını girin.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Tamam'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                      builder: (BuildContext context,
                                          StateSetter setState) {
                                        return ListView.builder(
                                          itemCount: questionCount,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              title: Text('Soru ${index + 1}'),
                                              trailing: DropdownButton<String>(
                                                value: answerValues[index],
                                                hint: const Text('Doğru Cevap'),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    answerValues[index] =
                                                        newValue;
                                                  });
                                                },
                                                items: answer_options.map<
                                                    DropdownMenuItem<String>>(
                                                  (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  },
                                                ).toList(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: const Text('Doğru Cevapları Düzenle'),
                            )
                          : const SizedBox(),
                      ElevatedButton(
                        onPressed: () async {
                          // Handle form submission
                          String name = nameController.text;
                          int questionCount =
                              int.tryParse(questionCountController.text) ?? 0;
                          if (widget.id != null) {
                            await dbHelper.update('tests', {
                              'id': widget.id,
                              'name': name,
                              'question_count': questionCount,
                              'correct_answers': jsonEncode(answerValues),
                            });
                          } else {
                            await dbHelper.insert('tests', {
                              'name': name,
                              'question_count': questionCount,
                              'correct_answers': jsonEncode(answerValues),
                            });
                          }
                          Navigator.pop(context, true);
                        },
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
