import 'package:equatable/equatable.dart';

class DeviceDetails extends Equatable {
  const DeviceDetails({
    required this.brandName,
    required this.modelNumber,
    required this.osVersion,
    this.isAvailable = true,
  });

  static const String unavailableValue = '—';

  final String brandName;
  final String modelNumber;
  final String osVersion;
  final bool isAvailable;

  factory DeviceDetails.unavailable() {
    return const DeviceDetails(
      brandName: unavailableValue,
      modelNumber: unavailableValue,
      osVersion: unavailableValue,
      isAvailable: false,
    );
  }

  bool get hasDisplayableInfo =>
      isAvailable &&
      (brandName != unavailableValue ||
          modelNumber != unavailableValue ||
          osVersion != unavailableValue);

  @override
  List<Object?> get props => [brandName, modelNumber, osVersion, isAvailable];
}
