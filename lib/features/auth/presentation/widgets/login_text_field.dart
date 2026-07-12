import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  static const _inputBorderRadius = BorderRadius.all(Radius.circular(5));

  static const _enabledBorder = OutlineInputBorder(
    borderRadius: _inputBorderRadius,
    borderSide: BorderSide(color: AppColors.cD9E5DE),
  );

  static const _focusedBorder = OutlineInputBorder(
    borderRadius: _inputBorderRadius,
    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
  );

  static const _errorBorder = OutlineInputBorder(
    borderRadius: _inputBorderRadius,
    borderSide: BorderSide(color: AppColors.error),
  );

  static const _focusedErrorBorder = OutlineInputBorder(
    borderRadius: _inputBorderRadius,
    borderSide: BorderSide(color: AppColors.error, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.c17231D,
            height: 1.5,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.c17231D,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.c17231D.withValues(alpha: 0.5),
            ),
            border: _enabledBorder,
            enabledBorder: _enabledBorder,
            focusedBorder: _focusedBorder,
            errorBorder: _errorBorder,
            focusedErrorBorder: _focusedErrorBorder,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 17.w,
              vertical: 15.h,
            ),
          ),
        ),
      ],
    );
  }
}
