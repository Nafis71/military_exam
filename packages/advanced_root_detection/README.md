# advance_root_detection

[![pub.dev](https://img.shields.io/pub/v/advance_root_detection.svg)](https://pub.dev/packages/advance_root_detection)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey)](https://pub.dev/packages/advance_root_detection)

Comprehensive **Flutter RASP (Runtime Application Self-Protection)** plugin for Android and iOS.

Detects rooted/jailbroken devices, hooking frameworks (Frida, Xposed, Substrate), emulators/simulators, debuggers, and app tampering — with a hardened **NDK-level C++ detection layer** on Android that significantly raises the bar for bypass attempts.

> **Disclaimer:** This plugin is intended for **legitimate app hardening** only. Default behavior is to warn or degrade gracefully — never to brick the device or corrupt user data. No client-side RASP is unbypassable against determined attackers. Use in combination with server-side attestation (Apple DeviceCheck / App Attest, server-side certificate pinning).

---

## Features

- Root detection (Android): `su` binaries, Magisk/Zygisk, test-keys, dangerous props, root manager packages
- Jailbreak detection (iOS): classic + modern (Dopamine, palera1n, rootless), URL schemes, sandbox escape
- Hooking detection: Frida (port + process + memory maps), Xposed/LSPosed, Cydia Substrate, libhooker
- Emulator/Simulator detection: Build fingerprint, QEMU props, telephony, sensor count, emulator files
- Debugger detection: `Debug.isDebuggerConnected`, `FLAG_DEBUGGABLE`, `TracerPid`, `sysctl P_TRACED`
- App integrity: APK/IPA signing cert SHA-256, installer source, bundle ID, package name
- Environment signals: screen capture, accessibility services, VPN, developer mode/ADB
- **Android NDK hardening layer**: native ptrace, raw-syscall `/proc/self/maps` scan, inline-hook detection, JNIEnv integrity, XOR-obfuscated strings, `.text` segment writability check
- Stream-based continuous monitoring via `EventChannel`
- Configurable per-app: expected package name, signing cert hashes, allowed install sources, bundle IDs

---

## Installation

```yaml
dependencies:
  advance_root_detection: ^0.0.1
```

### Android

Add to your `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        minSdk 21
    }
}
```

### iOS

Minimum iOS 12.0. No additional setup required.

---

## Quick Start

```dart
import 'package:advance_root_detection/advance_root_detection.dart';

final shield = AdvanceRootDetection();

// One-shot full check
final ThreatReport report = await shield.performCheck(SecurityConfig(
  android: AndroidConfig(
    packageName: 'com.example.app',
    signingCertHashes: ['A1B2C3...'], // SHA-256 hex, no colons
    allowedInstallers: [AppStore.googlePlay],
  ),
  ios: IOSConfig(
    bundleIds: ['com.example.app'],
    teamId: 'ABC123',
  ),
));

if (report.isPrivilegedAccess) {
  // Root or jailbreak detected
}
if (report.isRuntimeManipulated) {
  // Frida, Xposed, or Substrate detected
}
if (report.hasCriticalThreat) {
  // Block sensitive operation
}

// Stream-based monitoring
shield.threatStream.listen((Threat threat) {
  switch (threat.category) {
    case ThreatCategory.privilegedAccess:
    case ThreatCategory.runtimeManipulation:
    case ThreatCategory.debuggerAttached:
    case ThreatCategory.analysisEnvironment:
    case ThreatCategory.integrityViolation:
    case ThreatCategory.screenCapture:
    case ThreatCategory.untrustedSource:
      print(threat);
  }
});
await shield.startMonitoring(SecurityConfig(
  monitoringInterval: Duration(seconds: 30),
));

// Verify before sensitive operations (payments, biometrics)
final safe = await shield.verifyBeforeSensitiveOp();
if (!safe) {
  // Block the operation
}

// Stop monitoring when done
await shield.stopMonitoring();
```

---

## API Reference

### `AdvanceRootDetection`

| Method | Returns | Description |
|--------|---------|-------------|
| `performCheck([SecurityConfig])` | `Future<ThreatReport>` | Full security check, all detectors |
| `startMonitoring([SecurityConfig])` | `Future<void>` | Start background monitoring |
| `stopMonitoring()` | `Future<void>` | Stop background monitoring |
| `verifyBeforeSensitiveOp([SecurityConfig])` | `Future<bool>` | Quick check, `true` = safe |
| `threatStream` | `Stream<Threat>` | Continuous threat events |

### `ThreatReport`

| Property | Type | Description |
|----------|------|-------------|
| `isPrivilegedAccess` | `bool` | Root / jailbreak detected |
| `isRuntimeManipulated` | `bool` | Hooking framework detected |
| `isDebuggerAttached` | `bool` | Debugger present |
| `isAnalysisEnvironment` | `bool` | Emulator / simulator |
| `isIntegrityViolated` | `bool` | Signing or bundle integrity violated |
| `hasCriticalThreat` | `bool` | Any high or critical severity threat |
| `isClean` | `bool` | No threats at all |
| `detectedThreats` | `List<Threat>` | All individual findings |

### `ThreatCategory`

| Value | Description |
|-------|-------------|
| `privilegedAccess` | Root (Android) or jailbreak (iOS) |
| `runtimeManipulation` | Frida, Xposed, Substrate, etc. |
| `debuggerAttached` | Debugger or anti-debug triggered |
| `analysisEnvironment` | Emulator or simulator |
| `integrityViolation` | Signing / bundle integrity |
| `screenCapture` | Screen recording / sharing |
| `untrustedSource` | Unknown or untrusted install source |

### `Severity`

`info` → `low` → `medium` → `high` → `critical`

---

## Detection Capability Matrix

| Category | Detection Method | Android (Kotlin) | Android (NDK) | iOS (Swift) |
|----------|-----------------|:----------------:|:-------------:|:-----------:|
| **Root / Jailbreak** | su binary (8 paths) | ✅ | ✅ | — |
| | BusyBox | ✅ | — | — |
| | Magisk artifacts (6 paths) | ✅ | ✅ | — |
| | Test-keys in Build.TAGS | ✅ | — | — |
| | Dangerous props (ro.debuggable, ro.secure) | ✅ | — | — |
| | /system mounted rw | ✅ | — | — |
| | Root manager packages (17 packages) | ✅ | — | — |
| | su execution | ✅ | — | — |
| | Classic jailbreak paths | — | — | ✅ |
| | Modern jailbreak paths (Dopamine, palera1n) | — | — | ✅ |
| | Jailbreak URL schemes (cydia, sileo, zbra…) | — | — | ✅ |
| | fork() sandbox escape | — | — | ✅ |
| | /private/ writability | — | — | ✅ |
| | /Applications symlink | — | — | ✅ |
| **Hooking** | Frida port 27042 | ✅ | — | — |
| | Frida process in /proc | ✅ | — | — |
| | Frida in /proc/self/maps | ✅ | ✅ | — |
| | Frida named anonymous mappings | — | ✅ | — |
| | XposedBridge class lookup | ✅ | — | — |
| | Xposed/LSPosed packages | ✅ | — | — |
| | XposedBridge.jar on disk | ✅ | — | — |
| | Cydia Substrate in maps | ✅ | ✅ | — |
| | libhooker, libsubstitute | — | — | ✅ |
| | DYLD_INSERT_LIBRARIES | — | — | ✅ |
| | Inline/PLT hook prologue scan | — | ✅ | — |
| | JNIEnv table integrity | — | ✅ | — |
| **Debugger** | Debug.isDebuggerConnected | ✅ | — | — |
| | FLAG_DEBUGGABLE | ✅ | — | — |
| | TracerPid ≠ 0 (Java) | ✅ | — | — |
| | TracerPid ≠ 0 (raw syscall) | — | ✅ | — |
| | Per-thread tracer check | — | ✅ | — |
| | ptrace TRACEME | — | ✅ | — |
| | Fork-based parent debugger | — | ✅ | — |
| | sysctl P_TRACED | — | — | ✅ |
| | ptrace PT_DENY_ATTACH | — | — | ✅ |
| **Emulator / Simulator** | Build fingerprint/model/manufacturer | ✅ | — | — |
| | QEMU system properties | ✅ | — | — |
| | Emulator phone numbers | ✅ | — | — |
| | QEMU device files | ✅ | — | — |
| | Low sensor count | ✅ | — | — |
| | TARGET_OS_SIMULATOR / env vars | — | — | ✅ |
| | Hardware model / HOME path | — | — | ✅ |
| **App Integrity** | APK signing cert SHA-256 | ✅ | — | — |
| | Package name (repackaging) | ✅ | — | — |
| | Installer source allowlist | ✅ | — | — |
| | Bundle ID verification | — | — | ✅ |
| | Provisioning profile presence | — | — | ✅ |
| | Install source (App Store / sideload) | — | — | ✅ |
| **Native Hardening** | XOR-obfuscated strings | — | ✅ | — |
| | .text segment writability | — | ✅ | — |
| | Compile flags (-fstack-protector-strong, -D_FORTIFY_SOURCE=2) | — | ✅ | — |

---

## Supported Platforms

| Platform | Min Version |
|----------|-------------|
| Android | API 21 (Android 5.0) |
| iOS | 12.0 |

---

## Threat Model & Limitations

- **Layered defense:** Each threat category has multiple independent detectors. Bypassing one layer does not defeat the check.
- **NDK + Kotlin:** An attacker must hook both the Java and native layers simultaneously to silence all signals.
- **XOR obfuscation:** Sensitive path strings are encrypted in the binary; they do not appear in `strings libshield.so`.
- **Not unbypassable:** A dedicated, skilled attacker with physical device access can bypass client-side RASP. This plugin is designed to raise the cost significantly, not provide an absolute guarantee.
- **Complement with server-side attestation:**
  - Android: [Google Play Integrity API](https://developer.android.com/google/play/integrity)
  - iOS: [Apple App Attest / DeviceCheck](https://developer.apple.com/documentation/devicecheck)

---

## Legal & Ethical

- Implement a **warn-and-degrade** policy, not a silent brick. Show users a message; don't corrupt data.
- Respect user privacy: this plugin does not transmit any data externally.
- Implementations based on public security research: [OWASP MASTG](https://mas.owasp.org/MASTG/), [RootBeer](https://github.com/scottyab/rootbeer) (Apache-2.0), published anti-tampering and Frida-detection literature.

---

## Contributing

Issues and pull requests welcome. Please follow the [OWASP MASTG](https://mas.owasp.org/MASTG/) guidelines when proposing new detection methods.

---

## License

[MIT](LICENSE)
