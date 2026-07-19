import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/login_controller.dart';

class LoginDistrictDropdown extends StatelessWidget {
  const LoginDistrictDropdown({super.key, required this.controller});

  final LoginController controller;

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
          AppStrings.district,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.c17231D,
                height: 1.5,
              ),
        ),
        SizedBox(height: 8.h),
        Obx(() {
          final isLoading = controller.isLoadingDistricts.value;
          final districts = controller.districts;
          final selectedDistrict = controller.selectedDistrict.value;

          return Theme(
            data: Theme.of(context).copyWith(
              focusColor: AppColors.primary,
              hoverColor: AppColors.primary.withValues(alpha: 0.12),
              menuTheme: MenuThemeData(
                style: MenuStyle(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                ),
              ),
            ),
            child: DropdownButtonFormField<String>(
              key: ValueKey(selectedDistrict ?? 'district-none'),
              initialValue: selectedDistrict,
              isDense: true,
              itemHeight: 44.h,
              items: districts
                  .map(
                    (district) => DropdownMenuItem<String>(
                      value: district,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 17.w),
                        child: Text(
                          district,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: district == selectedDistrict
                                    ? AppColors.cFFFFFF
                                    : AppColors.c17231D,
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              selectedItemBuilder: (context) => districts
                  .map(
                    (district) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        district,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: isLoading ? null : controller.selectDistrict,
              validator: controller.validateDistrict,
              hint: Text(
                isLoading
                    ? AppStrings.loadingDistricts
                    : AppStrings.districtHint,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.c17231D.withValues(alpha: 0.5),
                    ),
              ),
              icon: isLoading
                  ? SizedBox(
                      height: 18.h,
                      width: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.c66736C,
                      ),
                    )
                  : const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.c66736C,
                    ),
              decoration: InputDecoration(
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
              isExpanded: true,
            ),
          );
        }),
      ],
    );
  }
}
