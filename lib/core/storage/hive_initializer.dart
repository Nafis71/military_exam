import 'package:hive_flutter/hive_flutter.dart';

import '../../features/exam_session/data/datasources/exam_answers_hive_datasource.dart';

abstract final class HiveInitializer {
  static Future<ExamAnswersHiveDataSource> initExamAnswers() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(ExamAnswersHiveDataSourceImpl.boxName);
    return ExamAnswersHiveDataSourceImpl(box);
  }
}
