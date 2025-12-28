package com.example.synapse_runner

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class TaskForegroundService : Service() {
    companion object {
        const val TAG = "TaskForegroundService"
        const val CHANNEL_ID = "task_foreground_service"
        const val NOTIFICATION_ID = 1000
        const val ACTION_START = "START_FOREGROUND_SERVICE"
        const val ACTION_STOP = "STOP_FOREGROUND_SERVICE"
        const val ACTION_UPDATE = "UPDATE_FOREGROUND_SERVICE"

        const val EXTRA_TASK_TITLE = "task_title"
        const val EXTRA_TASK_DESCRIPTION = "task_description"
        const val EXTRA_TASK_DURATION = "task_duration"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate() - Android SDK ${Build.VERSION.SDK_INT}")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: action=${intent?.action}")
        
        when (intent?.action) {
            ACTION_START -> {
                val title = intent.getStringExtra(EXTRA_TASK_TITLE) ?: "Current Task"
                val description = intent.getStringExtra(EXTRA_TASK_DESCRIPTION) ?: ""
                val duration = intent.getIntExtra(EXTRA_TASK_DURATION, 0)

                Log.d(TAG, "Starting foreground service: $title")
                startForegroundWithType(title, description, duration)
            }
            ACTION_UPDATE -> {
                val title = intent.getStringExtra(EXTRA_TASK_TITLE) ?: "Current Task"
                val description = intent.getStringExtra(EXTRA_TASK_DESCRIPTION) ?: ""
                val duration = intent.getIntExtra(EXTRA_TASK_DURATION, 0)

                Log.d(TAG, "Updating foreground service: $title")
                startForegroundWithType(title, description, duration)
            }
            ACTION_STOP -> {
                Log.d(TAG, "Stopping foreground service")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf()
            }
        }

        return START_STICKY
    }

    private fun startForegroundWithType(title: String, description: String, duration: Int) {
        val notification = createNotification(title, description, duration)
        
        // Log notification flags before starting foreground
        Log.d(TAG, "Notification flags: ${notification.flags} (hex: 0x${Integer.toHexString(notification.flags)})")
        Log.d(TAG, "FLAG_ONGOING_EVENT: ${(notification.flags and Notification.FLAG_ONGOING_EVENT) != 0}")
        Log.d(TAG, "FLAG_NO_CLEAR: ${(notification.flags and Notification.FLAG_NO_CLEAR) != 0}")
        
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                    Log.d(TAG, "Starting foreground with SPECIAL_USE type")
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    )
                }
                else -> {
                    Log.d(TAG, "Starting foreground (legacy)")
                    startForeground(NOTIFICATION_ID, notification)
                }
            }
            Log.d(TAG, "Foreground service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service", e)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Current Task",
                importance
            ).apply {
                description = "Shows your current active task"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(false)
                enableLights(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created: $CHANNEL_ID")
        }
    }

    private fun createNotification(title: String, description: String, durationMinutes: Int): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            pendingIntentFlags
        )

        val notificationText = description.ifEmpty { "Tap to view task" }
        
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)  // Removed emoji - clean title
            .setContentText(notificationText)
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentIntent(pendingIntent)
            .setOngoing(true)  // CRITICAL: Non-dismissible
            .setAutoCancel(false)  // CRITICAL: Can't dismiss by tapping
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setLocalOnly(true)
            .setColorized(false)

        if (description.isNotEmpty()) {
            builder.setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(description)
                    .setBigContentTitle(title)  // Removed emoji
                    .setSummaryText("Running for $durationMinutes min")  // Removed emoji
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        }

        // Build notification
        val notification = builder.build()
        
        // CRITICAL: Explicitly set flags AFTER build
        // This is necessary because NotificationCompat may override them
        notification.flags = notification.flags or 
            Notification.FLAG_ONGOING_EVENT or 
            Notification.FLAG_NO_CLEAR or
            Notification.FLAG_FOREGROUND_SERVICE
        
        Log.d(TAG, "Notification created with flags: ${notification.flags}")
        
        return notification
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy()")
    }
}
