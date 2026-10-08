import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvTemplateService {
  static const String templateContent =
      '''quiz_title,quiz_description,time_limit_minutes,category,difficulty,,,,
Sample Quiz,This is a sample quiz,30,general,intermediate

question_text,option1,option2,option3,option4,correct_answer,points,image_url,explanation
What is 2+2?,1,2,3,4,2,1,,
What is the capital of France?,London,Paris,Berlin,Madrid,3,1,,
Which planet is known as the Red Planet?,Earth,Mars,Venus,Jupiter,2,1,,''';

  static Future<void> downloadTemplate() async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/quiz_template.csv');

      // Write with explicit UTF-8 encoding (without BOM)
      await file.writeAsString(templateContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Quiz CSV Template',
          text: 'Use this template to create quizzes for import',
        ),
      );
    } catch (e) {
      throw Exception('Failed to generate template: $e');
    }
  }
}
