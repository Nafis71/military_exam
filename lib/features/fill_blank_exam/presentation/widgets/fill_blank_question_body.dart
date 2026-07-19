import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import 'fill_blank_answer_field.dart';
import 'fill_blank_question_card.dart';

class FillBlankQuestionBody extends StatelessWidget {
  const FillBlankQuestionBody({
    super.key,
    required this.question,
    required this.answerText,
    required this.onAnswerChanged,
    this.enabled = true,
  });

  final FillBlankQuestion question;
  final String answerText;
  final ValueChanged<String> onAnswerChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);

    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: SizedBox.expand(
          key: ValueKey(question.id),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md.w + mediaPadding.left,
              AppSpacing.md.h,
              AppSpacing.md.w + mediaPadding.right,
              AppSpacing.md.h,
            ),
            child: StaggeredEntrance(
              contentKey: question.id,
              duration: const Duration(milliseconds: 520),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FillBlankQuestionCard(question: question),
                SizedBox(height: AppSpacing.md.h),
                FillBlankAnswerField(
                  value: answerText,
                  onChanged: onAnswerChanged,
                  enabled: enabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
