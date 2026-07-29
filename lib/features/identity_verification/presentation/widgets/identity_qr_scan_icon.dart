import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_status_icon_card.dart';

class IdentityQrScanIcon extends StatelessWidget {
  const IdentityQrScanIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStatusIconCard(
      child: SizedBox(
        width: 76.w,
        height: 76.w,
        child: Icon(
          Icons.qr_code_scanner,
          color: AppColors.c0A5943,
          size: 48.sp,
        ),
      ),
    );
  }
}
