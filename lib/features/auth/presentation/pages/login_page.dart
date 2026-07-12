import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
      body: Stack(
        children: [
          const LoginBackground(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  const LoginHeader(),
                  LoginCard(controller: controller),
                  SizedBox(height: AppSpacing.xxl.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
