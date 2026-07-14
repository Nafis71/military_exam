package com.advanced_root_detection.detectors

import android.os.Build
import com.advanced_root_detection.DetectionConfig
import com.advanced_root_detection.ThreatResult

/**
 * Detects known custom ROM fingerprints that are incompatible with exam integrity.
 */
class CustomRomDetector(private val config: DetectionConfig) {

    private val romMarkers = listOf(
        "lineage",
        "crdroid",
        "evolution",
        "pixelexperience",
        "pixel experience",
        "derpfest",
        "aospa",
        "nameless",
        "awaken",
        "arrow",
        "corvus",
        "dotos",
        "havoc",
        "omnirom",
        "paranoid",
        "statix",
        "yaap",
        "cherish",
        "project elixir",
        "projectelixir",
        "crimson",
        "pixelos",
        "afterlife",
        "bliss",
        "calyx",
        "graphene",
    )

    private val romProperties = listOf(
        "ro.lineage.version",
        "ro.modversion",
        "ro.crdroid.version",
        "ro.evolution.version",
        "ro.pixelexperience.version",
    )

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()
        val strict = config.strictExamIntegrity
        val severity = if (strict) "high" else "info"

        val buildBlob = listOfNotNull(
            Build.FINGERPRINT,
            Build.DISPLAY,
            Build.PRODUCT,
            Build.BRAND,
            Build.MANUFACTURER,
            Build.MODEL,
            Build.DEVICE,
        ).joinToString(" ").lowercase()

        val matchedMarker = romMarkers.firstOrNull { buildBlob.contains(it) }
        if (matchedMarker != null) {
            threats += ThreatResult(
                category = "privilegedAccess",
                description = "Custom ROM detected: $matchedMarker in build fingerprint",
                severity = severity,
                details = mapOf("marker" to matchedMarker),
            )
        }

        for (prop in romProperties) {
            val value = getJavaSystemProperty(prop)
            if (value.isNotEmpty()) {
                threats += ThreatResult(
                    category = "privilegedAccess",
                    description = "Custom ROM property detected: $prop=$value",
                    severity = severity,
                    details = mapOf("property" to prop, "value" to value),
                )
            }
        }

        return threats
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
