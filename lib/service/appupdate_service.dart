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
      } else if (Platform.isIOS) {
        // iOS → always show popup (or control via version logic later)
        _showUpdateDialog(context);
      }
    } catch (e) {
      _showUpdateDialog(context); // fallback
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text("Update Available"),
        content:
            const Text("A new version is available. Please update the app."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleUpdate();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
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
            "https://play.google.com/store/apps/details?id=com.mtech.attendance")
        : Uri.parse("https://apps.apple.com/app/idYOUR_APP_ID");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
