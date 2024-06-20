import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optical_reader/main.dart';

Future<File> processImage(File file) async {
  final originalImage = img.decodeImage(file.readAsBytesSync());
  final processedImage = img.grayscale(originalImage!);
  final processedFile = File(file.path)
    ..writeAsBytesSync(img.encodeJpg(processedImage));
  return file;
}

Future<String> insertAnswersFromImage(pickedFile, studentId, testId) async {
  String text = '';
  if (pickedFile != null) {
    final processedFile = await processImage(File(pickedFile.path));
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final inputImage = InputImage.fromFile(processedFile);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    text = recognizedText.text;
    List<String> questions = [];
    List<String> answers = [];
    List<String> lines = text.split('\n');

    final test = await dbHelper.getRow(table: 'tests', where: 'id = $testId');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        continue;
      }
      if (int.tryParse(line) != null) {
        questions.add(line);
      } else if (line.length == 1 && line.contains(RegExp(r'[a-zA-Z]'))) {
        answers.add(line);
      }
    }
    textRecognizer.close();
    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < test['question_count']; i++) {
      results.add({
        'question': i < questions.length ? questions[i] : (i + 1).toString(),
        'answer': i < answers.length ? answers[i] : '-',
      });
    }
    results.sort(
        (a, b) => int.parse(a['question']).compareTo(int.parse(b['question'])));
    print(results.toString());
    await dbHelper.insert('student_answers', {
      'student_id': studentId,
      'test_id': testId,
      'results': jsonEncode(results),
    });
  }
  return text;
}
