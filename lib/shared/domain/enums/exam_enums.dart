import '../../../core/constants/app_strings.dart';

enum ExamPhase {
  splash,
  instructions,
  securityGate,
  login,
  mcq,
  fillBlank,
  written,
  finished,
  locked,
}

enum ExamQuestionType {
  mcq,
  fillInBlank,
  descriptive,
}

enum ViolationType {
  airplaneModeDisabled,
  vpnDisconnected,
  wifiDisabledDuringExam,
  appBackgrounded,
  appMinimized,
  screenshotTaken,
  screenRecordingDetected,
  rootedDevice,
  jailbreakDetected,
  developerModeEnabled,
}

enum SubmissionStatus {
  idle,
  saving,
  submitted,
  failed,
  locked,
}

enum ImageUploadStatus {
  localOnly,
  uploading,
  uploaded,
  failed,
}

extension ViolationTypeX on ViolationType {
  String get displayMessage => switch (this) {
        ViolationType.airplaneModeDisabled =>
          AppStrings.airplaneModeDisabledDuringExam,
        ViolationType.vpnDisconnected => AppStrings.vpnDisconnectedDuringExam,
        ViolationType.wifiDisabledDuringExam =>
          AppStrings.wifiDisabledDuringExam,
        ViolationType.appBackgrounded => AppStrings.appBackgrounded,
        ViolationType.appMinimized => AppStrings.appMinimized,
        ViolationType.screenshotTaken =>
          AppStrings.screenshotAttemptDetected,
        ViolationType.screenRecordingDetected =>
          AppStrings.screenRecordingDetected,
        ViolationType.rootedDevice => AppStrings.rootedDeviceDetected,
        ViolationType.jailbreakDetected =>
          AppStrings.jailbrokenDeviceDetected,
        ViolationType.developerModeEnabled => AppStrings.developerModeEnabled,
      };
}

extension ImageUploadStatusX on ImageUploadStatus {
  String get displayLabel => switch (this) {
        ImageUploadStatus.localOnly => AppStrings.uploadStatusLocalOnly,
        ImageUploadStatus.uploading => AppStrings.uploadStatusUploading,
        ImageUploadStatus.uploaded => AppStrings.uploadStatusUploaded,
        ImageUploadStatus.failed => AppStrings.uploadStatusFailed,
      };
}
