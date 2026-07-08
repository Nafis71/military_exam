import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';

abstract class SecurityRepository {
  Future<Result<DeviceIntegrityStatus>> checkDeviceIntegrity();

  Future<Result<AirplaneModeStatus>> checkAirplaneMode();

  Stream<AirplaneModeStatus> observeAirplaneMode();

  Future<Result<ConnectivityStatus>> checkConnectivity();

  Stream<ConnectivityStatus> observeConnectivity();

  Future<Result<void>> openAirplaneModeSettings();

  Future<Result<void>> openWifiSettings();

  Future<Result<void>> openDeveloperModeSettings();
}
