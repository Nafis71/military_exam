import 'package:get/get.dart';

import '../../../security_gate/domain/usecases/stop_security_watchdog_usecase.dart';
import '../../../auth/domain/usecases/clear_session_usecase.dart';

class FinishExamController extends GetxController {
  FinishExamController(this._stopWatchdog, this._clearSession);

  final StopSecurityWatchdogUseCase _stopWatchdog;
  final ClearSessionUseCase _clearSession;

  @override
  void onInit() {
    super.onInit();
    _cleanup();
  }

  Future<void> _cleanup() async {
    await _stopWatchdog();
    await _clearSession();
  }
}
