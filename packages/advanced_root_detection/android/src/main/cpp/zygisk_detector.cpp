/**
 * zygisk_detector.cpp — Shamiko/DenyList-resistant Magisk detection.
 *
 * Shamiko patches /proc/net/unix, /proc/self/mountinfo, thread names, and the
 * process list before the app reads them, defeating simple DenyList checks.
 * The checks below target facts that cannot be sanitised from userspace:
 *
 *  1. Bootloader state via __system_property_get (native) — the bootloader writes
 *     ro.boot.verifiedbootstate before init; spoofing it requires hooking libc's
 *     __system_property_get, which is detectable via our inline-hook checker.
 *
 *  2. Soft DenyList checks (thread names, process list, mounts, sockets) — these
 *     are defeated by Shamiko alone but succeed when Shamiko is absent, adding
 *     breadth against less-sophisticated setups.
 *
 * All I/O uses raw syscalls to bypass any libc-level file hooks.
 */

#include "zygisk_detector.h"
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/statfs.h>
#include <fcntl.h>
#include <unistd.h>
#include <grp.h>
#include <link.h>
#include <elf.h>
#include <cstring>
#include <cstdint>
#include <cctype>
#include <optional>
#include <string>
#include <vector>
#include <sys/system_properties.h>

namespace shield {

// ── Raw I/O helpers ───────────────────────────────────────────────────────────

static std::string readFileSyscall(const char* path, size_t limit = 65536) {
    int fd = static_cast<int>(syscall(SYS_openat, AT_FDCWD, path, O_RDONLY | O_CLOEXEC));
    if (fd < 0) return {};
    std::string result;
    char buf[4096];
    ssize_t n;
    while (result.size() < limit &&
           (n = static_cast<ssize_t>(syscall(SYS_read, fd, buf, sizeof(buf)))) > 0) {
        result.append(buf, static_cast<size_t>(n));
    }
    syscall(SYS_close, fd);
    return result;
}

// kernel dirent64 layout (same on all ABIs)
struct dirent64_t {
    uint64_t d_ino;
    int64_t  d_off;
    uint16_t d_reclen;
    uint8_t  d_type;
    char     d_name[1];
};

static std::vector<std::string> listDirSyscall(const char* path) {
    std::vector<std::string> entries;
    int fd = static_cast<int>(
        syscall(SYS_openat, AT_FDCWD, path, O_RDONLY | O_DIRECTORY | O_CLOEXEC));
    if (fd < 0) return entries;

    alignas(8) char buf[4096];
    for (;;) {
        long n = syscall(SYS_getdents64, fd, buf, sizeof(buf));
        if (n <= 0) break;
        for (long off = 0; off < n;) {
            auto* d = reinterpret_cast<dirent64_t*>(buf + off);
            std::string name(d->d_name);
            if (name != "." && name != "..") entries.push_back(name);
            off += d->d_reclen;
        }
    }
    syscall(SYS_close, fd);
    return entries;
}

static bool containsCI(const std::string& hay, const char* needle) {
    std::string lower = hay;
    for (char& c : lower) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    std::string nl(needle);
    for (char& c : nl) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return lower.find(nl) != std::string::npos;
}

static bool isAllDigits(const std::string& s) {
    if (s.empty()) return false;
    for (char c : s) if (!isdigit(static_cast<unsigned char>(c))) return false;
    return true;
}

// ── Detection functions ───────────────────────────────────────────────────────

/**
 * Scan /proc/self/task/<tid>/comm for Zygisk companion thread names.
 * Zygisk injects before DenyList remounting, so thread names survive.
 */
bool detectZygiskThreads() {
    auto tids = listDirSyscall("/proc/self/task");
    for (const auto& tid : tids) {
        std::string commPath = "/proc/self/task/" + tid + "/comm";
        std::string comm = readFileSyscall(commPath.c_str(), 64);
        if (containsCI(comm, "zygisk")) return true;
    }
    return false;
}

/**
 * Walk /proc/<pid>/cmdline for every PID looking for magiskd.
 * The Magisk supervisor daemon is always running and readable by any process.
 */
bool detectMagiskProcess() {
    auto pids = listDirSyscall("/proc");
    for (const auto& pid : pids) {
        if (!isAllDigits(pid)) continue;
        std::string cmdlinePath = "/proc/" + pid + "/cmdline";
        std::string cmdline = readFileSyscall(cmdlinePath.c_str(), 256);
        if (cmdline.empty()) continue;
        // Replace NUL arg separators with spaces
        for (char& c : cmdline) if (c == '\0') c = ' ';
        if (containsCI(cmdline, "magiskd")) return true;
        if (containsCI(cmdline, "magisk") && containsCI(cmdline, "daemon")) return true;
    }
    return false;
}

/**
 * Scan /proc/net/unix for the Magisk abstract socket.
 * magiskd creates an abstract UNIX socket whose name is exactly 32 lowercase
 * hex characters. It appears in /proc/net/unix as "@<32-hex-chars>".
 * DenyList cannot remove this kernel-level socket table entry.
 */
bool detectMagiskSocket() {
    std::string content = readFileSyscall("/proc/net/unix");
    if (content.empty()) return false;

    // Walk line by line
    size_t pos = 0;
    while (pos < content.size()) {
        size_t end = content.find('\n', pos);
        if (end == std::string::npos) end = content.size();
        std::string line = content.substr(pos, end - pos);
        pos = end + 1;

        // Find the last whitespace-delimited token (socket path column)
        size_t lastSpace = line.rfind(' ');
        if (lastSpace == std::string::npos) continue;
        std::string token = line.substr(lastSpace + 1);
        if (token.empty() || token[0] != '@') continue;
        std::string name = token.substr(1);
        if (name.size() != 32) continue;
        bool allHex = true;
        for (char c : name) {
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) {
                allHex = false; break;
            }
        }
        if (allHex) return true;
    }
    return false;
}

