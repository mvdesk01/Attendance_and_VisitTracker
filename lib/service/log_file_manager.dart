import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import 'background_service.dart' as Permission;

class LogFileManager {
  // Get the file path for the log file
  static Future<String> _getLogFilePath() async {
    final directory = await getExternalStorageDirectory();
    final logDir = Directory('${directory?.path}/Logs');
    print("path : "+directory!.path.toString());

    // Create the directory if it doesn't exist
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
      print(" not Exists");

    }else
      {
        print("Exists");
      }

    // Log file name with current date
    final logFileName = 'log_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
    return '${logDir.path}/$logFileName';
  }

  // Write a log message to the log file
/*
  static Future<void> writeLog(String message) async {
    try {
      final filePath = await _getLogFilePath();
      final logFile = File(filePath);

      final logMessage = '${DateTime.now().toIso8601String()} - $message\n';
      await logFile.writeAsString(logMessage, mode: FileMode.append);
      //print("Log written: $logMessage");
    } catch (e) {
      print("Failed to write log: $e");
    }
  }
*/

   static Future<void> writeLog( String sBody) async {
     // print("saveData Called");
     String path;

     path = await ExternalPath.getExternalStoragePublicDirectory(
         ExternalPath.DIRECTORY_DOCUMENTS);
     print("saveLogData Called path :"+path);

     Directory root = Directory('${path}/Flutter Attendance APP LogFile');

    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    File gpxfile = File('${root.path}/Log.txt');
    FileWriter writer;
     print("saveLogData Called RootPath"+root.path);
    String time=DateTime.now().toIso8601String();
    if (!await gpxfile.exists()) {
      writer = FileWriter(gpxfile, true);
      await writer.appendData('$time , $sBody\n');
      await writer.close();
      print("Data saved in log file 1");
    } else {
      writer = FileWriter(gpxfile, true);
      await writer.appendData('$time , $sBody\n');
      await writer.close();
      print("Data saved in log file 2");
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
      // ✅ Step 1: Check storage permission

      // 🕒 Step 1: Prepare timestamp
      String time = DateTime.now().toIso8601String();

      // 📂 Step 2: Get public Documents directory
      String path = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS,
      );

      // 🗂️ Step 3: Create subfolder if not exists
      Directory root = Directory('$path/Flutter Attendance APP LogFile');
      if (!await root.exists()) {
        await root.create(recursive: true);
      }

      // 📄 Step 4: Create or open file
      File file = File('${root.path}/TrackingLogs.txt');

      // ✍️ Step 5: Append log line with timestamp
      await file.writeAsString('$time , $logBody\n', mode: FileMode.append);

      print("✅ Log saved successfully at: ${file.path}");
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
