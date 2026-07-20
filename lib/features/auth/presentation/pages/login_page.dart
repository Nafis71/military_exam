import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/login_controller.dart';
import '../widgets/login_background.dart';
import '../widgets/login_card.dart';
import '../widgets/login_header.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewInsets = MediaQuery.viewInsetsOf(context);
            final isKeyboardOpen = viewInsets.bottom > 0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: viewInsets.bottom + AppSpacing.xxl.h,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: isKeyboardOpen ? 0 : constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LoginBackground(
                      child: LoginHeader(isCompact: true),
                    ),
                    LoginCard(controller: controller),
                    SizedBox(height: AppSpacing.xxl.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
