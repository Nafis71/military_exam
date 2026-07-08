import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:military_exam/core/theme/app_colors.dart';
import 'package:military_exam/features/instructions/presentation/widgets/instruction_progress_dots.dart';

void main() {
  testWidgets('InstructionProgressDots highlights active page', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: InstructionProgressDots(count: 3, currentIndex: 1),
        ),
      ),
    );

    expect(find.byType(AnimatedContainer), findsNWidgets(3));
    final containers = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final active = containers.firstWhere((c) => (c.constraints?.maxWidth ?? 0) > 20);
    final decoration = active.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary);
  });
}
