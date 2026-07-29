package com.example.military_exam

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val VPN_METHOD_CHANNEL = "com.example.military_exam/vpn"
        private const val VPN_EVENT_CHANNEL = "com.example.military_exam/vpn_events"
        private const val VPN_PREPARE_REQUEST = 9101
    }

    private var vpnResult: MethodChannel.Result? = null
    private var vpnEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepare" -> prepareVpn(result)
                    "startVpn" -> startVpn(result)
                    "stopVpn" -> {
                        stopVpnService()
                        result.success(true)
                    }
                    "isActive" -> result.success(LocalVpnService.isRunning)
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    vpnEventSink = events
                    LocalVpnService.eventSink = { event ->
                        runOnUiThread { vpnEventSink?.success(event) }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    vpnEventSink = null
                    LocalVpnService.eventSink = null
                }
            })
    }

    private fun prepareVpn(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent == null) {
            result.success(true)
            return
        }
        vpnResult = result
        startActivityForResult(intent, VPN_PREPARE_REQUEST)
    }

    private fun startVpn(result: MethodChannel.Result) {
        val intent = Intent(this, LocalVpnService::class.java).apply {
            action = LocalVpnService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        result.success(true)
    }

    private fun stopVpnService() {
        val intent = Intent(this, LocalVpnService::class.java).apply {
            action = LocalVpnService.ACTION_STOP
        }
        startService(intent)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_PREPARE_REQUEST) {
            val pending = vpnResult
            vpnResult = null
            if (resultCode == Activity.RESULT_OK) {
                pending?.success(true)
            } else {
                vpnEventSink?.success("permissionDenied")
                pending?.success(false)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
