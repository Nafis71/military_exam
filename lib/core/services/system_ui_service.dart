import 'package:flutter/services.dart';

/// Applies immersive fullscreen system UI (hides status and navigation bars).
class SystemUiService {
  static Future<void> applyFullscreenMode() {
    return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
