#pragma once
#include <vector>
#include <string>
#include <jni.h>

namespace shield {
    std::vector<std::string> detectInlineHooks();
    bool isJNIEnvIntact(JNIEnv* env);
    bool isTextSegmentWritable();

    /**
     * Shamiko detection: reads /proc/self/mountinfo and /proc/self/maps via both
     * the libc path (fopen/fread — potentially hooked) and raw syscalls
     * (SYS_openat/SYS_read — bypasses hooks). If the content differs, Shamiko
     * is actively intercepting and filtering our I/O.
     */
    bool detectHookedFileIO();
} // namespace shield
