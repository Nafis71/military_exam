package com.advanced_root_detection.detectors

import android.content.Context
import android.os.Build
import android.telephony.TelephonyManager
import com.advanced_root_detection.ThreatResult
import java.io.File

/**
 * Detects emulator / analysis environments.
 *
 * Reference: OWASP MASTG MSTG-RESILIENCE-5
 * https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0049/
 */
class EmulatorDetector(private val context: Context) {

    companion object {
        fun isEmulator(context: Context): Boolean =
            EmulatorDetector(context).detect().isNotEmpty()
    }

    private val emulatorFiles = listOf(
        "/dev/socket/qemud",
        "/dev/qemu_pipe",
        "/system/lib/libc_malloc_debug_qemu.so",
        "/sys/qemu_trace",
        "/system/bin/qemu-props",
        "/dev/socket/genyd",
        "/dev/socket/baseband_genyd",
    )

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        // 1. Build fingerprint / model / manufacturer checks
        checkBuildFields()?.let { threats += it }

        // 2. QEMU system properties
        checkQemuProps()?.let { threats += it }

        // 3. Telephony (zero/fake IMEI, emulator numbers)
        checkTelephony()?.let { threats += it }

        // 4. Emulator-specific files
        emulatorFiles.firstOrNull { File(it).exists() }?.let { path ->
            threats += ThreatResult(
                category = "analysisEnvironment",
                description = "Emulator file found: $path",
                severity = "high",
                details = mapOf("path" to path)
            )
        }

        // 5. Low sensor count (emulators typically have ≤2)
        if (hasTooFewSensors()) {
            threats += ThreatResult(
                category = "analysisEnvironment",
                description = "Abnormally low sensor count — likely running in an emulator",
                severity = "medium"
            )
        }

        return threats
    }

    private fun checkBuildFields(): ThreatResult? {
        val emulatorFingerprints = listOf(
            "generic", "goldfish", "ranchu", "sdk", "emulator",
            "android_x86", "vbox", "test-keys"
        )
        val fingerprint = Build.FINGERPRINT?.lowercase() ?: ""
        val model = Build.MODEL?.lowercase() ?: ""
        val manufacturer = Build.MANUFACTURER?.lowercase() ?: ""
        val hardware = Build.HARDWARE?.lowercase() ?: ""
        val product = Build.PRODUCT?.lowercase() ?: ""

        val allFields = "$fingerprint $model $manufacturer $hardware $product"
        val matched = emulatorFingerprints.firstOrNull { allFields.contains(it) }

        return if (matched != null) {
            ThreatResult(
                category = "analysisEnvironment",
                description = "Emulator signature in Build fields (matched: $matched)",
                severity = "high",
                details = mapOf(
                    "fingerprint" to Build.FINGERPRINT,
                    "model" to Build.MODEL,
                    "manufacturer" to Build.MANUFACTURER,
                )
            )
        } else null
    }

    private fun checkQemuProps(): ThreatResult? {
        val qemuProps = mapOf(
            "ro.kernel.qemu" to "1",
            "ro.hardware" to "goldfish",
            "ro.hardware" to "ranchu",
        )
        for ((prop, value) in qemuProps) {
            val actual = getSystemProperty(prop)
            if (actual == value) {
                return ThreatResult(
                    category = "analysisEnvironment",
                    description = "QEMU system property detected: $prop=$actual",
                    severity = "high",
                    details = mapOf("property" to prop, "value" to actual)
                )
            }
        }
        return null
    }

    @Suppress("MissingPermission")
    private fun checkTelephony(): ThreatResult? {
        return try {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                ?: return null
            val line = tm.line1Number
            if (line == "15555215554" || line == "15555215556") {
                ThreatResult(
                    category = "analysisEnvironment",
                    description = "Emulator phone number detected: $line",
                    severity = "high",
                    details = mapOf("phoneNumber" to line)
                )
            } else null
        } catch (_: Exception) {
            null
        }
    }

    private fun hasTooFewSensors(): Boolean {
        return try {
            val sm = context.getSystemService(Context.SENSOR_SERVICE)
                    as? android.hardware.SensorManager ?: return false
            sm.getSensorList(android.hardware.Sensor.TYPE_ALL).size < 3
        } catch (_: Exception) {
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
}
