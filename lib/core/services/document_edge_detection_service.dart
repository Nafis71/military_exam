import 'package:flutter/foundation.dart';
import 'package:flutter_edge_detection/flutter_edge_detection.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_strings.dart';

/// Launches the native document scanner (camera + edge detect + crop).
class DocumentEdgeDetectionService {
  final Logger _logger = Logger();

  /// Opens the scanner and returns the cropped image path, or `null` if cancelled.
  Future<String?> scanDocument() async {
    final directory = await getApplicationSupportDirectory();
    final saveTo = p.join(
      directory.path,
      'edge_detection_${DateTime.now().millisecondsSinceEpoch}.jpeg',
    );

    try {
      final success = await FlutterEdgeDetection.detectEdge(
        saveTo,
        canUseGallery: false,
        androidScanTitle: AppStrings.edgeDetectionScanTitle,
        androidCropTitle: AppStrings.edgeDetectionCropTitle,
        androidCropBlackWhiteTitle: AppStrings.edgeDetectionCropBlackWhiteTitle,
        androidCropReset: AppStrings.edgeDetectionCropReset,
      );
      return success ? saveTo : null;
    } on EdgeDetectionException catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.e(
          'scanDocument failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return null;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        _logger.e(
          'scanDocument failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }
}
