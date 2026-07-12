import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import 'mcq_card.dart';
import 'mcq_option_tile.dart';

class McqQuestionBody extends StatelessWidget {
  const McqQuestionBody({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onSelectOption,
  });

  final McqQuestion question;
  final String? selectedOptionId;
  final ValueChanged<String> onSelectOption;

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
                McqCard(question: question),
                SizedBox(height: AppSpacing.md.h),
                ...question.options.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: McqOptionTile(
                      option: entry.value,
                      optionIndex: entry.key,
                      isSelected: selectedOptionId == entry.value.id,
                      onTap: () => onSelectOption(entry.value.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
