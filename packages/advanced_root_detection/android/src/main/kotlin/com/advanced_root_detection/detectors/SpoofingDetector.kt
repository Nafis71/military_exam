package com.advanced_root_detection.detectors

import android.content.Context
import android.os.Build
import android.provider.Settings
import com.advanced_root_detection.DetectionConfig
import com.advanced_root_detection.ThreatResult

/**
 * Detects developer-mode / ADB spoofing and system-property tampering.
 *
 * Uses multi-source signals and compares Java SystemProperties against native
 * __system_property_get reads to catch hook-based spoofing modules.
 */
class SpoofingDetector(
    private val context: Context,
    private val config: DetectionConfig,
) {

    /**
     * Developer-mode signals via Settings only — no native property reads.
     * Used when [DetectionConfig.scope] is essential.
     */
    fun detectDeveloperModeOnly(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()
        val strict = config.strictExamIntegrity

        val settingsDevEnabled = isDeveloperModeEnabled()
        val adbEnabled = isAdbEnabled()
        val wirelessAdbEnabled = isWirelessAdbEnabled()

        if (settingsDevEnabled || adbEnabled || wirelessAdbEnabled) {
            val severity = when {
                strict -> "high"
                config.treatDeveloperModeAsThreat -> "medium"
                else -> "info"
            }
            threats += ThreatResult(
                category = "debuggerAttached",
                description = "Developer options or ADB enabled (multi-source check)",
                severity = severity,
            )
        }

        return threats
    }

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()
        val strict = config.strictExamIntegrity

        val settingsDevEnabled = isDeveloperModeEnabled()
        val adbEnabled = isAdbEnabled()
        val wirelessAdbEnabled = isWirelessAdbEnabled()
        val nativeDevSignals = hasNativeDeveloperSignals()

        if (nativeDevSignals && !settingsDevEnabled && !adbEnabled && !wirelessAdbEnabled) {
            threats += ThreatResult(
                category = "integrityViolation",
                description = "Developer settings spoofing detected: native ADB/dev " +
                    "signals active but Settings report off",
                severity = if (strict) "critical" else "medium",
            )
        }

        if (settingsDevEnabled || adbEnabled || wirelessAdbEnabled || nativeDevSignals) {
            val severity = when {
                strict -> "high"
                config.treatDeveloperModeAsThreat -> "medium"
                else -> "info"
            }
            threats += ThreatResult(
                category = "debuggerAttached",
                description = "Developer options or ADB enabled (multi-source check)",
                severity = severity,
            )
        }

        val tamperProps = listOf(
            "ro.debuggable",
            "ro.secure",
            "ro.build.type",
            "ro.boot.verifiedbootstate",
        )
        for (prop in tamperProps) {
            val javaValue = getJavaSystemProperty(prop)
            val nativeValue = NativeDetector.getSystemProperty(prop)
            if (javaValue.isNotEmpty() &&
                nativeValue.isNotEmpty() &&
                !javaValue.equals(nativeValue, ignoreCase = true)
            ) {
                threats += ThreatResult(
                    category = "integrityViolation",
                    description = "System property spoofing detected: $prop " +
                        "java=$javaValue native=$nativeValue",
                    severity = if (strict) "critical" else "high",
                    details = mapOf("property" to prop, "java" to javaValue, "native" to nativeValue),
                )
            }
        }

        return threats
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
            0,
        ) != 0
    }

    private fun isAdbEnabled(): Boolean {
        return Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.ADB_ENABLED,
            0,
        ) != 0
    }

    private fun isWirelessAdbEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        return try {
            Settings.Global.getInt(
                context.contentResolver,
                "adb_wifi_enabled",
                0,
            ) != 0
        } catch (_: Exception) {
            false
        }
    }

    private fun hasNativeDeveloperSignals(): Boolean {
        val adbdRunning = NativeDetector.getSystemProperty("init.svc.adbd")
            .equals("running", ignoreCase = true)
        val usbConfig = NativeDetector.getSystemProperty("persist.sys.usb.config").lowercase()
        val adbPort = NativeDetector.getSystemProperty("service.adb.tcp.port")
        val roDebuggable = NativeDetector.getSystemProperty("ro.debuggable") == "1"
        val buildType = NativeDetector.getSystemProperty("ro.build.type")
        val nonProductionBuild = buildType == "userdebug" || buildType == "eng"

        return adbdRunning ||
            usbConfig.contains("adb") ||
            (adbPort.isNotEmpty() && adbPort != "0" && adbPort != "-1") ||
            roDebuggable ||
            nonProductionBuild
    }

    private fun getJavaSystemProperty(name: String): String {
        return try {
            val cls = Class.forName("android.os.SystemProperties")
            val method = cls.getMethod("get", String::class.java)
            method.invoke(null, name) as? String ?: ""
        } catch (_: Exception) {
            ""
        }
    }
}
