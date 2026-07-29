import 'package:hive_flutter/hive_flutter.dart';

import '../../features/exam_session/data/datasources/exam_answers_hive_datasource.dart';

abstract final class AppHiveBoxes {
  static const String examAnswers = 'exam_answers';
  static const String onboardingPrefs = 'onboarding_prefs';
  static const String session = 'session';
  static const String examCache = 'exam_cache';
  static const String writtenExamMeta = 'written_exam_meta';
}

abstract final class HiveInitializer {
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  static Future<ExamAnswersHiveDataSource> initExamAnswers() async {
    final box = await Hive.openBox<dynamic>(AppHiveBoxes.examAnswers);
    return ExamAnswersHiveDataSourceImpl(box);
  }

  static Future<Box<dynamic>> openBox(String name) async {
    return Hive.openBox<dynamic>(name);
  }
}
