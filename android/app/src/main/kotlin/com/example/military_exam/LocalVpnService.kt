package com.example.military_exam

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat

class LocalVpnService : VpnService() {

    companion object {
        const val ACTION_START = "com.example.military_exam.vpn.START"
        const val ACTION_STOP = "com.example.military_exam.vpn.STOP"
        private const val CHANNEL_ID = "exam_vpn_lockdown"
        private const val NOTIFICATION_ID = 7401

        @Volatile
        var isRunning: Boolean = false
            private set

        var eventSink: ((String) -> Unit)? = null
    }

    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSinkhole()
                return START_NOT_STICKY
            }
            else -> {
                if (setupSinkhole()) {
                    isRunning = true
                    return START_NOT_STICKY
                }
                stopSelf()
                return START_NOT_STICKY
            }
        }
    }

    private fun setupSinkhole(): Boolean {
        return try {
            val builder = Builder()
                .setSession("MilitaryExamLockdown")
                .addAddress("10.0.0.2", 24)
                .addAddress("fd00::2", 64)
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0)
                .addDisallowedApplication(packageName)

            vpnInterface?.close()
            vpnInterface = builder.establish()
            if (vpnInterface == null) {
                false
            } else {
                startForeground(NOTIFICATION_ID, buildNotification())
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.vpn_lockdown_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.vpn_lockdown_notification_title))
            .setContentText(getString(R.string.vpn_lockdown_notification_body))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    private fun stopSinkhole() {
        vpnInterface?.close()
        vpnInterface = null
        isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onRevoke() {
        isRunning = false
        eventSink?.invoke("disconnected")
        stopSinkhole()
        super.onRevoke()
    }

    override fun onDestroy() {
        isRunning = false
        eventSink?.invoke("disconnected")
        vpnInterface?.close()
        vpnInterface = null
        super.onDestroy()
    }
}
