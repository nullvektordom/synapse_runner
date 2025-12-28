package com.example.synapse_runner

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Notification Listener Service to detect when task notification is dismissed
 * and immediately recreate it (workaround for Android 14+ dismissible notifications)
 * 
 * Based on solution from Tasks.org and Tasker apps that implement "swipe to immediately recreate"
 */
class TaskNotificationListener : NotificationListenerService() {
    companion object {
        const val TAG = "TaskNotifListener"
        private const val PACKAGE_NAME = "com.example.synapse_runner"
        private const val NOTIFICATION_ID = 1000
    }

    private var lastTaskTitle: String? = null
    private var lastTaskDescription: String? = null
    private var lastTaskDuration: Int = 0
    private var isTaskActive = false

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)

        // Track our task notification when it's posted
        if (sbn?.packageName == PACKAGE_NAME && sbn.id == NOTIFICATION_ID) {
            isTaskActive = true
            val notification = sbn.notification
            lastTaskTitle = notification.extras.getString("android.title")
            lastTaskDescription = notification.extras.getString("android.text")

            Log.d(TAG, "Task notification posted: $lastTaskTitle")
        }
    }

    override fun onNotificationRemoved(
        sbn: StatusBarNotification?,
        rankingMap: RankingMap?,
        reason: Int
    ) {
        super.onNotificationRemoved(sbn, rankingMap, reason)

        // Check if our task notification was dismissed
        if (sbn?.packageName == PACKAGE_NAME && sbn.id == NOTIFICATION_ID) {

            val reasonText = when (reason) {
                REASON_CANCEL -> "user dismissed"
                REASON_APP_CANCEL -> "app cancelled"
                REASON_CLICK -> "user clicked"
                else -> "reason $reason"
            }

            Log.d(TAG, "Task notification removed: $reasonText (isTaskActive=$isTaskActive)")

            // Only recreate if user dismissed AND task is actually active
            // Android 14 = SDK 34 (UPSIDE_DOWN_CAKE)
            if (reason == REASON_CANCEL && isTaskActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                Log.d(TAG, "Android 14+ detected - recreating dismissed notification immediately")
                recreateNotification()
            } else if (reason == REASON_APP_CANCEL || reason == REASON_CANCEL) {
                // App cancelled or user dismissed but task not active - clear state
                isTaskActive = false
                lastTaskTitle = null
                lastTaskDescription = null
                lastTaskDuration = 0
                Log.d(TAG, "Task completed or stale - clearing cached state")
            }
        }
    }

    private fun recreateNotification() {
        // CRITICAL: Verify foreground service is actually running before recreating
        // This prevents recreating stale notifications after app restart
        if (!isServiceRunning()) {
            Log.d(TAG, "Foreground service not running - not recreating (stale notification)")
            isTaskActive = false
            lastTaskTitle = null
            lastTaskDescription = null
            lastTaskDuration = 0
            return
        }

        // Send intent to service to recreate the notification
        val intent = Intent(this, TaskForegroundService::class.java).apply {
            action = TaskForegroundService.ACTION_UPDATE
            putExtra(TaskForegroundService.EXTRA_TASK_TITLE, lastTaskTitle ?: "Current Task")
            putExtra(TaskForegroundService.EXTRA_TASK_DESCRIPTION, lastTaskDescription ?: "")
            putExtra(TaskForegroundService.EXTRA_TASK_DURATION, lastTaskDuration)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d(TAG, "Notification recreation triggered - notification will reappear immediately")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to recreate notification", e)
        }
    }

    private fun isServiceRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (TaskForegroundService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification listener connected - Android 14+ workaround active")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }
}
