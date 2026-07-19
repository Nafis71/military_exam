package com.advanced_root_detection.detectors

import android.content.Context
import android.media.projection.MediaProjectionManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.provider.Settings
import com.advanced_root_detection.DetectionConfig
import com.advanced_root_detection.ThreatResult

/**
 * Detects environment-level signals: VPN, developer mode, ADB, screen capture.
 *
 * Reference: OWASP MASTG
 * https://mas.owasp.org/MASTG/
 */
class EnvironmentDetector(private val context: Context, private val config: DetectionConfig) {

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        // 1. Developer mode / ADB enabled
        if (!config.skipDeveloperMode && isDeveloperModeEnabled()) {
            val severity = if (config.treatDeveloperModeAsThreat) "medium" else "info"
            threats += ThreatResult(
                category = "debuggerAttached",
                description = "Developer options / ADB enabled on device",
                severity = severity
            )
        }

        // 2. VPN active
        if (config.checkVpn && isVpnActive()) {
            threats += ThreatResult(
                category = "analysisEnvironment",
                description = "Active VPN connection detected",
                severity = "info"
            )
        }

        // 3. Accessibility services (potential keyloggers / overlays)
        getAbusiveAccessibilityServices()?.let { serviceList ->
            threats += ThreatResult(
                category = "runtimeManipulation",
                description = "Potentially abusive accessibility services active: $serviceList",
                severity = "medium",
                details = mapOf("services" to serviceList)
            )
        }

        return threats
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
        ) != 0
    }

    private fun isVpnActive(): Boolean {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(network) ?: return false
            caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        } catch (_: Exception) {
            false
        }
    }

    private fun getAbusiveAccessibilityServices(): String? {
        return try {
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (enabled.isNullOrBlank()) return null
            val services = enabled.split(":").filter { it.isNotBlank() }
            // Flag any service not belonging to the current app or known system services
            val suspicious = services.filter { service ->
                !service.startsWith(context.packageName) &&
                        !service.startsWith("com.android") &&
                        !service.startsWith("com.google") &&
                        !service.startsWith("com.samsung") &&
                        !service.startsWith("com.sec")
            }
            if (suspicious.isNotEmpty()) suspicious.joinToString(", ") else null
        } catch (_: Exception) {
            null
        }
    }
}
