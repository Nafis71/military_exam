import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/exam_entities.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_local_datasource.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  SecurityRepositoryImpl(this._localDataSource);

  final SecurityLocalDataSource _localDataSource;

  @override
  Future<Result<DeviceIntegrityStatus>> checkDeviceIntegrity() async {
    try {
      final status = await _localDataSource.checkDeviceIntegrity();
      return Success(status);
    } catch (error) {
      return ErrorResult(
        SecurityFailure('${AppStrings.deviceIntegrityCheckFailed}: $error'),
      );
    }
  }

  @override
  Future<Result<AirplaneModeStatus>> checkAirplaneMode() async {
    try {
      final status = await _localDataSource.checkAirplaneMode();
      return Success(status);
    } catch (error) {
      return ErrorResult(
        SecurityFailure('${AppStrings.airplaneModeCheckFailedWithError}: $error'),
      );
    }
  }

  @override
  Stream<AirplaneModeStatus> observeAirplaneMode() =>
      _localDataSource.observeAirplaneMode();

  @override
  Future<Result<ConnectivityStatus>> checkConnectivity() async {
    try {
      final status = await _localDataSource.checkConnectivity();
      return Success(status);
    } catch (error) {
      return ErrorResult(
        SecurityFailure('${AppStrings.connectivityCheckFailedWithError}: $error'),
      );
    }
  }

  @override
  Stream<ConnectivityStatus> observeConnectivity() =>
      _localDataSource.observeConnectivity();

  @override
  Future<Result<void>> openAirplaneModeSettings() async {
    try {
      await _localDataSource.openAirplaneModeSettings();
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        SecurityFailure('${AppStrings.unableToOpenAirplaneModeSettings}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> openWifiSettings() async {
    try {
      await _localDataSource.openWifiSettings();
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        SecurityFailure('${AppStrings.unableToOpenWifiSettings}: $error'),
      );
    }
  }

  @override
  Future<Result<void>> openDeveloperModeSettings() async {
    try {
      await _localDataSource.openDeveloperModeSettings();
      return const Success(null);
    } catch (error) {
      return ErrorResult(
        SecurityFailure('${AppStrings.unableToOpenDeveloperModeSettings}: $error'),
      );
    }
  }
}
