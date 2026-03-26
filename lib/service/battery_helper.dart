import 'package:attendance_system_ios/service/log_file_manager.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationHelper {
  static const MethodChannel _channel = MethodChannel("battery_optimization");

  static Future<bool> isIgnoring() async {
    try {
      final bool result = await _channel.invokeMethod("isIgnoringBatteryOptimizations");
      return result;
    } catch (e) {
      print("⚠️ Battery optimization check failed: $e");
      return false;
    }
  }

  static Future<void> requestIgnore() async {
    try {
      await _channel.invokeMethod("requestIgnoreBatteryOptimizations");
    } catch (e) {
      print("⚠️ Battery optimization request failed: $e");
      LogFileManager.writeLog("⚠️ Battery optimization request failed: $e");
    }
  }
}
