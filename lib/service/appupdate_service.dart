import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static Future<void> checkAndUpdate(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        AppUpdateInfo info = await InAppUpdate.checkForUpdate();

        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          _showUpdateDialog(context);
        }
      }
      // ❌ REMOVE auto popup for iOS
      // handle iOS only when you implement version check
    } catch (e) {
      // ✅ only log, DO NOT show dialog
      print("Update check failed: $e");
    }
  }

  static Future<bool> _showUpdateDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("Update Available"),
          content: const Text(
            "A new version of the app is available.\n\n"
                "Please update to enjoy the latest features and fixes.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Continue without update
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true); // Update selected
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  static Future<void> _handleUpdate() async {
    if (Platform.isAndroid) {
      try {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return;
      } catch (e) {
        // fallback below
      }
    }

    // fallback / iOS → open store
    final Uri url = Platform.isAndroid
        ? Uri.parse(
            "https://play.google.com/store/apps/details?id=com.mtech.attendance_kd")
        : Uri.parse("https://apps.apple.com/app/idYOUR_APP_ID");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
