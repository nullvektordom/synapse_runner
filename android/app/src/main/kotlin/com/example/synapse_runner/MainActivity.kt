package com.example.synapse_runner

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "synapse_runner/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val taskTitle = call.argument<String>("taskTitle") ?: "Current Task"
                    val taskDescription = call.argument<String>("taskDescription") ?: ""
                    val durationMinutes = call.argument<Int>("durationMinutes") ?: 0

                    startForegroundService(taskTitle, taskDescription, durationMinutes)
                    result.success(null)
                }
                "updateService" -> {
                    val taskTitle = call.argument<String>("taskTitle") ?: "Current Task"
                    val taskDescription = call.argument<String>("taskDescription") ?: ""
                    val durationMinutes = call.argument<Int>("durationMinutes") ?: 0

                    updateForegroundService(taskTitle, taskDescription, durationMinutes)
                    result.success(null)
                }
                "stopService" -> {
                    stopForegroundService()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startForegroundService(title: String, description: String, duration: Int) {
        val intent = Intent(this, TaskForegroundService::class.java).apply {
            action = TaskForegroundService.ACTION_START
            putExtra(TaskForegroundService.EXTRA_TASK_TITLE, title)
            putExtra(TaskForegroundService.EXTRA_TASK_DESCRIPTION, description)
            putExtra(TaskForegroundService.EXTRA_TASK_DURATION, duration)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun updateForegroundService(title: String, description: String, duration: Int) {
        val intent = Intent(this, TaskForegroundService::class.java).apply {
            action = TaskForegroundService.ACTION_UPDATE
            putExtra(TaskForegroundService.EXTRA_TASK_TITLE, title)
            putExtra(TaskForegroundService.EXTRA_TASK_DESCRIPTION, description)
            putExtra(TaskForegroundService.EXTRA_TASK_DURATION, duration)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopForegroundService() {
        val intent = Intent(this, TaskForegroundService::class.java).apply {
            action = TaskForegroundService.ACTION_STOP
        }
        startService(intent)
    }
}
