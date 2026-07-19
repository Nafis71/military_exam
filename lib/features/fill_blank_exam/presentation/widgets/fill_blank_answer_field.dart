import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class FillBlankAnswerField extends StatefulWidget {
  const FillBlankAnswerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<FillBlankAnswerField> createState() => _FillBlankAnswerFieldState();
}

class _FillBlankAnswerFieldState extends State<FillBlankAnswerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant FillBlankAnswerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: 3,
      minLines: 1,
      textInputAction: TextInputAction.done,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.c17231D,
          ),
      decoration: InputDecoration(
        hintText: AppStrings.fillBlankAnswerHint,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.c17231D.withValues(alpha: 0.4),
            ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.cD9E5DE),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.cD9E5DE),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.c176B4D, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.cD9E5DE.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
