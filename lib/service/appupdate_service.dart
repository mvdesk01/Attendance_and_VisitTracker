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
          await _handleUpdate(info);
        }
      }
      // iOS handled separately when you implement version check
    } catch (e) {
      print("Update check failed: $e");
    }
  }

  static Future<void> _handleUpdate(AppUpdateInfo info) async {
    try {
      if (info.immediateUpdateAllowed) {
        // ✅ Opens Play Store's native full-screen update UI directly.
        // User either updates (app restarts post-update) or taps back/cancel
        // to return to the app.
        final result = await InAppUpdate.performImmediateUpdate();

        if (result == AppUpdateResult.userDeniedUpdate) {
          print("User cancelled the update");
        }
        // AppUpdateResult.success means app will auto-restart, no code runs after
        return;
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }
    } catch (e) {
      print("In-app update failed: $e");
      // fallback below
    }

    // fallback → open Play Store listing manually
    final Uri url = Platform.isAndroid
        ? Uri.parse(
        "https://play.google.com/store/apps/details?id=com.mtech.attendance_kd")
        : Uri.parse("https://apps.apple.com/app/idYOUR_APP_ID");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}