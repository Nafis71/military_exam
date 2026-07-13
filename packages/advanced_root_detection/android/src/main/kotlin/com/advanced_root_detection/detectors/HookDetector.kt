package com.advanced_root_detection.detectors

import android.content.Context
import android.content.pm.PackageManager
import com.advanced_root_detection.ThreatResult
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.Socket

/**
 * Detects hooking frameworks: Frida, Xposed/LSPosed/EdXposed, Cydia Substrate.
 *
 * Reference: OWASP MASTG MSTG-RESILIENCE-4
 * https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0048/
 */
class HookDetector(private val context: Context) {

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        threats += detectFrida()
        threats += detectXposed()

        if (isCydiaSubstratePresent()) {
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "Cydia Substrate library detected",
                severity = "critical"
            )
        }

        return threats
    }

    // ── Frida ────────────────────────────────────────────────────────────────

    private fun detectFrida(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        // 1. Frida default port 27042
        if (isFridaPortOpen()) {
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "Frida server detected: port 27042 is listening",
                severity = "critical",
                details = mapOf("port" to "27042")
            )
        }

        // 2. frida-server process name in /proc
        if (isFridaProcessRunning()) {
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "frida-server process found in /proc",
                severity = "critical"
            )
        }

        // 3. Frida artifacts in /proc/self/maps
        val fridaMapsHit = scanMapsForFrida()
        if (fridaMapsHit != null) {
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "Frida library mapped in process memory: $fridaMapsHit",
                severity = "critical",
                details = mapOf("mapEntry" to fridaMapsHit)
            )
        }

        return threats
    }

    private fun isFridaPortOpen(): Boolean {
        return try {
            Socket("127.0.0.1", 27042).use { true }
        } catch (_: Exception) {
            false
        }
    }

    private fun isFridaProcessRunning(): Boolean {
        return try {
            File("/proc").listFiles()?.any { dir ->
                if (!dir.isDirectory) return@any false
                try {
                    val cmdline = File(dir, "cmdline").readText().trim('\u0000')
                    cmdline.contains("frida-server", ignoreCase = true) ||
                            cmdline.contains("frida-agent", ignoreCase = true)
                } catch (_: Exception) {
                    false
                }
            } ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun scanMapsForFrida(): String? {
        val fridaSignatures = listOf("frida", "gum-js-loop", "gadget", "frida-agent")
        return try {
            BufferedReader(FileReader("/proc/self/maps")).useLines { lines ->
                lines.firstOrNull { line ->
                    fridaSignatures.any { sig -> line.contains(sig, ignoreCase = true) }
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    // ── Xposed / LSPosed / EdXposed ──────────────────────────────────────────

    private fun detectXposed(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        // 1. XposedBridge class
        if (isXposedBridgePresent()) {
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "XposedBridge class found in runtime — Xposed framework active",
                severity = "critical"
            )
        }

        // 2. XposedInstaller / LSPosed packages
        val xposedPackages = listOf(
            "de.robv.android.xposed.installer",
            "org.meowcat.edxposed.manager",
            "com.android.xposed",
            "org.lsposed.manager",
        )
        xposedPackages.firstOrNull { isPackageInstalled(it) }?.let { pkg ->
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "Xposed/LSPosed manager installed: $pkg",
                severity = "critical",
                details = mapOf("package" to pkg)
            )
        }

        // 3. XposedBridge.jar on disk
        if (File("/system/framework/XposedBridge.jar").exists()) {
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "XposedBridge.jar found at /system/framework/XposedBridge.jar",
                severity = "critical"
            )
        }

        return threats
    }

    private fun isXposedBridgePresent(): Boolean {
        return try {
            Class.forName("de.robv.android.xposed.XposedBridge")
            true
        } catch (_: ClassNotFoundException) {
            false
        }
    }

    // ── Cydia Substrate ──────────────────────────────────────────────────────

    private fun isCydiaSubstratePresent(): Boolean {
        return try {
            // Check for substrate shared library in process maps
            BufferedReader(FileReader("/proc/self/maps")).useLines { lines ->
                lines.any { it.contains("substrate", ignoreCase = true) || it.contains("libsubstrate", ignoreCase = true) }
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
}