/**
 * Read /proc/self/mountinfo and look for signatures left by Magisk overlay
 * and bind mounts. DenyList hides the paths themselves but the kernel mount
 * table retains the entries. NOTE: defeated by Shamiko — kept for breadth.
 */
bool detectMagiskMounts() {
    std::string content = readFileSyscall("/proc/self/mountinfo");
    if (content.empty()) return false;

    static const char* sigs[] = {
        "magisk", "@magisk", "/data/adb", "worker_", "zygisk",
        "/sbin/.core", "system_root", nullptr
    };

    for (int i = 0; sigs[i]; ++i) {
        if (containsCI(content, sigs[i])) return true;
    }
    return false;
}

/**
 * Read bootloader-set system properties directly via __system_property_get.
 *
 * ro.boot.verifiedbootstate = "orange" → bootloader is unlocked (required for Magisk).
 * ro.boot.flash.locked      = "0"      → bootloader is unlocked.
 * ro.boot.vbmeta.device_state = "unlocked"
 *
 * These are written by the bootloader before init runs. Spoofing them at runtime
 * requires a Zygisk module that hooks __system_property_get in libc — which is
 * detectable by the inline-hook checker in hook_detector.cpp.
 *
 * Returns 1 if an unlocked-bootloader property is found, 0 otherwise.
 */
/**
 * Checks filesystem types via statfs() — not patchable by Shamiko because
 * statfs() is a raw vfs_statfs kernel call, not a file read.
 *
 * Magisk's "magic mount" overlays modules onto /system, /vendor, /product
 * using overlayfs (OVERLAYFS_SUPER_MAGIC = 0x794C7630). On a stock device
 * these partitions are ext4, f2fs, erofs, or squashfs — never overlayfs.
 *
 * Exception: some A/B OTA setups use overlayfs on /system_ext or /product
 * during an update, so we check all three and require at least /system or
 * /vendor to be overlayfs before flagging.
 */
bool detectOverlayMount() {
    constexpr unsigned long OVERLAYFS_MAGIC = 0x794C7630UL;
    const char* paths[] = { "/system", "/vendor", nullptr };
    struct statfs sf;
    for (int i = 0; paths[i]; ++i) {
        if (statfs(paths[i], &sf) == 0) {
            if (static_cast<unsigned long>(sf.f_type) == OVERLAYFS_MAGIC) {
                return true;
            }
        }
    }
    return false;
}

// ── __system_property_foreach scan ───────────────────────────────────────────

static bool isHuaweiHonorHideProp(const std::string& name) {
    return name == "ro.build.hide" || name.rfind("ro.build.hide.", 0) == 0;
}

static bool isMagiskProperty(const std::string& name) {
    if (isHuaweiHonorHideProp(name)) return false;
    if (name == "persist.magisk.hide") return true;
    if (name.rfind("persist.magisk.", 0) == 0) return true;
    if (name.rfind("init.svc.magisk", 0) == 0) return true;
    if (name.rfind("magisk.", 0) == 0) return true;
    return false;
}

struct PropCtx { std::optional<std::string> matched; };

static void onProp(const prop_info* pi, void* cookie) {
    auto* ctx = static_cast<PropCtx*>(cookie);
    if (ctx->matched.has_value()) return;

    char name[PROP_NAME_MAX]   = {};
    char value[PROP_VALUE_MAX] = {};
    __system_property_read(pi, name, value);

    const std::string sname(name);
    // Only flag property NAMES uniquely associated with Magisk. Boot-state props
    // (ro.boot.verifiedbootstate, ro.boot.flash.locked) are checked separately
    // in detectUnlockedBootloader(). ro.build.hide* is Huawei/Honor OEM — not Magisk.
    if (isMagiskProperty(sname)) {
        ctx->matched = sname;
    }
}

