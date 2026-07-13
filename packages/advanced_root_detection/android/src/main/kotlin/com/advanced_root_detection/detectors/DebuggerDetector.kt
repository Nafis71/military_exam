package com.advanced_root_detection.detectors

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Debug
import com.advanced_root_detection.ThreatResult
import java.io.BufferedReader
import java.io.FileReader

/**
 * Detects attached debuggers.
 *
 * Reference: OWASP MASTG MSTG-RESILIENCE-2
 * https://mas.owasp.org/MASTG/tests/android/MASVS-RESILIENCE/MASTG-TEST-0046/
 */
class DebuggerDetector(private val context: Context) {

    fun detect(): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        // 1. Java debugger attached
        if (Debug.isDebuggerConnected()) {
            threats += ThreatResult(
                category = "debuggerAttached",
                description = "Java debugger is connected (Debug.isDebuggerConnected())",
                severity = "critical"
            )
        }

        // 2. Application is debuggable
        val appInfo = context.applicationInfo
        if (appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            threats += ThreatResult(
                category = "debuggerAttached",
                description = "Application has FLAG_DEBUGGABLE set in manifest",
                severity = "high"
            )
        }

        // 3. TracerPid non-zero in /proc/self/status
        readTracerPid()?.let { pid ->
            threats += ThreatResult(
                category = "debuggerAttached",
                description = "Non-zero TracerPid in /proc/self/status (TracerPid: $pid) — debugger attached",
                severity = "critical",
                details = mapOf("tracerPid" to pid)
            )
        }

        return threats
    }

    private fun readTracerPid(): String? {
        return try {
            BufferedReader(FileReader("/proc/self/status")).useLines { lines ->
                lines.firstNotNullOfOrNull { line ->
                    if (line.startsWith("TracerPid:")) {
                        val pid = line.substringAfter("TracerPid:").trim()
                        if (pid != "0") pid else null
                    } else null
                }
            }
        } catch (_: Exception) {
            null
        }
    }
}
