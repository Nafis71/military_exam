/**
 * anti_debug.cpp — Native debugger detection via TracerPid.
 *
 * Uses /proc/self/status TracerPid read via raw syscalls (bypasses Java-layer
 * hooks) and per-thread tracer check via /proc/self/task/<tid>/status.
 *
 * ptrace(PTRACE_TRACEME) is intentionally NOT used — it false-positives on
 * stock Android 10+ (EPERM from SELinux / ptrace_scope without a debugger).
 *
 * References:
 *   OWASP MASTG MSTG-RESILIENCE-2
 *   https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0046/
 */

#include "anti_debug.h"
#include <sys/wait.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <cstring>
#include <cstdlib>
#include <dirent.h>
#include <android/log.h>

#define LOG_TAG "shield_anti_debug"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

namespace shield {

/**
 * Read /proc/self/status via raw syscalls to bypass Java-layer file hooks.
 * Returns the TracerPid value, or -1 on failure.
 */
static int readTracerPidSyscall() {
    // Use raw syscall to open /proc/self/status
    char path[] = "/proc/self/status";
    int fd = static_cast<int>(syscall(SYS_openat, AT_FDCWD, path, O_RDONLY));
    if (fd < 0) return -1;

    char buf[4096] = {};
    ssize_t n = static_cast<ssize_t>(syscall(SYS_read, fd, buf, sizeof(buf) - 1));
    syscall(SYS_close, fd);
    if (n <= 0) return -1;

    // Parse TracerPid field
    const char* needle = "TracerPid:";
    char* pos = strstr(buf, needle);
    if (!pos) return -1;
    pos += strlen(needle);
    while (*pos == ' ' || *pos == '\t') ++pos;
    return atoi(pos);
}

/**
 * Check all threads: /proc/self/task/<tid>/status for non-zero TracerPid.
 */
static bool anyThreadTraced() {
    DIR* taskDir = opendir("/proc/self/task");
    if (!taskDir) return false;
    bool traced = false;
    struct dirent* entry;
    while ((entry = readdir(taskDir)) != nullptr) {
        if (entry->d_name[0] == '.') continue;
        char statusPath[64];
        snprintf(statusPath, sizeof(statusPath), "/proc/self/task/%s/status", entry->d_name);
        int fd = static_cast<int>(syscall(SYS_openat, AT_FDCWD, statusPath, O_RDONLY));
        if (fd < 0) continue;
        char buf[512] = {};
        syscall(SYS_read, fd, buf, sizeof(buf) - 1);
        syscall(SYS_close, fd);
        const char* needle = "TracerPid:";
        char* pos = strstr(buf, needle);
        if (pos) {
            pos += strlen(needle);
            while (*pos == ' ' || *pos == '\t') ++pos;
            if (atoi(pos) != 0) {
                traced = true;
                break;
            }
        }
    }
    closedir(taskDir);
    return traced;
}

bool __attribute__((always_inline)) isDebuggerPresent() {
    if (readTracerPidSyscall() > 0) {
        return true;
    }
    if (anyThreadTraced()) {
        return true;
    }
    return false;
}

/**
 * Fork-based verification: child reads its own TracerPid; if parent is a debugger,
 * the child's TracerPid will be non-zero.
 */
bool isParentDebugger() {
    pid_t child = fork();
    if (child == 0) {
        // Child: check own TracerPid
        int pid = readTracerPidSyscall();
        _exit(pid > 0 ? 1 : 0);
    } else if (child > 0) {
        int status = 0;
        waitpid(child, &status, 0);
        if (WIFEXITED(status) && WEXITSTATUS(status) == 1) {
            return true;
        }
    }
    return false;
}

} // namespace shield
