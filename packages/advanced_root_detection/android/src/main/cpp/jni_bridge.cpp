/**
 * jni_bridge.cpp — JNI entry point for the native security layer.
 *
 * Aggregates results from all native detection modules and returns them
 * as a Java array of maps to the Kotlin NativeDetector.
 *
 * The JNI method name must match:
 *   com.advance.root.detection.detectors.NativeDetector.nativeRunChecks()
 */

#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>

#include "anti_debug.h"
#include "proc_scanner.h"
#include "hook_detector.h"
#include "integrity_check.h"
#include "zygisk_detector.h"
#include "property_reader.h"

#define LOG_TAG "shield_jni"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

// ── Helper: create a Java HashMap<String,String> ─────────────────────────────

static jobject createJavaMap(JNIEnv* env,
                              const char* category,
                              const char* description,
                              const char* severity) {
    jclass mapClass = env->FindClass("java/util/HashMap");
    if (!mapClass) return nullptr;

    jmethodID initId = env->GetMethodID(mapClass, "<init>", "()V");
    jmethodID putId  = env->GetMethodID(mapClass, "put",
        "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");

    jobject map = env->NewObject(mapClass, initId);
    if (!map) return nullptr;

    auto putStr = [&](const char* key, const char* value) {
        jstring k = env->NewStringUTF(key);
        jstring v = env->NewStringUTF(value);
        env->CallObjectMethod(map, putId, k, v);
        env->DeleteLocalRef(k);
        env->DeleteLocalRef(v);
    };

    putStr("category",    category);
    putStr("description", description);
    putStr("severity",    severity);

    env->DeleteLocalRef(mapClass);
    return map;
}

