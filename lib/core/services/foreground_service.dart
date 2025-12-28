import 'package:flutter/services.dart';

class ForegroundService {
  static const MethodChannel _channel = MethodChannel('synapse_runner/foreground_service');

  /// Start the foreground service with task notification
  static Future<void> startService({
    required String taskTitle,
    required String taskDescription,
    required int durationMinutes,
  }) async {
    try {
      await _channel.invokeMethod('startService', {
        'taskTitle': taskTitle,
        'taskDescription': taskDescription,
        'durationMinutes': durationMinutes,
      });
    } on PlatformException catch (e) {
      print('Failed to start foreground service: ${e.message}');
    }
  }

  /// Update the foreground service notification
  static Future<void> updateService({
    required String taskTitle,
    required String taskDescription,
    required int durationMinutes,
  }) async {
    try {
      await _channel.invokeMethod('updateService', {
        'taskTitle': taskTitle,
        'taskDescription': taskDescription,
        'durationMinutes': durationMinutes,
      });
    } on PlatformException catch (e) {
      print('Failed to update foreground service: ${e.message}');
    }
  }

  /// Stop the foreground service
  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      print('Failed to stop foreground service: ${e.message}');
    }
  }
}
