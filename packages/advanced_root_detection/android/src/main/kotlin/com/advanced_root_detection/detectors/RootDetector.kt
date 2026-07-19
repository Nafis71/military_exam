package com.advanced_root_detection.detectors

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.advanced_root_detection.DetectionConfig
import com.advanced_root_detection.ThreatResult
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

/**
 * Detects root / privileged-access indicators on Android.
 *
 * Implements checks from OWASP MASTG MSTG-RESILIENCE-1 and techniques
 * from the open-source RootBeer library (Apache-2.0).
 * References:
 *   https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0045/
 *   https://github.com/scottyab/rootbeer
 */
class RootDetector(
    private val context: Context,
    private val config: DetectionConfig = DetectionConfig(),
) {

    private val suPaths = listOf(
        "/system/bin/su",
        "/system/xbin/su",
        "/sbin/su",
        "/vendor/bin/su",
        "/data/local/xbin/su",
        "/data/local/bin/su",
        "/system/sd/xbin/su",
        "/system/bin/failsafe/su",
        "/data/local/su",
        "/su/bin/su",
    )

    private val magiskPaths = listOf(
        "/sbin/.magisk",
        "/data/adb/magisk",
        "/cache/.disable_magisk",
        "/dev/.magisk.unblock",
        "/data/adb/magisk.db",
        "/data/adb/modules",
        "/sbin/.core/mirror",
        "/sbin/.core/img",
    )

    private val rootPackages = listOf(
        "com.noshufou.android.su",
        "com.noshufou.android.su.elite",
        "eu.chainfire.supersu",
        "com.koushikdutta.superuser",
        "com.thirdparty.superuser",
        "com.yellowes.su",
        "com.topjohnwu.magisk",
        "com.kingroot.kinguser",
        "com.kingo.root",
        "com.smedialink.oneclickroot",
        "com.zhiqupk.root.global",
        "com.alephzain.framaroot",
        "com.koushikdutta.rommanager",
        "com.dimonvideo.luckypatcher",
        "com.chelpus.lackypatch",
        "com.ramdroid.appquarantine",
        "com.ramdroid.appquarantinepro",
    )

    fun detect(): List<ThreatResult> {
        if (config.skipRootOnEmulator && EmulatorDetector.isEmulator(context)) {
            return emptyList()
        }

        val threats = mutableListOf<ThreatResult>()

        // 1. su binary presence
        suPaths.firstOrNull { File(it).exists() }?.let { path ->
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "su binary found at $path",
                severity = "critical",
                details = mapOf("path" to path)
            )
        }

        // 2. BusyBox presence
        if (File("/system/xbin/busybox").exists() || File("/system/bin/busybox").exists()) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "BusyBox binary detected — common on rooted devices",
                severity = "medium"
            )
        }

        // 3. Magisk artifacts (file-based; bypassed by DenyList but kept as complementary layer)
        magiskPaths.firstOrNull { File(it).exists() }?.let { path ->
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Magisk artifact found at $path",
                severity = "critical",
                details = mapOf("path" to path)
            )
        }

        // 4. Test-keys in Build.TAGS
        if (Build.TAGS?.contains("test-keys") == true) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Build signed with test-keys (non-release build)",
                severity = "high",
                details = mapOf("tags" to (Build.TAGS ?: ""))
            )
        }

        // 5. Dangerous system properties
        checkDangerousProps()?.let { threats += it }

        // 6. /system mounted read-write
        if (isSystemMountedRW()) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "/system partition is mounted read-write",
                severity = "critical"
            )
        }

        // 7. Root manager packages
        rootPackages.firstOrNull { isPackageInstalled(it) }?.let { pkg ->
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Root management app installed: $pkg",
                severity = "critical",
                details = mapOf("package" to pkg)
            )
        }



        // ── DenyList-specific checks (kernel mount namespace bypass) ──────────
        // DenyList unmounts /data/adb/magisk from the app's mount namespace, but it
        // does NOT unmount the Magisk app's own /data/data/ directory. These checks
        // operate on facts that DenyList's mount namespace manipulation cannot reach.

        // 9a. Magisk app data directory.
        // DenyList unmounts /data/adb/magisk* but never /data/data/com.topjohnwu.magisk
        // because that is the Magisk app's legitimate data directory — removing it
        // would break the Magisk app itself. This check is not a file-path hint
        // (easily hooked) but a direct stat() on a path DenyList never touches.
        detectMagiskAppDirectory()?.let { threats += it }


        // ── DenyList + Shamiko-resistant checks ───────────────────────────────
        // Shamiko patches /proc/net/unix, /proc/self/mountinfo, thread names, and
        // the process list before the app reads them. The checks below work on facts
        // that cannot be patched at the userspace level.

        // 9. Bootloader unlock state.
        // Magisk requires an unlocked bootloader. ro.boot.verifiedbootstate is written
        // by the bootloader itself before the OS starts; "orange" means unlocked.
        // Spoofing it requires a Zygisk module that also patches __system_property_get
        // inside the native layer — which itself leaves a detectable hook trace.
        checkBootloaderState()?.let { threats += it }

        // 10. SELinux enforcement.
        // Many root workflows set SELinux permissive. Read the kernel file directly
        // (/sys/fs/selinux/enforce) rather than using the Java API, which can be hooked.
        // Severity is medium because a small number of unmodified OEM ROMs ship
        // with permissive SELinux for specific hardware features.
        if (isSELinuxPermissive()) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "SELinux is in permissive mode — common on rooted devices",
                severity = "medium"
            )
        }

        // 11. Soft DenyList checks (defeated by Shamiko, kept as complementary layer).
        if (detectMagiskSocket()) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Magisk daemon socket detected in /proc/net/unix",
                severity = "critical"
            )
        }
        if (detectSuspiciousMounts()) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Suspicious Magisk mount entries in /proc/self/mountinfo",
                severity = "critical"
            )
        }
        if (detectZygiskThreads()) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Zygisk companion thread detected — Magisk active despite DenyList",
                severity = "critical"
            )
        }
        if (detectMagiskProcess()) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Magisk daemon (magiskd) found in running process list",
                severity = "critical"
            )
        }

        return threats
    }

    private fun checkDangerousProps(): ThreatResult? {
        val dangerousProps = mapOf(
            "ro.debuggable" to "1",
            "ro.secure" to "0",
        )
        for ((prop, dangerousValue) in dangerousProps) {
            val value = getSystemProperty(prop)
            if (value == dangerousValue) {
                return ThreatResult(
                    category = "privilegedAccess",
                    description = "Dangerous system property: $prop=$value",
                    severity = "high",
                    details = mapOf("property" to prop, "value" to value)
                )
            }
        }
        val buildType = getSystemProperty("ro.build.type")
        if (buildType == "userdebug" || buildType == "eng") {
            return ThreatResult(
                category = "privilegedAccess",
                description = "Non-production build type detected: ro.build.type=$buildType",
                severity = "high",
                details = mapOf("buildType" to buildType)
            )
        }
        return null
    }

    private fun isSystemMountedRW(): Boolean {
        return try {
            BufferedReader(InputStreamReader(File("/proc/mounts").inputStream())).useLines { lines ->
                lines.any { line ->
                    val parts = line.split(" ")
                    parts.size >= 4 && parts[1] == "/system" && parts[3].startsWith("rw")
                }
            }
        } catch (_: Exception) {
            false
        }
    }


    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun getSystemProperty(name: String): String {
        return try {
            val cls = Class.forName("android.os.SystemProperties")
            val method = cls.getMethod("get", String::class.java)
            method.invoke(null, name) as? String ?: ""
        } catch (_: Exception) {
            ""
        }
    }

    // ── DenyList-specific helpers ──────────────────────────────────────────────

    /**
     * DenyList unmounts Magisk system paths (/data/adb/magisk, /sbin/.magisk …)
     * but cannot unmount the Magisk application's own data directory because
     * /data/data/com.topjohnwu.magisk is the installed app's private storage —
     * removing it from the namespace would crash the Magisk app itself.
     *
     * Checking for directory existence via File.exists() (which calls stat()) is
     * NOT defeated by DenyList's mount namespace cleanup.
     */
    private fun detectMagiskAppDirectory(): ThreatResult? {
        val magiskDataPaths = listOf(
            "/data/data/com.topjohnwu.magisk",
            "/data/user/0/com.topjohnwu.magisk",
            // Canary / debug builds
            "/data/data/io.github.vvb2060.magisk",
            "/data/data/io.github.vvb2060.magisk.canary",
        )
        val found = magiskDataPaths.firstOrNull { File(it).exists() } ?: return null
        return ThreatResult(
            category = "privilegedAccess",
            description = "Magisk app data directory found at $found " +
                "(DenyList does not hide app data directories)",
            severity = "critical",
            details = mapOf("path" to found)
        )
    }



    // ── Shamiko-resistant helpers ──────────────────────────────────────────────

    /**
     * Checks bootloader-set properties that reflect an unlocked device.
     * ro.boot.verifiedbootstate = "orange" → bootloader was unlocked (required for Magisk).
     * ro.boot.flash.locked = "0"           → bootloader is unlocked.
     * These are set by the bootloader before init runs; spoofing them from userspace
     * requires hooking __system_property_get in libc, which leaves a detectable trace
     * in the native layer's inline-hook check.
     */
    private fun checkBootloaderState(): ThreatResult? {
        val vbstate = getSystemProperty("ro.boot.verifiedbootstate")
        if (vbstate == "orange" || vbstate == "red") {
            return ThreatResult(
                category = "privilegedAccess",
                description = "Bootloader is unlocked (ro.boot.verifiedbootstate=$vbstate)",
                severity = "high",
                details = mapOf("verifiedbootstate" to vbstate)
            )
        }
        val flashLocked = getSystemProperty("ro.boot.flash.locked")
        if (flashLocked == "0") {
            return ThreatResult(
                category = "privilegedAccess",
                description = "Bootloader is unlocked (ro.boot.flash.locked=0)",
                severity = "high",
                details = mapOf("flash.locked" to "0")
            )
        }
        val vbmetaState = getSystemProperty("ro.boot.vbmeta.device_state")
        if (vbmetaState == "unlocked") {
            return ThreatResult(
                category = "privilegedAccess",
                description = "Bootloader is unlocked (ro.boot.vbmeta.device_state=unlocked)",
                severity = "high",
                details = mapOf("vbmeta.device_state" to "unlocked")
            )
        }
        return null
    }

    /**
     * Reads the SELinux enforcement state directly from the kernel sysfs node.
     * "0" = permissive (security policies not enforced — common when rooted).
     * Uses the kernel file instead of Java's SELinux API to avoid hook bypass.
     */
    private fun isSELinuxPermissive(): Boolean {
        return try {
            File("/sys/fs/selinux/enforce").readText().trim() == "0"
        } catch (_: Exception) {
            false
        }
    }

    // ── DenyList-resistant helpers ─────────────────────────────────────────────

    /**
     * Scans /proc/net/unix for the Magisk daemon socket.
     * magiskd creates an abstract socket with a name that is exactly 32 hex characters
     * (prefixed with '@' in /proc/net/unix). DenyList cannot remove kernel socket table
     * entries.
     *
     * Reference: https://github.com/topjohnwu/Magisk/issues/1786
     */
    private fun detectMagiskSocket(): Boolean {
        return try {
            File("/proc/net/unix").bufferedReader().useLines { lines ->
                lines.any { line ->
                    // Each line: Num RefCount Protocol Flags Type St Inode Path
                    // Abstract sockets appear as " @<name>" in the Path column.
                    val path = line.trim().split("\\s+".toRegex()).lastOrNull() ?: return@any false
                    if (!path.startsWith("@")) return@any false
                    val name = path.drop(1)
                    // Magisk daemon socket name is exactly 32 lowercase hex characters
                    name.length == 32 && name.all { it.isDigit() || it in 'a'..'f' }
                }
            }
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Reads /proc/self/mountinfo and looks for mount entries that indicate Magisk
     * overlay or bind mounts. DenyList hides the actual files but the kernel mount
     * table retains the entries.
     *
     * Reference: https://darvincitech.wordpress.com/2019/11/04/detecting-magisk-hide/
     */
    private fun detectSuspiciousMounts(): Boolean {
        val signatures = listOf(
            "magisk", "@magisk", "/data/adb", "worker_", "zygisk",
            "/sbin/.core", "system_root"
        )
        return try {
            File("/proc/self/mountinfo").bufferedReader().useLines { lines ->
                lines.any { line ->
                    val lower = line.lowercase()
                    signatures.any { sig -> lower.contains(sig) }
                }
            }
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Checks /proc/self/task/<tid>/comm for Zygisk companion thread names.
     * Zygisk injects a companion thread into every app process at Zygote fork time,
     * before DenyList's mount remapping runs. The thread name contains "zygisk".
     */
    private fun detectZygiskThreads(): Boolean {
        return try {
            File("/proc/self/task").listFiles()?.any { tidDir ->
                val comm = File(tidDir, "comm").readText().trim().lowercase()
                "zygisk" in comm
            } ?: false
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Iterates /proc/<pid>/cmdline for every running process looking for the Magisk
     * supervisor daemon. magiskd is always running on a rooted device and its cmdline
     * is readable by any process via the /proc filesystem.
     */
    private fun detectMagiskProcess(): Boolean {
        return try {
            File("/proc").listFiles()
                ?.filter { it.name.all(Char::isDigit) }
                ?.any { pidDir ->
                    val cmdline = File(pidDir, "cmdline")
                        .runCatching { readText() }
                        .getOrNull()
                        ?.replace('\u0000', ' ')
                        ?.trim()
                        ?: return@any false
                    cmdline == "magiskd" ||
                        cmdline.startsWith("magisk") && cmdline.contains("daemon")
                } ?: false
        } catch (_: Exception) {
            false
        }
    }
}
