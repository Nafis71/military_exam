import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/violation_controller.dart';
import '../widgets/violation_status_body.dart';

class ViolationPage extends GetView<ViolationController> {
  const ViolationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cFEF2F2,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Obx(
              () => ViolationStatusBody(
                contentKey: controller.violation.value?.type ??
                    controller.message,
                title: controller.title,
                message: controller.message,
                alertMessage: controller.alertMessage,
                bullets: controller.bullets,
                isSubmitting: controller.isSubmitting.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
