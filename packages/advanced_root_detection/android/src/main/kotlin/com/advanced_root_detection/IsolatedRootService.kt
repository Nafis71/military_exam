package com.advanced_root_detection

import android.app.Service
import android.content.Intent
import android.os.IBinder
import com.advanced_root_detection.detectors.NativeDetector
import com.advanced_root_detection.detectors.RootDetector
import org.json.JSONArray
import org.json.JSONObject

class IsolatedRootService : Service() {

    private val binder = object : IRootDetectionService.Stub() {
        override fun evaluateThreats(configJson: String): String {
            val threats = mutableListOf<ThreatResult>()

            // Run Android filesystem & process checks
            threats += RootDetector(this@IsolatedRootService).detect()

            // Run Native C++ checks
            threats += NativeDetector.runNativeChecks()

            // Optional: you could parse configJson to run other detectors that need config
            // For isolated process, RootDetector and NativeDetector are the most critical
            // for breaking out of Mount Namespaces and DenyList masking!

            // Serialize to JSON
            val array = JSONArray()
            threats.forEach { threat ->
                val obj = JSONObject()
                obj.put("category", threat.category)
                obj.put("description", threat.description)
                obj.put("severity", threat.severity)
                threat.details?.let { obj.put("details", JSONObject(it as Map<*, *>)) }
                array.put(obj)
            }
            return array.toString()
        }
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }
}
