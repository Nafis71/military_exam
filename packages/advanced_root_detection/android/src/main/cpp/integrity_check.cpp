/**
 * integrity_check.cpp — Native-side file integrity checks.
 *
 * Checks for su binary presence and Magisk artifacts using raw syscalls
 * to bypass Java-layer file hooks.
 *
 * Reference: OWASP MASTG MSTG-RESILIENCE-1
 */

#include "integrity_check.h"
#include "obfuscated_strings.h"
#include <sys/syscall.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <string>
#include <vector>

namespace shield {

/**
 * Test if a file exists using raw SYS_openat syscall (bypasses libc hooks).
 */
static bool fileExistsSyscall(const char* path) {
    int fd = static_cast<int>(syscall(SYS_openat, AT_FDCWD, path, O_RDONLY | O_CLOEXEC));
    if (fd >= 0) {
        syscall(SYS_close, fd);
        return true;
    }
    return false;
}

/**
 * Returns paths of suspicious root-related files found via syscall-level access.
 * Uses OBFUSCATE() so strings are XOR-encrypted in the binary.
 */
std::vector<std::string> findRootArtifacts() {
    std::vector<std::string> found;

    // su binary locations
    const std::vector<std::string> suPaths = {
        OBFUSCATE("/system/bin/su"),
        OBFUSCATE("/system/xbin/su"),
        OBFUSCATE("/sbin/su"),
        OBFUSCATE("/vendor/bin/su"),
        OBFUSCATE("/data/local/xbin/su"),
        OBFUSCATE("/data/local/bin/su"),
        OBFUSCATE("/system/sd/xbin/su"),
        OBFUSCATE("/system/bin/failsafe/su"),
    };

    // Magisk artifacts
    const std::vector<std::string> magiskPaths = {
        OBFUSCATE("/sbin/.magisk"),
        OBFUSCATE("/data/adb/magisk"),
        OBFUSCATE("/cache/.disable_magisk"),
        OBFUSCATE("/dev/.magisk.unblock"),
        OBFUSCATE("/data/adb/magisk.db"),
    };

    for (const auto& p : suPaths) {
        if (fileExistsSyscall(p.c_str())) {
            found.push_back(p);
        }
    }
    for (const auto& p : magiskPaths) {
        if (fileExistsSyscall(p.c_str())) {
            found.push_back(p);
        }
    }

    return found;
}

} // namespace shield
