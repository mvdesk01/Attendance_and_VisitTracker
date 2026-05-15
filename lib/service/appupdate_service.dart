import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static Future<void> checkAndUpdate(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final AppUpdateInfo info =
        await InAppUpdate.checkForUpdate();

        debugPrint("Update Availability: ${info.updateAvailability}");

        if (info.updateAvailability ==
            UpdateAvailability.updateAvailable) {

          // FORCE UPDATE
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
            return;
          }

          // fallback if immediate not allowed
          _showForceUpdateDialog(context);
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static void _showForceUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // IMPORTANT
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("Update Required"),
          content: const Text(
            "Please update the app to continue using it.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _openStore();
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openStore() async {
    final Uri url = Platform.isAndroid
        ? Uri.parse(
      "https://play.google.com/store/apps/details?id=com.mtech.attendance",
    )
        : Uri.parse(
      "https://apps.apple.com/app/idYOUR_APP_ID",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}