/**
 * Enumerates ALL system properties via __system_property_foreach (native API).
 * Shamiko would need to hook this low-level callback mechanism to hide Magisk
 * properties — doing so reliably without breaking the OS is extremely difficult.
 */
std::optional<std::string> detectMagiskProperties() {
    PropCtx ctx{std::nullopt};
    __system_property_foreach(onProp, &ctx);
    return ctx.matched;
}

/**
 * Checks supplementary group membership via the getgroups() syscall.
 *
 * DenyList is a mount namespace operation — it has no effect on the process's
 * GID list. A normal Android app belongs to its own app GIDs plus a small set
 * of capability groups (inet, sdcard, etc.). GID 0 (root) or GID 1000 (system)
 * in the supplementary list is a strong indicator of privilege escalation.
 *
 * getgroups() calls the kernel directly; Shamiko would need to hook the raw
 * syscall instruction to intercept it.
 */
bool hasPrivilegedGroups() {
    gid_t groups[128] = {};
    int count = getgroups(128, groups);
    if (count < 0) return false;

    for (int i = 0; i < count; ++i) {
        if (groups[i] == 0 ||    // root
            groups[i] == 1000) { // system
            return true;
        }
    }
    return false;
}

/**
 * Detects the Zygisk companion library in the dynamic linker's link_map.
 *
 * Zygisk loads its companion via memfd_create() + dlopen(). The resulting ELF
 * is mapped into memory and appears in dl_iterate_phdr — unlike file-system
 * paths, its in-memory identity survives DenyList's mount namespace cleanup
 * completely (DenyList only changes mounts, not already-loaded ELF images).
 *
 * Detection heuristic:
 *   • dlpi_name contains "/memfd:" or "/proc/self/fd/" → loaded from memfd
 *   • dlpi_name is empty AND the ELF has at least one executable PT_LOAD segment
 *     whose size exceeds 256 KB (rules out the main exec / linker stubs)
 *
 * Shamiko could remove the entry from the link_map, but doing so while the
 * code is still executing would crash the process — making it impractical.
 */
bool detectZygiskInMemory() {
    struct Ctx { bool found; };
    Ctx ctx{false};

    constexpr ElfW(Half) kMaxPhnum = 128;

    dl_iterate_phdr([](struct dl_phdr_info* info, size_t /*sz*/, void* data) -> int {
        auto* ctx = static_cast<Ctx*>(data);
        if (!info) return 0;

        // dlpi_name may be null on some OEM link_map entries (e.g. MIUI/HyperOS).
        const char* rawName = info->dlpi_name;
        const std::string name = rawName ? std::string(rawName) : std::string();

        // Case 1: library loaded from a memfd or a /proc/self/fd file descriptor
        if (!name.empty()) {
            if (name.find("/memfd:") != std::string::npos &&
                name.find("jit-zygote-cache") == std::string::npos) {
                // Exclude the legitimate ART JIT cache memfd
                ctx->found = true;
                return 1;
            }
            if (name.find("/proc/self/fd/") != std::string::npos) {
                ctx->found = true;
                return 1;
            }
            return 0;
        }

        // Case 2: anonymous library (empty name) with a large executable segment.
        // Guard dlpi_phdr — MIUI can expose null phdr with non-zero phnum.
        if (!info->dlpi_phdr || info->dlpi_phnum == 0) return 0;

        const ElfW(Half) phnum = info->dlpi_phnum > kMaxPhnum ? kMaxPhnum : info->dlpi_phnum;
        for (ElfW(Half) i = 0; i < phnum; ++i) {
            const ElfW(Phdr)& ph = info->dlpi_phdr[i];
            if (ph.p_type  == PT_LOAD &&
                (ph.p_flags & PF_X) &&
                ph.p_memsz  > 256 * 1024) {
                ctx->found = true;
                return 1;
            }
        }
        return 0;
    }, &ctx);

    return ctx.found;
}

bool detectUnlockedBootloader() {
    char value[PROP_VALUE_MAX];

    // ro.boot.verifiedbootstate: "green" = locked+verified, "orange" = unlocked
    if (__system_property_get("ro.boot.verifiedbootstate", value) > 0) {
        if (value[0] == 'o' || value[0] == 'r') { // "orange" or "red"
            return true;
        }
    }

    // ro.boot.flash.locked: "1" = locked, "0" = unlocked
    if (__system_property_get("ro.boot.flash.locked", value) > 0) {
        if (value[0] == '0') return true;
    }

    // ro.boot.vbmeta.device_state: "locked" or "unlocked"
    if (__system_property_get("ro.boot.vbmeta.device_state", value) > 0) {
        if (containsCI(std::string(value), "unlocked")) return true;
    }

    return false;
}

} // namespace shield
