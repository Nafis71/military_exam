package com.advanced_root_detection

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.advanced_root_detection.detectors.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import android.content.ComponentName
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import org.json.JSONArray
import java.util.concurrent.CountDownLatch

/**
 * AdvanceRootDetectionPlugin — Flutter plugin entry point.
 *
 * Wires together all native detectors and exposes them via:
 *  - MethodChannel `advanced_root_detection/methods` for one-shot checks
 *  - EventChannel  `advanced_root_detection/threats`  for streaming monitoring
 *
 * Reference: OWASP MASTG (https://mas.owasp.org/MASTG/)
 */
class AdvanceRootDetectionPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context

    private var eventSink: EventChannel.EventSink? = null
    private var scheduler: ScheduledExecutorService? = null
    private var monitoringFuture: ScheduledFuture<*>? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var isolatedService: IRootDetectionService? = null
    private var serviceBindLatch = CountDownLatch(1)

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            isolatedService = IRootDetectionService.Stub.asInterface(service)
            serviceBindLatch.countDown()
        }
        override fun onServiceDisconnected(name: ComponentName?) {
            isolatedService = null
        }
    }

    // ── Flutter plugin lifecycle ─────────────────────────────────────────────

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "advanced_root_detection/methods"
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "advanced_root_detection/threats"
        )
        eventChannel.setStreamHandler(this)

        // Bind to isolated service
        val intent = Intent(context, IsolatedRootService::class.java)
        context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopMonitoringInternal()
        try {
            context.unbindService(serviceConnection)
        } catch (_: Exception) {}
    }

    // ── MethodChannel handler ────────────────────────────────────────────────

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "performCheck" -> {
                val config = parseConfig(call.arguments)
                Executors.newSingleThreadExecutor().execute {
                    try {
                        // Wait briefly if service is still binding
                        serviceBindLatch.await(2, TimeUnit.SECONDS)
                        val report = buildReport(context, config)
                        mainHandler.post { result.success(report) }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("DETECTION_ERROR", e.message, null)
                        }
                    }
                }
            }
            "startMonitoring" -> {
                val config = parseConfig(call.arguments)
                startMonitoringInternal(config)
                result.success(null)
            }
            "stopMonitoring" -> {
                stopMonitoringInternal()
                result.success(null)
            }
            "verifyBeforeSensitiveOp" -> {
                val config = parseConfig(call.arguments)
                Executors.newSingleThreadExecutor().execute {
                    try {
                        val threats = collectAllThreats(context, config)
                        val safe = !hasBlockingThreats(threats, config)
                        mainHandler.post { result.success(safe) }
                    } catch (e: Exception) {
                        mainHandler.post { result.success(false) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    // ── EventChannel (stream) handler ────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopMonitoringInternal()
    }

    // ── Internal monitoring ───────────────────────────────────────────────────

    private fun startMonitoringInternal(config: DetectionConfig) {
        stopMonitoringInternal()
        val intervalSeconds = config.monitoringIntervalSeconds.coerceAtLeast(5).toLong()
        scheduler = Executors.newSingleThreadScheduledExecutor()
        monitoringFuture = scheduler?.scheduleWithFixedDelay(
            {
                try {
                    val threats = collectAllThreats(context, config)
                    threats.forEach { threat ->
                        mainHandler.post { eventSink?.success(threat.toMap()) }
                    }
                } catch (_: Exception) {
                }
            },
            0L,
            intervalSeconds,
            TimeUnit.SECONDS
        )
    }

    private fun stopMonitoringInternal() {
        monitoringFuture?.cancel(false)
        scheduler?.shutdown()
        scheduler = null
        monitoringFuture = null
    }

    // ── Detection orchestration ───────────────────────────────────────────────

    private fun collectAllThreats(ctx: Context, config: DetectionConfig): List<ThreatResult> {
        if (config.isEssentialScope) {
            return collectEssentialThreats(ctx, config)
        }
        return collectFullThreats(ctx, config)
    }

    private fun collectEssentialThreats(
        ctx: Context,
        config: DetectionConfig,
    ): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()
        threats += RootDetector(ctx, config).detect()
        threats += CustomRomDetector(config).detect()
        threats += SpoofingDetector(ctx, config).detectDeveloperModeOnly()
        return threats
    }

    private fun collectFullThreats(ctx: Context, config: DetectionConfig): List<ThreatResult> {
        val threats = mutableListOf<ThreatResult>()

        // Root / privileged access
        threats += RootDetector(ctx, config).detect()

        // Hooking frameworks
        threats += HookDetector(ctx).detect()

        // Emulator / analysis environment
        threats += EmulatorDetector(ctx).detect()

        // Debugger
        threats += DebuggerDetector(ctx).detect()

        // App integrity & tampering
        threats += TamperingDetector(ctx, config).detect()

        // Environment signals
        threats += EnvironmentDetector(ctx, config).detect()

        // Spoofing / property tamper detection
        threats += SpoofingDetector(ctx, config).detect()

        // Custom ROM fingerprints
        threats += CustomRomDetector(config).detect()

        // Hardware Keystore Bootloader Attestation
        threats += BootloaderAttestationDetector().detect()

        // Isolated-process checks (native + root) bypass DenyList/MagiskHide.
        // Prefer isolated native checks; fall back to main-process native only
        // when the isolated service is unavailable (isolated crash won't kill app).
        var isolatedNativeMerged = false
        isolatedService?.let { service ->
            try {
                val jsonString = service.evaluateThreats("{}")
                val array = JSONArray(jsonString)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val category = obj.optString("category", "privilegedAccess")
                    val desc = obj.optString("description", "")
                    val severity = obj.optString("severity", "high")
                    var detailsMap: Map<String, String>? = null

                    if (obj.has("details")) {
                        val d = obj.getJSONObject("details")
                        val map = mutableMapOf<String, String>()
                        d.keys().forEach { k -> map[k] = d.optString(k) }
                        detailsMap = map
                    }
                    val t = ThreatResult(category, desc, severity, detailsMap)
                    if (threats.none { it.description == desc }) {
                        threats.add(t)
                    }
                }
                isolatedNativeMerged = true
            } catch (_: Exception) { }
        }

        if (!isolatedNativeMerged) {
            threats += NativeDetector.runNativeChecks()
        }

        return threats
    }

    private fun hasBlockingThreats(
        threats: List<ThreatResult>,
        config: DetectionConfig,
    ): Boolean {
        if (config.isEssentialScope) {
            return threats.any { it.severity == "critical" || it.severity == "high" }
        }
        return threats.any { it.severity == "critical" || it.severity == "high" }
    }

    private fun buildReport(ctx: Context, config: DetectionConfig): Map<String, Any> {
        val threats = collectAllThreats(ctx, config)
        return mapOf(
            "detectedThreats" to threats.map { it.toMap() },
            "checkedAt" to java.time.Instant.now().toString()
        )
    }

    // ── Config parsing ────────────────────────────────────────────────────────

    @Suppress("UNCHECKED_CAST")
    private fun parseConfig(arguments: Any?): DetectionConfig {
        val args = arguments as? Map<String, Any?> ?: return DetectionConfig()
        val androidArgs = args["android"] as? Map<String, Any?> ?: emptyMap()
        return DetectionConfig(
            packageName = androidArgs["packageName"] as? String,
            signingCertHashes = (androidArgs["signingCertHashes"] as? List<String>) ?: emptyList(),
            allowedInstallers = (androidArgs["allowedInstallers"] as? List<String>) ?: listOf("googlePlay", "amazonAppstore"),
            checkVpn = androidArgs["checkVpn"] as? Boolean ?: false,
            treatDeveloperModeAsThreat = androidArgs["treatDeveloperModeAsThreat"] as? Boolean ?: false,
            allowSideload = androidArgs["allowSideload"] as? Boolean ?: false,
            strictExamIntegrity = androidArgs["strictExamIntegrity"] as? Boolean ?: false,
            skipRootOnEmulator = androidArgs["skipRootOnEmulator"] as? Boolean ?: false,
            skipDeveloperModeOnEmulator = androidArgs["skipDeveloperModeOnEmulator"] as? Boolean ?: false,
            monitoringIntervalSeconds = (args["monitoringIntervalSeconds"] as? Int) ?: 30,
            scope = args["scope"] as? String ?: "essential",
        )
    }
}

// ── Shared data structures ────────────────────────────────────────────────────

data class DetectionConfig(
    val packageName: String? = null,
    val signingCertHashes: List<String> = emptyList(),
    val allowedInstallers: List<String> = listOf("googlePlay", "amazonAppstore"),
    val checkVpn: Boolean = false,
    val treatDeveloperModeAsThreat: Boolean = false,
    val allowSideload: Boolean = false,
    val strictExamIntegrity: Boolean = false,
    val skipRootOnEmulator: Boolean = false,
    val skipDeveloperModeOnEmulator: Boolean = false,
    val monitoringIntervalSeconds: Int = 30,
    val scope: String = "essential",
) {
    val isEssentialScope: Boolean
        get() = scope != "full"
}

data class ThreatResult(
    val category: String,
    val description: String,
    val severity: String,
    val details: Map<String, String>? = null,
) {
    fun toMap(): Map<String, Any?> = buildMap {
        put("category", category)
        put("description", description)
        put("severity", severity)
        details?.let { put("details", it) }
    }
}