// ── JNI method ────────────────────────────────────────────────────────────────

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_advanced_1root_1detection_detectors_NativeDetector_nativeRunChecks(
        JNIEnv* env, jclass /* clazz */) {

    struct NativeThreat {
        std::string category;
        std::string description;
        std::string severity;
    };

    std::vector<NativeThreat> threats;

    // 1. Debugger checks (TracerPid only — ptrace heuristics removed)
    LOGI("checkpoint: debugger");
    if (shield::isDebuggerPresent()) {
        threats.push_back({"debuggerAttached",
                           "Native ptrace/TracerPid check: debugger attached",
                           "critical"});
    }

    // 2. /proc/self/maps hook scan
    LOGI("checkpoint: maps_hooks");
    auto hookedLibs = shield::scanMapsForHooks();
    for (const auto& lib : hookedLibs) {
        threats.push_back({"runtimeManipulation",
                           "Hooking library found in process maps: " + lib,
                           "critical"});
    }

    if (shield::hasFridaAnonymousMapping()) {
        threats.push_back({"runtimeManipulation",
                           "Frida anonymous mapping detected in /proc/self/maps",
                           "critical"});
    }

    // 2b. dl_iterate_phdr — queries the dynamic linker's internal link_map,
    //     which Shamiko does not patch (unlike /proc/self/maps).
    LOGI("checkpoint: dl_iterate_phdr");
    if (shield::detectInjectedLibraries()) {
        threats.push_back({"privilegedAccess",
                           "Zygisk/Magisk library detected via dl_iterate_phdr",
                           "critical"});
    }

    // 2c. Anonymous rwxp pages removed — ART JIT creates legitimate rwxp on Android 10+.

    // 3a. Shamiko hooked-I/O detection (THE primary Shamiko detector).
    LOGI("checkpoint: hooked_file_io");
    if (shield::detectHookedFileIO()) {
        threats.push_back({"privilegedAccess",
                           "Shamiko/libc hook detected: /proc file content differs between "
                           "libc and raw syscall paths",
                           "critical"});
    }

    // 3c. Inline hook (prologue trampoline) detection
    auto hookedFuncs = shield::detectInlineHooks();
    for (const auto& func : hookedFuncs) {
        threats.push_back({"runtimeManipulation",
                           "Inline hook trampoline detected in libc function: " + func,
                           "critical"});
    }

    // 4. JNIEnv integrity
    LOGI("checkpoint: jni_env");
    if (!shield::isJNIEnvIntact(env)) {
        threats.push_back({"runtimeManipulation",
                           "JNIEnv function table pointers outside libart.so range",
                           "critical"});
    }

    // 5. .text segment writability
    if (shield::isTextSegmentWritable()) {
        threats.push_back({"integrityViolation",
                           "libshield.so .text segment is writable — runtime patcher detected",
                           "critical"});
    }

    // 6. Root artifact check via syscalls
    auto rootFiles = shield::findRootArtifacts();
    for (const auto& file : rootFiles) {
        threats.push_back({"privilegedAccess",
                           "Root artifact found (native syscall check): " + file,
                           "critical"});
    }

    // 7. Shamiko/DenyList-resistant checks (native layer)

    // ── DenyList-specific native checks ──────────────────────────────────────
    // DenyList is a kernel mount-namespace operation. These checks target facts
    // that are unaffected by mount namespace manipulation.

    // GID 0 (root) or GID 1000 (system) in supplementary groups.
    // DenyList changes mounts, not process credentials.
    if (shield::hasPrivilegedGroups()) {
        threats.push_back({"privilegedAccess",
                           "Process has privileged supplementary groups (root/system GID)",
                           "critical"});
    }

    // Zygisk companion library mapped via memfd — already in memory before DenyList runs.
    LOGI("checkpoint: zygisk_memory");
    if (shield::detectZygiskInMemory()) {
        threats.push_back({"privilegedAccess",
                           "Zygisk companion ELF detected in process memory (memfd-loaded library)",
                           "critical"});
    }

    // statfs() overlay-mount check — statfs is a kernel vfs call; Shamiko's
    // userspace libc hooks cannot intercept it.
    if (shield::detectOverlayMount()) {
        threats.push_back({"privilegedAccess",
                           "Magisk magic mount detected: /system or /vendor is overlayfs "
                           "(statfs OVERLAYFS_SUPER_MAGIC)",
                           "critical"});
    }

    // __system_property_foreach scan — enumerates every system property at the
    // native level; Shamiko would need to patch the property tree itself to hide.
    LOGI("checkpoint: magisk_properties");
    if (const auto magiskProp = shield::detectMagiskProperties()) {
        threats.push_back({"privilegedAccess",
                           std::string("Magisk property detected via "
                                       "__system_property_foreach: ") + *magiskProp,
                           "critical"});
    }

    // Bootloader unlock via __system_property_get — cannot be patched without
    // hooking libc, which our inline-hook checker detects.
    if (shield::detectUnlockedBootloader()) {
        threats.push_back({"privilegedAccess",
                           "Unlocked bootloader detected via native property read (Magisk prerequisite)",
                           "high"});
    }

    if (shield::detectZygiskThreads()) {
        threats.push_back({"privilegedAccess",
                           "Zygisk companion thread detected in /proc/self/task",
                           "critical"});
    }

    if (shield::detectMagiskProcess()) {
        threats.push_back({"privilegedAccess",
                           "Magisk daemon (magiskd) found in /proc process list",
                           "critical"});
    }

    if (shield::detectMagiskSocket()) {
        threats.push_back({"privilegedAccess",
                           "Magisk daemon abstract socket detected in /proc/net/unix",
                           "critical"});
    }

    if (shield::detectMagiskMounts()) {
        threats.push_back({"privilegedAccess",
                           "Magisk mount entries detected in /proc/self/mountinfo",
                           "critical"});
    }

    LOGI("checkpoint: complete (%zu threats)", threats.size());

    // ── Build Java array ───────────────────────────────────────────────────

    jclass mapClass = env->FindClass("java/util/HashMap");
    if (!mapClass) return nullptr;

    jobjectArray result = env->NewObjectArray(
        static_cast<jsize>(threats.size()), mapClass, nullptr);
    if (!result) return nullptr;

    for (size_t i = 0; i < threats.size(); ++i) {
        jobject map = createJavaMap(env,
            threats[i].category.c_str(),
            threats[i].description.c_str(),
            threats[i].severity.c_str());
        if (map) {
            env->SetObjectArrayElement(result, static_cast<jsize>(i), map);
            env->DeleteLocalRef(map);
        }
    }

    env->DeleteLocalRef(mapClass);
    return result;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_advanced_1root_1detection_detectors_NativeDetector_nativeGetProperty(
        JNIEnv* env, jclass /* clazz */, jstring name) {
    if (name == nullptr) {
        return env->NewStringUTF("");
    }
    const char* cname = env->GetStringUTFChars(name, nullptr);
    if (cname == nullptr) {
        return env->NewStringUTF("");
    }
    const std::string value = shield::getSystemProperty(cname);
    env->ReleaseStringUTFChars(name, cname);
    return env->NewStringUTF(value.c_str());
}
