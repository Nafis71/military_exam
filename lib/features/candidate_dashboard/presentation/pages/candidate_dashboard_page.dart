import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/candidate_dashboard_controller.dart';
import '../widgets/candidate_dashboard_showcase_host.dart';

class CandidateDashboardPage extends GetView<CandidateDashboardController> {
  const CandidateDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CandidateDashboardShowcaseHost(controller: controller);
  }
}
