import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../shared/domain/entities/device_details.dart';

/// Provides a stable device identifier and display-friendly suffix.
class DeviceIdService {
  DeviceIdService({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;
  String? _cachedDeviceId;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      if (kIsWeb) {
        _cachedDeviceId = 'WEB';
      } else if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        _cachedDeviceId = info.id;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        _cachedDeviceId = info.identifierForVendor ?? 'IOS';
      } else {
        _cachedDeviceId = 'UNKNOWN';
      }
    } catch (_) {
      _cachedDeviceId = 'UNKNOWN';
    }

    return _cachedDeviceId!;
  }

  Future<String> getDisplaySuffix() async {
    final id = await getDeviceId();
    if (id.length >= 4) {
      return id.substring(id.length - 4).toUpperCase();
    }
    if (id.isEmpty || id == 'UNKNOWN') return '----';
    return id.toUpperCase();
  }

  Future<String> getMaskedDisplay() async {
    final suffix = await getDisplaySuffix();
    return '•••• $suffix';
  }

  Future<DeviceDetails> getDeviceDetails() async {
    try {
      if (kIsWeb) {
        return const DeviceDetails(
          brandName: 'Web',
          modelNumber: 'Web Browser',
          osVersion: 'Web',
        );
      }
      if (Platform.isAndroid) {
        return _fromAndroid(await _deviceInfo.androidInfo);
      }
      if (Platform.isIOS) {
        return _fromIos(await _deviceInfo.iosInfo);
      }
      return DeviceDetails.unavailable();
    } catch (_) {
      return DeviceDetails.unavailable();
    }
  }

  DeviceDetails _fromAndroid(AndroidDeviceInfo info) {
    final brandName = _formatBrandName(
      _firstNonEmpty([info.brand, info.manufacturer]),
    );
    final modelNumber = _normalizeValue(info.model);
    final release = info.version.release.trim();
    final osVersion = release.isEmpty
        ? DeviceDetails.unavailableValue
        : 'Android $release';

    return _buildDetails(
      brandName: brandName,
      modelNumber: modelNumber,
      osVersion: osVersion,
    );
  }

  DeviceDetails _fromIos(IosDeviceInfo info) {
    final modelNumber = _normalizeValue(
      _firstNonEmpty([info.utsname.machine, info.model]),
    );
    final systemVersion = info.systemVersion.trim();
    final osVersion =
        systemVersion.isEmpty ? DeviceDetails.unavailableValue : 'iOS $systemVersion';

    return _buildDetails(
      brandName: 'Apple',
      modelNumber: modelNumber,
      osVersion: osVersion,
    );
  }

  DeviceDetails _buildDetails({
    required String brandName,
    required String modelNumber,
    required String osVersion,
  }) {
    final hasData = brandName != DeviceDetails.unavailableValue ||
        modelNumber != DeviceDetails.unavailableValue ||
        osVersion != DeviceDetails.unavailableValue;

    if (!hasData) {
      return DeviceDetails.unavailable();
    }

    return DeviceDetails(
      brandName: brandName,
      modelNumber: modelNumber,
      osVersion: osVersion,
    );
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return DeviceDetails.unavailableValue;
  }

  String _normalizeValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? DeviceDetails.unavailableValue : trimmed;
  }

  String _formatBrandName(String brand) {
    if (brand == DeviceDetails.unavailableValue) return brand;
    if (brand.length == 1) return brand.toUpperCase();
    return brand[0].toUpperCase() + brand.substring(1).toLowerCase();
  }
}
