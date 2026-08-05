import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_strings.dart';
import '../logging/app_logger.dart';
import '../widgets/app_error_toast.dart';

abstract final class ExternalUrlLauncher {
  static Future<bool> launchHttpUrl(
    String url, {
    AppLogger? logger,
  }) async {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return false;
      }

      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        return false;
      }

      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      if (kDebugMode) {
        logger?.error('external url launch failed', error: e, stackTrace: st);
      }
      return false;
    }
  }

  static Future<bool> launchHttpUrlOrShowError(
    String url, {
    AppLogger? logger,
  }) async {
    final launched = await launchHttpUrl(url, logger: logger);
    if (!launched) {
      AppErrorToast.show(AppStrings.somethingWentWrong);
    }
    return launched;
  }
}
