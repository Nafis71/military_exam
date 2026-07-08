import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'system_ui_service.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  final StreamController<AppLifecycleState> _controller =
      StreamController<AppLifecycleState>.broadcast();

  AppLifecycleState _currentState = AppLifecycleState.resumed;

  Stream<AppLifecycleState> get lifecycleStream => _controller.stream;

  AppLifecycleState get currentState => _currentState;

  Future<AppLifecycleService> init() async {
    WidgetsBinding.instance.addObserver(this);
    _currentState = WidgetsBinding.instance.lifecycleState ??
        AppLifecycleState.resumed;
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;
    _controller.add(state);

    if (state == AppLifecycleState.resumed) {
      unawaited(SystemUiService.applyFullscreenMode());
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.close());
    super.onClose();
  }
}
