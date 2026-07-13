package com.advanced_root_detection.detectors

import com.advanced_root_detection.ThreatResult

/**
 * Bridge to the NDK C++ security checks in libshield.so.
 *
 * The native layer provides hardened checks that are significantly harder to
 * bypass than Java-layer checks alone, as an attacker must hook both layers.
 *
 * If the native library fails to load (e.g., unsupported ABI in tests),
 * this detector degrades gracefully to returning an empty list.
 */
object NativeDetector {

    private var nativeAvailable = false

    init {
        try {
            System.loadLibrary("shield")
            nativeAvailable = true
        } catch (_: UnsatisfiedLinkError) {
            // Native library not available (unit tests, unsupported ABI)
        }
    }

    /**
     * Runs all NDK-level checks.
     * Returns a list of [ThreatResult]s or an empty list if native is unavailable.
     */
    fun runNativeChecks(): List<ThreatResult> {
        if (!nativeAvailable) return emptyList()
        return try {
            val rawResults = nativeRunChecks() ?: return emptyList()
            rawResults.mapNotNull { map ->
                if (map == null) return@mapNotNull null
                ThreatResult(
                    category = map["category"] ?: "integrityViolation",
                    description = map["description"] ?: "",
                    severity = map["severity"] ?: "high",
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun getSystemProperty(name: String): String {
        if (!nativeAvailable || name.isBlank()) return ""
        return try {
            nativeGetProperty(name) ?: ""
        } catch (_: Exception) {
            ""
        }
    }

    /**
     * JNI method implemented in jni_bridge.cpp.
     * Returns an array of maps, each representing one detected threat.
     */
    @JvmStatic
    private external fun nativeRunChecks(): Array<Map<String, String>?>?

    /**
     * JNI method implemented in jni_bridge.cpp.
     * Reads a system property via native __system_property_get.
     */
    @JvmStatic
    private external fun nativeGetProperty(name: String): String?
}
