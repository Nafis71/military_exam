# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.4+1] - local fork (military_exam)

### Changed
- 16 KB page size alignment for `libshield.so` (Google Play / Android 15+):
  - `ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON` in `android/build.gradle`
  - `-Wl,-z,max-page-size=16384` in `android/src/main/cpp/CMakeLists.txt`

## [0.0.4] - 2026-04-27

### Added
- `bypassInDebugMode` flag on `RootDetectionGuard` — when set to `true`, the root/jailbreak check is skipped entirely in debug builds (`kDebugMode == true`), allowing installation and testing on normal (non-rooted) developer devices without triggering the blocked screen. Has no effect in profile or release builds.

## [0.0.3] - 2026-04-26

### Changed
- Shortened package description to comply with pub.dev 180-character limit
- Added `homepage`, `repository`, and `issue_tracker` URLs to `pubspec.yaml`


## [0.0.1] - 2026-04-26

### Added
- Initial release of `advance_root_detection` Flutter RASP plugin
- Android root detection: `su` binaries, Magisk/Zygisk artifacts, test-keys, dangerous props, root manager packages
- Android hooking detection: Frida (port + process + maps), Xposed/LSPosed/EdXposed, Cydia Substrate
- Android emulator detection: Build fingerprint, QEMU props, telephony, sensor count, emulator files
- Android debugger detection: `Debug.isDebuggerConnected`, `FLAG_DEBUGGABLE`, `TracerPid`, native ptrace anti-attach
- Android app integrity: APK signing certificate SHA-256, installer package, package name, APK hash
- Android environment signals: screen capture, accessibility services, VPN, developer mode/ADB
- Android NDK C++ hardening layer: native ptrace anti-debug, syscall-level `/proc/self/maps` scan, inline-hook detection, JNIEnv integrity, `.text` segment integrity, XOR-obfuscated strings
- iOS jailbreak detection: classic + modern paths (Dopamine, palera1n, rootless), URL schemes, sandbox escape, writability tests
- iOS hooking detection: Frida gadget scan, Cycript, Substrate, libhooker, `DYLD_INSERT_LIBRARIES`
- iOS debugger detection: `sysctl` P_TRACED, `ptrace(PT_DENY_ATTACH)`
- iOS app integrity: provisioning profile, bundle ID, code-signing, install source
- iOS simulator detection: `TARGET_OS_SIMULATOR`, env vars, hardware model
- Dart public API: `performCheck()`, `startMonitoring()`, `stopMonitoring()`, `verifyBeforeSensitiveOp()`, `threatStream`
- `ThreatReport`, `Threat`, `ThreatCategory`, `Severity`, `SecurityConfig`, `AndroidConfig`, `IOSConfig` data models
- MethodChannel (`flutter_security_shield/methods`) + EventChannel (`flutter_security_shield/threats`)
- Example app with Material 3 dashboard showing live threat status per category
- Dart unit tests with mocked MethodChannel
