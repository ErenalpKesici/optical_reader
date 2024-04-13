import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';

import 'database_helper.dart';

List<CameraDescription> cameras = [];
var dbHelper = DatabaseHelper();
final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Optik Okuyucu'),
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
              subtitle:
                  Text('Soru Sayısı: ${testList[index]['question_count']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DetailsPage(id: id)))
                          .then((value) => refreshTestList());
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
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
                                  await dbHelper.delete('tests', id);
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
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DetailsPage()))
              .then((value) {
            if (value == true) {
              refreshTestList();
            }
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DetailsPage extends StatefulWidget {
  final int? id;

  DetailsPage({Key? key, this.id}) : super(key: key);

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController questionCountController = TextEditingController();

  var answerValues = [];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      dbHelper
          .getRows(table: 'tests', where: 'id = ' + widget.id.toString())
          .then((value) {
        setState(() {
          nameController.text = value[0]['name'];
          questionCountController.text = value[0]['question_count'].toString();
        });
      });
    }
    answerValues = List<String?>.filled(123, null);
  }

  Future<String> getTextFromImage(pickedFile) async {
    String text = '';
    if (pickedFile != null) {
      final image = Image.file(File(pickedFile.path));
      final RecognizedText recognizedText = await textRecognizer
          .processImage(InputImage.fromFile(File(pickedFile.path)));
      text = recognizedText.text;
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details Page'),
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
                  labelText: 'Adı',
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.id != null
                        ? ElevatedButton(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await showDialog<PickedFile>(
                                context: context,
                                builder: (BuildContext context) {
                                  return SimpleDialog(
                                    title: const Text(
                                        'Take a photo or choose from gallery'),
                                    children: <Widget>[
                                      SimpleDialogOption(
                                        onPressed: () async {
                                          final pickedFile =
                                              await picker.pickImage(
                                                  source: ImageSource.camera);
                                          String text = await getTextFromImage(
                                              pickedFile);
                                          print(text);
                                        },
                                        child: const Text('Take a photo'),
                                      ),
                                      SimpleDialogOption(
                                        onPressed: () async {
                                          final pickedFile =
                                              await picker.pickImage(
                                                  source: ImageSource.gallery);
                                          String text = await getTextFromImage(
                                              pickedFile);
                                          print(text);
                                        },
                                        child:
                                            const Text('Choose from gallery'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (pickedFile != null) {
                                final image = Image.file(File(pickedFile.path));
                                // Do something with the image
                              }
                            },
                            child: const Text('Shoot or Select Image'),
                          )
                        : const SizedBox(),
                    widget.id != null
                        ? ElevatedButton(
                            onPressed: () {
                              int questionCount =
                                  int.tryParse(questionCountController.text) ??
                                      0;
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
                                              items: <String>[
                                                'A',
                                                'B',
                                                'C',
                                                'D',
                                                'E'
                                              ].map<DropdownMenuItem<String>>(
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
                            child: const Icon(Icons.question_answer),
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
                          });
                        } else
                          await dbHelper.insert('tests', {
                            'name': name,
                            'question_count': questionCount,
                          });
                        Navigator.pop(context, true);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
