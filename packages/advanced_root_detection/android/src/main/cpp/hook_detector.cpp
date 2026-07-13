/**
 * hook_detector.cpp — Inline/PLT hook detection and JNIEnv integrity.
 *
 * Implements:
 *   1. Prologue inspection: resolve libc functions via dlsym, read first bytes,
 *      detect B/BR/LDR-PC trampolines (ARM64 + ARM-Thumb).
 *   2. JNIEnv function-table pointer range check against libart.so mapped range.
 *   3. .text segment writability check (mprotect-based).
 *
 * References:
 *   OWASP MASTG MSTG-RESILIENCE-4
 *   https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0048/
 */

#include "hook_detector.h"
#include "obfuscated_strings.h"
#include <dlfcn.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <fcntl.h>
#include <cstdio>
#include <cinttypes>
#include <cstring>
#include <cstdint>
#include <string>
#include <vector>
#include <android/log.h>
#include <jni.h>

#define LOG_TAG "shield_hook"

namespace shield {

/**
 * Returns true if the function at [funcPtr] has a hook trampoline in its prologue.
 *
 * ARM64: standard prologue is `stp x29, x30, [sp, #-N]!` (0xA9B...).
 *        A hook trampoline uses `LDR X16, #8; BR X16` or `B <offset>`.
 *
 * ARM-Thumb: standard is PUSH {r4,lr}. Hook trampolines use `LDR PC, [PC, #N]`.
 */
static bool prologueIsHooked(void* funcPtr) {
    if (!funcPtr) return false;

    auto* bytes = reinterpret_cast<const uint8_t*>(funcPtr);

#if defined(__aarch64__)
    // ARM64: check for B trampoline (0x14xxxxxx) or LDR X17 pattern (0x58xxxxxx)
    uint32_t instr;
    memcpy(&instr, bytes, 4);
    uint8_t opHigh = static_cast<uint8_t>(instr >> 24);
    if (opHigh == 0x14 || opHigh == 0x58 || opHigh == 0x18) {
        return true; // B or LDR (literal) — likely hook
    }
#elif defined(__arm__)
    // ARM-Thumb: check for LDR PC, [PC, #N] (0xF8DF or 0x4778)
    if ((bytes[1] == 0xF8 && bytes[0] == 0xDF) || (bytes[0] == 0x78 && bytes[1] == 0x47)) {
        return true;
    }
#endif
    return false;
}

/**
 * Checks whether commonly hooked libc functions have modified prologues.
 */
std::vector<std::string> detectInlineHooks() {
    std::vector<std::string> hooked;

    const char* funcs[] = { "open", "read", "fopen", "dlopen", nullptr };
    void* libc = dlopen("libc.so", RTLD_LAZY | RTLD_NOLOAD);
    if (!libc) return hooked;

    for (int i = 0; funcs[i]; ++i) {
        void* sym = dlsym(libc, funcs[i]);
        if (sym && prologueIsHooked(sym)) {
            hooked.emplace_back(funcs[i]);
        }
    }
    dlclose(libc);
    return hooked;
}

/**
 * Verifies that JNIEnv function-table pointers lie within the mapped range of libart.so.
 * If any pointer is outside that range, a hook has redirected it.
 */
bool isJNIEnvIntact(JNIEnv* env) {
    if (!env) return true; // can't check

    // Find libart.so range from /proc/self/maps
    int fd = static_cast<int>(syscall(SYS_openat, AT_FDCWD, "/proc/self/maps", O_RDONLY));
    if (fd < 0) return true;

    char buf[16384] = {};
    syscall(SYS_read, fd, buf, sizeof(buf) - 1);
    syscall(SYS_close, fd);

    uintptr_t artStart = 0, artEnd = 0;
    char* line = strtok(buf, "\n");
    while (line) {
        if (strstr(line, "libart.so")) {
            uintptr_t start = 0, end = 0;
            if (sscanf(line, "%" SCNxPTR "-%" SCNxPTR, &start, &end) == 2) {
                if (start < artStart || artStart == 0) artStart = start;
                if (end > artEnd) artEnd = end;
            }
        }
        line = strtok(nullptr, "\n");
    }

    if (artStart == 0 || artEnd == 0) return true; // couldn't determine range

    // Check a sample of JNIEnv function pointers
    const JNINativeInterface* funcs = env->functions;
    auto checkPtr = [&](const void* ptr) -> bool {
        auto addr = reinterpret_cast<uintptr_t>(ptr);
        return addr >= artStart && addr < artEnd;
    };

    if (!checkPtr(reinterpret_cast<const void*>(funcs->FindClass))) return false;
    if (!checkPtr(reinterpret_cast<const void*>(funcs->NewStringUTF))) return false;
    if (!checkPtr(reinterpret_cast<const void*>(funcs->GetStringUTFChars))) return false;

    return true;
}

/**
 * Checks whether the .text segment of this library is unexpectedly writable.
 * A writable code segment indicates a runtime patcher has modified mprotect flags.
 */
bool isTextSegmentWritable() {
    int fd = static_cast<int>(syscall(SYS_openat, AT_FDCWD, "/proc/self/maps", O_RDONLY));
    if (fd < 0) return false;

    char buf[16384] = {};
    syscall(SYS_read, fd, buf, sizeof(buf) - 1);
    syscall(SYS_close, fd);

    char* line = strtok(buf, "\n");
    while (line) {
        if (strstr(line, "libshield.so")) {
            // Format: addr-addr perms offset dev inode path
            char perms[8] = {};
            if (sscanf(line, "%*x-%*x %7s", perms) == 1) {
                // perms[1] == 'w' means writable code segment
                if (strlen(perms) >= 3 && perms[0] == 'r' && perms[1] == 'w' && perms[2] == 'x') {
                    return true;
                }
            }
        }
        line = strtok(nullptr, "\n");
    }
    return false;
}

/**
 * Detects Shamiko-style libc hooking.
 *
 * Shamiko hooks libc's fopen/fread/open/read to filter Magisk artifacts out of
 * /proc files before the app sees them. Raw syscalls (SYS_openat / SYS_read)
 * bypass these hooks and go straight to the kernel.
 *
 * Strategy: read the same file twice — once through libc (potentially filtered)
 * and once through raw syscalls (unfiltered). Any size or content difference
 * proves that something between libc and the kernel is modifying the data.
 *
 * Defeating this check would require hooking the SVC/SYSCALL instruction itself,
 * which needs a kernel driver — well beyond Shamiko's userspace scope.
 */
bool detectHookedFileIO() {
    // We probe /proc/self/mountinfo only (more stable than /proc/self/maps
    // which changes on every allocation, causing false positives on clean devices).
    //
    // Strategy: read the file via BOTH paths, then check whether Magisk-specific
    // lines appear in the raw syscall result but are ABSENT from the libc result.
    // On a clean device both reads are identical → no detection.
    // With Shamiko active: raw read exposes Magisk entries; libc read is filtered.
    // Comparing total sizes is intentionally avoided to prevent race-condition
    // false positives from concurrent memory-map changes.

    const char* path = "/proc/self/mountinfo";
    constexpr size_t kLimit = 65536;

    // ── Path A: libc (Shamiko hooks fopen/fread) ──────────────────────────────
    std::string libcData;
    if (FILE* f = fopen(path, "r")) {
        char buf[4096];
        size_t n;
        while (libcData.size() < kLimit &&
               (n = fread(buf, 1, sizeof(buf), f)) > 0) {
            libcData.append(buf, n);
        }
        fclose(f);
    }

    // ── Path B: raw kernel syscall (bypasses every libc hook) ─────────────────
    std::string rawData;
    int fd = static_cast<int>(
        syscall(SYS_openat, AT_FDCWD, path, O_RDONLY | O_CLOEXEC));
    if (fd >= 0) {
        char buf[4096];
        ssize_t n;
        while (rawData.size() < kLimit &&
               (n = static_cast<ssize_t>(
                   syscall(SYS_read, fd, buf, sizeof(buf)))) > 0) {
            rawData.append(buf, static_cast<size_t>(n));
        }
        syscall(SYS_close, fd);
    }

    if (libcData.empty() || rawData.empty()) return false;

    // ── Compare for Magisk-specific content presence only ─────────────────────
    // A clean device has identical content in both paths → no false positive.
    // Shamiko removes Magisk entries from the libc path but not the raw path.
    static const char* magiskSigs[] = {
        "magisk", "/data/adb", "worker_", "zygisk", nullptr
    };

    // Lower-case both for case-insensitive search
    std::string lowerRaw  = rawData;
    std::string lowerLibc = libcData;
    for (char& c : lowerRaw)  c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    for (char& c : lowerLibc) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));

    for (int i = 0; magiskSigs[i]; ++i) {
        bool presentInRaw  = lowerRaw.find(magiskSigs[i])  != std::string::npos;
        bool presentInLibc = lowerLibc.find(magiskSigs[i]) != std::string::npos;
        // Present in the unfiltered kernel read but missing from the libc read
        // → Shamiko actively filtered this entry → hooking confirmed.
        if (presentInRaw && !presentInLibc) return true;
    }

    return false;
}

} // namespace shield
