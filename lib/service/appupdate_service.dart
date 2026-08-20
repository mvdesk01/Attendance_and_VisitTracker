import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static Future<void> checkAndUpdate(BuildContext context) async {
    try {
      if (!Platform.isAndroid) return;

      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await _showMandatoryUpdateDialog(context);
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static Future<void> _showMandatoryUpdateDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: const Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Update Required",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            "A new version of the Attendance application is available.\n\n"
            "This update includes important improvements, bug fixes, "
            "and security enhancements to provide you with a better "
            "and more reliable experience.\n\n"
            "Please update the application to continue using it.",
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                _exitApplication();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  48,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Exit Application",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await _handleUpdate();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  50,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Update Now",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _handleUpdate() async {
    if (Platform.isAndroid) {
      try {
        // Mandatory update
        await InAppUpdate.performImmediateUpdate();
        return;
      } catch (e) {
        debugPrint("In-app update failed: $e");

        // If Play Store update fails, open Play Store
      }
    }

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

  static void _exitApplication() {
    SystemNavigator.pop();
  }
}
