import 'package:permission_handler/permission_handler.dart';

/// Requests and checks camera permission for the written exam capture flow.
class CameraPermissionService {
  Future<bool> get isGranted async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> ensureGranted() async {
    if (await isGranted) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> get isPermanentlyDenied async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  Future<bool> openSettings() => openAppSettings();
}
