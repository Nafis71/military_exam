import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class LoginTextField extends StatefulWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final bool showVisibilityToggle;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

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

  void _toggleVisibility() {
    setState(() => _isObscured = !_isObscured);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
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
          controller: widget.controller,
          obscureText: widget.showVisibilityToggle ? _isObscured : widget.obscureText,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.c17231D,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
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
            suffixIcon: widget.showVisibilityToggle
                ? IconButton(
                    onPressed: _toggleVisibility,
                    icon: Icon(
                      _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.c66736C,
                      size: 22.sp,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
