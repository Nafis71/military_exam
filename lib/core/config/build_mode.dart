import 'package:flutter/foundation.dart';

enum BuildMode { development, staging, production, demo }

abstract final class BuildModeResolver {
  static BuildMode resolve() {
    if (kDebugMode) return BuildMode.development;
    if (kProfileMode) return BuildMode.staging;
    return BuildMode.production;
  }
}
