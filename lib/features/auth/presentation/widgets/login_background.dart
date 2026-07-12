import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 264,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.85, -1.0),
                end: Alignment(0.85, 1.0),
                colors: [
                  AppColors.c0F3D2E,
                  AppColors.c176B4D,
                  AppColors.c23966A,
                ],
                stops: [0.085, 0.583, 0.915],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 580,
          child: ColoredBox(color: AppColors.background),
        ),
      ],
    );
  }
}
