/**
 * proc_scanner.cpp — /proc/self/maps scanner for hooking library signatures.
 *
 * Scans the process memory map for known hooking-framework signatures using
 * raw syscalls (bypasses Java-layer file hooks).
 *
 * Detected signatures: frida, gum-js-loop, gadget, xposed, substrate, libhoudini.
 *
 * Reference: OWASP MASTG MSTG-RESILIENCE-4
 * https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0048/
 */

#include "proc_scanner.h"
#include "obfuscated_strings.h"
#include <sys/syscall.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib>
#include <cctype>
#include <string>
#include <vector>
#include <link.h>
#include <android/log.h>

#define LOG_TAG "shield_proc"

namespace shield {

static const char* HOOK_SIGNATURES[] = {
    "frida",
    "gum-js-loop",
    "gadget",
    "frida-agent",
    "xposed",
    "substrate",
    "libhoudini",
    "libcycript",
    nullptr
};

/**
 * Reads /proc/self/maps entirely via raw syscalls into a string.
 */
static std::string readMaps() {
    char path[] = "/proc/self/maps";
    int fd = static_cast<int>(syscall(SYS_openat, AT_FDCWD, path, O_RDONLY));
    if (fd < 0) return {};

    std::string result;
    char buf[4096];
    ssize_t n;
    while ((n = static_cast<ssize_t>(syscall(SYS_read, fd, buf, sizeof(buf)))) > 0) {
        result.append(buf, static_cast<size_t>(n));
    }
    syscall(SYS_close, fd);
    return result;
}

/**
 * Returns all matching hook signatures found in /proc/self/maps.
 */
std::vector<std::string> scanMapsForHooks() {
    std::vector<std::string> found;
    std::string maps = readMaps();
    if (maps.empty()) return found;

    // Convert to lowercase for case-insensitive match
    std::string lowerMaps = maps;
    for (char& c : lowerMaps) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));

    for (int i = 0; HOOK_SIGNATURES[i] != nullptr; ++i) {
        if (lowerMaps.find(HOOK_SIGNATURES[i]) != std::string::npos) {
            found.emplace_back(HOOK_SIGNATURES[i]);
        }
    }
    return found;
}

/**
 * Checks for named anonymous mappings typical of Frida gadget:
 * lines like: "... 00000000 00:00 0    frida-agent-<arch>"
 */
bool hasFridaAnonymousMapping() {
    std::string maps = readMaps();
    if (maps.empty()) return false;
    std::string lower = maps;
    for (char& c : lower) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return lower.find("frida-agent") != std::string::npos;
}

// ── Shamiko-resistant checks ──────────────────────────────────────────────────

struct LibScanCtx {
    bool found;
    // Keywords that identify Zygisk/Magisk injected shared libraries.
    // Shamiko renames threads and patches /proc files but the dynamic linker's
    // internal link_map is much harder to sanitise.
    static const char* const KEYWORDS[];
};
const char* const LibScanCtx::KEYWORDS[] = {
    "zygisk", "magisk", "magiskd", "shamiko", nullptr
};

static int phdrCallback(struct dl_phdr_info* info, size_t /*size*/, void* data) {
    if (!info->dlpi_name || info->dlpi_name[0] == '\0') return 0;
    std::string name(info->dlpi_name);
    std::string lower = name;
    for (char& c : lower) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    auto* ctx = static_cast<LibScanCtx*>(data);
    for (int i = 0; LibScanCtx::KEYWORDS[i]; ++i) {
        if (lower.find(LibScanCtx::KEYWORDS[i]) != std::string::npos) {
            ctx->found = true;
            return 1; // stop iteration
        }
    }
    return 0;
}

/**
 * Walks the dynamic linker's own shared-library list (dl_iterate_phdr) looking
 * for Zygisk or Magisk library names. Unlike /proc/self/maps which Shamiko
 * patches, dl_iterate_phdr queries the linker's internal link_map structure
 * directly in memory.
 */
bool detectInjectedLibraries() {
    LibScanCtx ctx{false};
    dl_iterate_phdr(phdrCallback, &ctx);
    return ctx.found;
}

/**
 * Scans /proc/self/maps for anonymous pages that are both writable AND executable
 * (rwxp). Normal app code is r-xp (read+exec, not writable). A rwxp anonymous
 * region is a strong indicator of injected shellcode or a Zygisk module that
 * needed to patch its own code at runtime.
 *
 * False-positive guard: JIT code regions use r-xp after sealing and are backed
 * by memfd (non-anonymous). We exclude lines that contain a path token.
 */
bool detectAnonymousExecMappings() {
    std::string maps = readMaps();
    if (maps.empty()) return false;

    size_t pos = 0;
    while (pos < maps.size()) {
        size_t nl = maps.find('\n', pos);
        if (nl == std::string::npos) nl = maps.size();
        std::string line = maps.substr(pos, nl - pos);
        pos = nl + 1;

        // Permission field is the second space-delimited token, e.g. "rwxp"
        size_t sp1 = line.find(' ');
        if (sp1 == std::string::npos) continue;
        size_t sp2 = line.find(' ', sp1 + 1);
        if (sp2 == std::string::npos) continue;
        std::string perms = line.substr(sp1 + 1, sp2 - sp1 - 1);
        if (perms.size() < 4) continue;

        bool writable   = (perms[1] == 'w');
        bool executable = (perms[2] == 'x');
        if (!writable || !executable) continue;

        // Skip if the mapping has a file backing (last token starts with '/')
        size_t lastSp = line.rfind(' ');
        if (lastSp != std::string::npos) {
            std::string lastToken = line.substr(lastSp + 1);
            if (!lastToken.empty() && lastToken[0] == '/') continue;
        }

        return true; // anonymous rwxp found
    }
    return false;
}

} // namespace shield
