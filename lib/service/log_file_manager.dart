import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'background_service.dart' as Permission;

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LogFileManager {

  static Future<File> _getLogFile() async {
    final dir = await getExternalStorageDirectory();
    final logDir = Directory('${dir!.path}/Logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    final fileName =
        'log_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';

    return File('${logDir.path}/$fileName');
  }

  static Future<void> writeLog(String message) async {
    try {
      final file = await _getLogFile();

      final logLine =
          '${DateTime.now().toIso8601String()} - $message\n';

      await file.writeAsString(
        logLine,
        mode: FileMode.append,
      );

      print("Log written: ${file.path}");
    } catch (e) {
      print("Log write error: $e");
    }
  }
}

class FileWriter {
  final File file;
  final bool append;

  FileWriter(this.file, this.append);

  Future<void> appendData(String data) async {
    await file.writeAsString(data, mode: append ? FileMode.append : FileMode.write);
  }

  Future<void> close() async {
    // No explicit close needed for Dart's File operations
  }
}

class LogManagerTrackingData {
  static Future<void> writeLog(String logBody) async {
    try {

      // 🕒 Timestamp
      String time = DateTime.now().toIso8601String();

      // 📂 Get app-specific external directory
      final directory = await getExternalStorageDirectory();

      // 🗂️ Create Logs folder
      final logDir = Directory('${directory!.path}/TrackingLogs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // 📄 Log file
      final File file = File('${logDir.path}/TrackingLogs.txt');

      // ✍️ Write log
      await file.writeAsString(
        '$time , $logBody\n',
        mode: FileMode.append,
      );

      print("✅ Log saved successfully: ${file.path}");

    } catch (e) {
      print("❌ Error writing log: $e");
    }
  }
}
/// hand written log generate code
/*
class LogManagerTrackingData {
  static Future<void> writeLog(String logBody) async {
    String time = DateTime.now().toIso8601String();

    String path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOCUMENTS);
    Directory root = Directory("$path/Flutter Attendance APP LogFile");
    if(!await root.exists()){
      root.create(recursive: true);
    }
    File file = File("$root/TrackingLogs.txt");

    file.writeAsString('$time , $logBody\n', mode: FileMode.append);
  }
}*/


/// log with ios implementation
/*
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class LogFileManager {
  /// Get a valid directory path for the current platform
  static Future<Directory> _getLogDirectory() async {
    Directory appDocDir;

    if (Platform.isAndroid) {
      // ✅ On Android, use external app-specific storage
      appDocDir = (await getExternalStorageDirectory())!;
    } else if (Platform.isIOS) {
      // ✅ On iOS, use the app's visible "Documents" directory
      // This shows up in Files → On My iPhone → <App Name>
      appDocDir = await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Unsupported platform");
    }

    // Create a subdirectory for logs
    final logDir = Directory('${appDocDir.path}/Flutter Attendance APP LogFile');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    return logDir;
  }

  /// Write logs to file
  static Future<void> writeLog(String message) async {
    try {
      final logDir = await _getLogDirectory();

      // Log file name per day
      final fileName = 'log_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
      final logFile = File('${logDir.path}/$fileName');

      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final logLine = '$time — $message\n';

      await logFile.writeAsString(logLine, mode: FileMode.append);

      print("✅ Log saved to: ${logFile.path}");
    } catch (e) {
      print("❌ Error writing log: $e");
    }
  }
}*/
