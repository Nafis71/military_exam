import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:military_exam/core/constants/app_strings.dart';
import 'package:military_exam/core/widgets/app_primary_button.dart';
import 'package:military_exam/features/mcq_exam/presentation/widgets/mcq_exam_header.dart';
import 'package:military_exam/features/mcq_exam/presentation/widgets/mcq_question_body.dart';
import 'package:military_exam/shared/domain/entities/exam_entities.dart';

McqQuestion _longQuestion() {
  return McqQuestion(
    id: 'q1',
    index: 12,
    total: 50,
    question:
        'এটি একটি দীর্ঘ প্রশ্ন যা ছোট স্ক্রিনেও মোড়ানো উচিত এবং কোনো ওভারফ্লো সতর্কতা তৈরি করবে না। '
        'Additional long English text to stress wrapping across narrow widths and short heights.',
    options: const [
      McqOption(
        id: 'a',
        label:
            'খুব দীর্ঘ অপশন টেক্সট যা একাধিক লাইনে ভাঙবে এবং সারি ওভারফ্লো করবে না',
      ),
      McqOption(id: 'b', label: 'দ্বিতীয় অপশন'),
      McqOption(id: 'c', label: 'তৃতীয় অপশন'),
      McqOption(
        id: 'd',
        label:
            'Another extremely long option label that must wrap safely on compact devices without causing a RenderFlex overflow error.',
      ),
    ],
  );
}

Future<void> _pumpMcqLayout(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final overflowErrors = <FlutterErrorDetails>[];
  final oldHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      overflowErrors.add(details);
    }
    oldHandler?.call(details);
  };
  addTearDown(() => FlutterError.onError = oldHandler);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: size,
            textScaler: TextScaler.linear(textScale),
            padding: const EdgeInsets.fromLTRB(0, 44, 0, 34),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const McqExamHeader(
                    questionIndex: 12,
                    questionTotal: 50,
                    formattedTimer: '59:59',
                  ),
                  Expanded(
                    child: McqQuestionBody(
                      question: _longQuestion(),
                      selectedOptionId: 'a',
                      onSelectOption: (_) {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
                    child: AppPrimaryButton(
                      label: AppStrings.finishMcq,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();

  expect(
    overflowErrors,
    isEmpty,
    reason: overflowErrors.map((e) => e.toString()).join('\n\n'),
  );
}

void main() {
  testWidgets('MCQ layout has no overflow on small phone', (tester) async {
    await _pumpMcqLayout(tester, size: const Size(320, 568));
  });

  testWidgets('MCQ layout has no overflow on short landscape', (tester) async {
    await _pumpMcqLayout(tester, size: const Size(667, 375));
  });

  testWidgets('MCQ layout has no overflow on large tablet', (tester) async {
    await _pumpMcqLayout(tester, size: const Size(1024, 1366));
  });

  testWidgets('MCQ layout has no overflow with large text scale', (tester) async {
    await _pumpMcqLayout(
      tester,
      size: const Size(360, 640),
      textScale: 1.6,
    );
  });
}
