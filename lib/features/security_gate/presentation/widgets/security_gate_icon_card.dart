import 'package:flutter/material.dart';

import '../../../../core/widgets/app_status_icon_card.dart';

/// White rounded card with green glow and circular icon background.
class SecurityGateIconCard extends StatelessWidget {
  const SecurityGateIconCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppStatusIconCard(child: child);
  }
}
