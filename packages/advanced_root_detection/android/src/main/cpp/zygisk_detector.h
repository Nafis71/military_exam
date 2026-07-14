#pragma once

#include <optional>
#include <string>

namespace shield {
    /** Scan /proc/self/task/<tid>/comm for Zygisk companion thread names. */
    bool detectZygiskThreads();

    /** Scan /proc/<pid>/cmdline for the Magisk supervisor daemon (magiskd). */
    bool detectMagiskProcess();

    /** Scan /proc/net/unix for the 32-hex-char Magisk daemon abstract socket. */
    bool detectMagiskSocket();

    /** Scan /proc/self/mountinfo for Magisk overlay/bind-mount signatures. */
    bool detectMagiskMounts();

    /**
     * Check ro.boot.verifiedbootstate / ro.boot.flash.locked via
     * __system_property_get (native). An unlocked bootloader is required for
     * Magisk; spoofing these properties from userspace requires hooking libc
     * which is detectable by the inline-hook checker.
     */
    bool detectUnlockedBootloader();

    /**
     * statfs() on /system and /vendor to check for overlayfs (OVERLAYFS_SUPER_MAGIC).
     * Magisk magic-mount uses overlayfs; statfs goes to the kernel directly and
     * cannot be intercepted by Shamiko's userspace libc hooks.
     */
    bool detectOverlayMount();

    /**
     * getgroups() syscall: check for GID 0 (root) or GID 1000 (system) in the
     * process's supplementary group list. DenyList cannot change GIDs.
     */
    bool hasPrivilegedGroups();

    /**
     * dl_iterate_phdr scan for the Zygisk companion ELF loaded via memfd_create.
     * Survives DenyList because it is already mapped into process memory before
     * DenyList's mount namespace cleanup runs.
     */
    bool detectZygiskInMemory();

    /**
     * Walk ALL system properties via __system_property_foreach looking for
     * Magisk-specific property names. Returns the first matched property name,
     * or std::nullopt on clean devices. Huawei/Honor ro.build.hide.* OEM props
     * are explicitly excluded.
     */
    std::optional<std::string> detectMagiskProperties();
} // namespace shield
